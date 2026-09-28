import importlib.util
from pathlib import Path
import unittest

spec=importlib.util.spec_from_file_location('validator',Path(__file__).with_name('validate-ios-release.py'))
validator=importlib.util.module_from_spec(spec);spec.loader.exec_module(validator)

class ReleaseBoundaryTests(unittest.TestCase):
    def test_capture_is_only_optimized_simulator_build(self):
        validator.settings('AppStoreCapture','iphonesimulator','build',validator.CAPTURE,'APPSTORE_CAPTURE')
        for platform,action,origin,conditions in [('iphoneos','build',validator.CAPTURE,'APPSTORE_CAPTURE'),
                ('iphonesimulator','install',validator.CAPTURE,'APPSTORE_CAPTURE'),
                ('iphonesimulator','build',validator.PROD,'APPSTORE_CAPTURE'),
                ('iphonesimulator','build',validator.CAPTURE,'DEBUG APPSTORE_CAPTURE')]:
            with self.subTest(platform=platform,action=action),self.assertRaises(ValueError):
                validator.settings('AppStoreCapture',platform,action,origin,conditions)
    def test_release_refuses_capture_loopback_and_debug(self):
        validator.settings('Release','iphoneos','install',validator.PROD,'')
        for origin,flags in [(validator.CAPTURE,''),('http://127.0.0.1:5281',''),(validator.PROD,'DEBUG'),(validator.PROD,'APPSTORE_CAPTURE')]:
            with self.assertRaises(ValueError): validator.settings('Release','iphoneos','install',origin,flags)

if __name__=='__main__':unittest.main()
