#!/usr/bin/env python3
"""Enforce the production archive / simulator-only screenshot configuration boundary."""
import argparse
import plistlib
from pathlib import Path

PROD = 'https://donkeytrump-api-p.azurewebsites.net'
CAPTURE = 'https://donkeytrump-api-d.azurewebsites.net/capture'


def settings(configuration, platform, action, origin, conditions):
    flags = set(conditions.split())
    if configuration == 'AppStoreCapture':
        if platform != 'iphonesimulator' or action not in ('build', 'analyze') or origin != CAPTURE or 'DEBUG' in flags or 'APPSTORE_CAPTURE' not in flags:
            raise ValueError('AppStoreCapture is simulator-only, uses isolated DEV HTTPS, and cannot archive/export')
    elif not configuration.startswith('Debug'):
        if origin != PROD or 'DEBUG' in flags or 'APPSTORE_CAPTURE' in flags:
            raise ValueError('A distribution configuration must use PROD HTTPS and exclude test/capture compilation')


def archive(path):
    path = Path(path)
    apps = list((path / 'Products/Applications').glob('*.app'))
    if len(apps) != 1: raise ValueError('Expected exactly one archived iOS app')
    with (apps[0] / 'Info.plist').open('rb') as stream: info = plistlib.load(stream)
    if info.get('DT3DCaptureBuild') or info.get('HighscoreAPIBaseURL') != PROD:
        raise ValueError('Capture or non-PROD app cannot be distributed')
    if info.get('UIDeviceFamily') != [1]: raise ValueError('The final candidate must be iPhone-only after verified account history')
    if info.get('CFBundleSupportedPlatforms') != ['iPhoneOS']: raise ValueError('Archive is not an iOS device build')
    if not (apps[0] / 'PrivacyInfo.xcprivacy').exists(): raise ValueError('Privacy manifest missing')
    return info['CFBundleShortVersionString'], info['CFBundleVersion']


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='command',required=True)
    build = sub.add_parser('build-settings')
    for arg in ['configuration','platform','action','origin','conditions']: build.add_argument('--'+arg,required=True)
    check = sub.add_parser('archive'); check.add_argument('path')
    args = parser.parse_args()
    if args.command == 'archive': print('Validated archive identity:', *archive(args.path))
    else: settings(args.configuration,args.platform,args.action,args.origin,args.conditions)
