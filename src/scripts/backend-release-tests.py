"""Promotion must reject failed/untrusted runs and mismatched release artifacts."""
import contextlib
import hashlib
import importlib.util
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import urllib.error
import zipfile

spec = importlib.util.spec_from_file_location('release', Path(__file__).with_name('backend-release.py'))
release = importlib.util.module_from_spec(spec)
spec.loader.exec_module(release)
SHA = 'a' * 40
REPO = 'owner/repo'


class PromotionTests(unittest.TestCase):
    def run_record(self):
        return dict(status='completed', conclusion='success', workflow_id=123, head_branch='main',
                    head_repository=dict(full_name=REPO), event='push', head_sha=SHA)

    def test_only_successful_expected_dev_run_is_accepted(self):
        self.assertEqual(SHA, release.validate_dev_run(self.run_record(), REPO, 123))
        for field, value in [('status', 'in_progress'), ('conclusion', 'failure'),
                             ('conclusion', 'cancelled'), ('workflow_id', 124),
                             ('head_branch', 'feature'), ('head_repository', {'full_name': 'fork/repo'}),
                             ('event', 'pull_request'), ('head_sha', 'not-a-sha')]:
            with self.subTest(field=field, value=value):
                candidate = self.run_record(); candidate[field] = value
                with self.assertRaises(ValueError):
                    release.validate_dev_run(candidate, REPO, 123)

    def test_manual_main_dev_run_is_accepted(self):
        candidate = self.run_record(); candidate['event'] = 'workflow_dispatch'
        self.assertEqual(SHA, release.validate_dev_run(candidate, REPO, 123))

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.source = Path(self.temp.name) / 'publish'; self.source.mkdir()
        self.output = Path(self.temp.name) / 'release'
        (self.source / 'DonkeyTrump.Highscores.Api.dll').write_bytes(b'test-assembly')
        (self.source / 'appsettings.Development.json').write_text('{"UseAzurite":true}')
        with contextlib.redirect_stdout(io.StringIO()):
            release.package(self.source, self.output, SHA)

    def test_package_roundtrip_keeps_root_and_excludes_development_profile(self):
        release.validate_package(self.output, SHA)
        with zipfile.ZipFile(self.output / 'app.zip') as archive:
            self.assertNotIn('appsettings.Development.json', archive.namelist())
            self.assertIn('DonkeyTrump.Highscores.Api.dll', archive.namelist())

    def test_wrong_source_commit_is_rejected(self):
        with self.assertRaises(ValueError): release.validate_package(self.output, 'b' * 40)

    def test_modified_package_is_rejected(self):
        with (self.output / 'app.zip').open('ab') as out: out.write(b'changed')
        with self.assertRaisesRegex(ValueError, 'digest'): release.validate_package(self.output, SHA)

    def change_archive(self, entries):
        with zipfile.ZipFile(self.output / 'app.zip', 'w') as archive:
            for name, data in entries.items(): archive.writestr(name, data)
        manifest = json.loads((self.output / 'release.json').read_text())
        manifest['sha256'] = hashlib.sha256((self.output / 'app.zip').read_bytes()).hexdigest()
        (self.output / 'release.json').write_text(json.dumps(manifest))

    def test_embedded_wrong_commit_is_rejected_even_with_matching_digest(self):
        self.change_archive({'DonkeyTrump.Highscores.Api.dll': b'x', 'deployment.json': json.dumps({'commit': 'b' * 40})})
        with self.assertRaisesRegex(ValueError, 'Embedded'): release.validate_package(self.output, SHA)

    def test_unsafe_archive_paths_are_rejected(self):
        for name in ['../outside', '/absolute']:
            self.change_archive({'DonkeyTrump.Highscores.Api.dll': b'x', 'deployment.json': json.dumps({'commit': SHA}), name: b'x'})
            with self.assertRaisesRegex(ValueError, 'Unsafe'): release.validate_package(self.output, SHA)

    def test_nested_publish_folder_is_rejected(self):
        self.change_archive({'publish/DonkeyTrump.Highscores.Api.dll': b'x'})
        with self.assertRaisesRegex(ValueError, 'root'): release.validate_package(self.output, SHA)

    def test_smoke_rejects_non_https_or_credential_bearing_targets(self):
        for origin in ['http://example.test', 'https://user:password@example.test',
                       'https://example.test?token=anything', 'https://example.test/path']:
            with self.assertRaises(ValueError): release.smoke(origin)


class SmokeVersionTests(unittest.TestCase):
    def test_both_read_versions_are_required_before_promotion(self):
        class Response(io.BytesIO):
            status = 200
            headers = {"Cache-Control": "no-store"}

        class Opener:
            def __init__(self, v2_exists):
                self.v2_exists = v2_exists
                self.paths = []
            def open(self, url, timeout):
                self.paths.append(url)
                if url.startswith('http:'):
                    raise urllib.error.HTTPError(url, 301, 'HTTPS', {"Location": "https://example.test/health/live"}, None)
                if url.endswith('/health/live'):
                    return Response(b'Healthy')
                if url.endswith('/api/v2/highscores') and not self.v2_exists:
                    raise urllib.error.HTTPError(url, 404, 'Missing', {}, None)
                return Response(b'{"entries":[],"revision":"fixture"}')

        for exists in (False, True):
            opener = Opener(exists)
            with self.subTest(v2_exists=exists), patch.object(release.urllib.request, 'build_opener', return_value=opener), contextlib.redirect_stdout(io.StringIO()):
                if exists:
                    release.smoke('https://example.test', attempts=1)
                else:
                    with self.assertRaisesRegex(RuntimeError, 'smoke failed'):
                        release.smoke('https://example.test', attempts=1)
                self.assertIn('https://example.test/api/v1/highscores', opener.paths)
                self.assertIn('https://example.test/api/v2/highscores', opener.paths)


if __name__ == '__main__': unittest.main()
