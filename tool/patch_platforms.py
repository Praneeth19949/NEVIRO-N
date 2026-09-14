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

    gradle_kts = ROOT / 'android' / 'app' / 'build.gradle.kts'
    if gradle_kts.exists():
        gradle = gradle_kts.read_text()
        gradle = gradle.replace('minSdk = flutter.minSdkVersion', 'minSdk = 24')
        mlkit_dependencies = '''

dependencies {
    implementation("com.google.mlkit:text-recognition-chinese:16.0.1")
    implementation("com.google.mlkit:text-recognition-devanagari:16.0.1")
    implementation("com.google.mlkit:text-recognition-japanese:16.0.1")
    implementation("com.google.mlkit:text-recognition-korean:16.0.1")
}
'''
        if 'text-recognition-chinese:16.0.1' not in gradle:
            gradle += mlkit_dependencies
        gradle_kts.write_text(gradle)

    gradle_groovy = ROOT / 'android' / 'app' / 'build.gradle'
    if gradle_groovy.exists():
        gradle = gradle_groovy.read_text()
        gradle = gradle.replace('minSdkVersion flutter.minSdkVersion', 'minSdkVersion 24')
        mlkit_dependencies = '''

dependencies {
    implementation 'com.google.mlkit:text-recognition-chinese:16.0.1'
    implementation 'com.google.mlkit:text-recognition-devanagari:16.0.1'
    implementation 'com.google.mlkit:text-recognition-japanese:16.0.1'
    implementation 'com.google.mlkit:text-recognition-korean:16.0.1'
}
'''
        if 'text-recognition-chinese:16.0.1' not in gradle:
            gradle += mlkit_dependencies
        gradle_groovy.write_text(gradle)


def patch_ios():
    plist_path = ROOT / 'ios' / 'Runner' / 'Info.plist'
    if not plist_path.exists():
        return
    with plist_path.open('rb') as f:
        data = plistlib.load(f)
    data['CFBundleDisplayName'] = 'NEVIRO'
    data['NSLocationWhenInUseUsageDescription'] = (
        'NEVIRO uses your location to load nearby fuel prices when you open Fuel Prices.'
    )
    data['NSCameraUsageDescription'] = (
        'NEVIRO uses the camera when you choose to scan a fuel receipt.'
    )
    data['NSPhotoLibraryUsageDescription'] = (
        'NEVIRO lets you choose a fuel receipt photo to scan its fill-up details.'
    )
    with plist_path.open('wb') as f:
        plistlib.dump(data, f, sort_keys=False)


if __name__ == '__main__':
    target = sys.argv[1] if len(sys.argv) > 1 else 'all'
    if target in ('all', 'android'):
        patch_android()
    if target in ('all', 'ios'):
        patch_ios()
