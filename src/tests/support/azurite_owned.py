"""Minimal signed REST helper for explicitly owned loopback emulator fixtures only."""
import base64
import datetime
import hashlib
import hmac
import urllib.request
from urllib.parse import urlsplit

EMULATOR_KEY = 'Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw=='

class OwnedAzurite:
    def __init__(self, endpoint, container):
        parsed = urlsplit(endpoint)
        if (parsed.scheme != 'http' or parsed.hostname not in ('127.0.0.1', 'localhost', '::1')
                or parsed.path != '/devstoreaccount1' or parsed.query or parsed.fragment or parsed.username
                or not (container == 'highscores-release-validation' or container.startswith(('dt3d-test-', 'dt3d-owned-')))):
            raise ValueError('Only an explicitly owned loopback fixture is allowed')
        self.endpoint, self.container = endpoint, container

    def request(self, method, blob=None, body=None):
        date = datetime.datetime.now(datetime.timezone.utc).strftime('%a, %d %b %Y %H:%M:%S GMT')
        path = f'/devstoreaccount1/{self.container}' + ('/' + blob if blob else '')
        query = '' if blob else '?restype=container'
        headers = {'x-ms-date': date, 'x-ms-version': '2025-11-05'}
        content_type = 'application/json' if body is not None else ''
        if body is not None: headers['Content-Type'] = content_type
        if blob and method == 'PUT': headers['x-ms-blob-type'] = 'BlockBlob'
        fields = [method, '', '', str(len(body)) if body else '', '', content_type, '', '', '', '', '', '']
        canonical = '\n'.join(fields) + '\n' + ''.join(f'{k}:{v}\n' for k,v in sorted(headers.items()) if k.startswith('x-ms-'))
        canonical += '/devstoreaccount1' + path + ('\nrestype:container' if not blob else '')
        signature = base64.b64encode(hmac.new(base64.b64decode(EMULATOR_KEY), canonical.encode(), hashlib.sha256).digest()).decode()
        headers['Authorization'] = 'SharedKey devstoreaccount1:' + signature
        request = urllib.request.Request(self.endpoint + '/' + self.container + ('/' + blob if blob else '') + query,
                                         data=body, method=method, headers=headers)
        with urllib.request.urlopen(request, timeout=6) as response:
            return response.status, dict(response.headers), response.read()
