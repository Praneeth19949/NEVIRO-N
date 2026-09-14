#!/usr/bin/env python3
from pathlib import Path
import plistlib
import sys

ROOT = Path(__file__).resolve().parents[1]


def patch_android():
    manifest = ROOT / 'android' / 'app' / 'src' / 'main' / 'AndroidManifest.xml'
    if not manifest.exists():
        return
    text = manifest.read_text()
    permissions = [
        '<uses-permission android:name="android.permission.INTERNET" />',
        '<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />',
        '<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />',
    ]
    for permission in reversed(permissions):
        if permission not in text:
            text = text.replace('<manifest', '<manifest', 1)
            insert_at = text.find('>') + 1
            text = text[:insert_at] + '\n    ' + permission + text[insert_at:]
    text = text.replace('android:label="neviro"', 'android:label="NEVIRO"')
    text = text.replace('android:label="Neviro"', 'android:label="NEVIRO"')
    manifest.write_text(text)


def patch_ios():
    plist_path = ROOT / 'ios' / 'Runner' / 'Info.plist'
    if not plist_path.exists():
        return
    with plist_path.open('rb') as f:
        data = plistlib.load(f)
    data['CFBundleDisplayName'] = 'NEVIRO'
    data['NSLocationWhenInUseUsageDescription'] = (
        'NEVIRO uses your location only when you ask for nearby fuel prices and directions.'
    )
    with plist_path.open('wb') as f:
        plistlib.dump(data, f, sort_keys=False)


if __name__ == '__main__':
    target = sys.argv[1] if len(sys.argv) > 1 else 'all'
    if target in ('all', 'android'):
        patch_android()
    if target in ('all', 'ios'):
        patch_ios()
