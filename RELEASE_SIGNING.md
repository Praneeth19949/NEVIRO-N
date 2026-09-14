# NEVIRO Release Signing

## Google Play

The GitHub Android workflow is intended to prove the app builds and to provide an installable APK. Before publishing the AAB to Google Play, create and protect your own Android upload key and configure release signing.

Do not publish a private keystore or passwords in a public GitHub repository.

Recommended flow:

1. Create an Android upload keystore on your own computer.
2. Store the keystore and passwords securely.
3. Put signing credentials in GitHub Actions encrypted secrets or build the signed AAB locally.
4. Enable Play App Signing in Google Play Console when creating the app.
5. Upload the signed `app-release.aab`.

Your package/application ID in this project is intended to be `com.neviro.neviro`.

## Apple App Store

Apple distribution requires:

- Apple Developer Program membership
- An App Store Connect app record
- A unique Bundle ID (intended: `com.neviro.neviro`)
- Apple distribution signing managed by Xcode/App Store Connect
- App Store screenshots, privacy information and review metadata

The included iOS workflow performs a no-codesign build check only. A signed archive/IPA must be created with credentials from the publisher's Apple Developer account.
