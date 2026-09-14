# NEVIRO v1.0

NEVIRO is a mobile fuel tracker and fuel-price comparison app built with Flutter for Android and iOS.

## Final V1 scope

- Dark-green NEVIRO UI
- No login, no Firebase, no demo/sample data
- Local fuel history stored on the device
- Automatic region profile from the phone locale with a manual override
- Automatic currency with a manual override
- Region-specific fuel types
- Home dashboard: monthly spend, litres, average price, average efficiency, recent fill-ups
- Add Fuel: date, fuel type, optional station, price/L, litres, auto total, optional odometer, notes
- Odometer-based distance and estimated fuel efficiency
- History with search, filter, edit and delete
- Reports: weekly/monthly/yearly, spending trend, efficiency, fuel breakdown
- Excel export
- Fuel Prices:
  - Western Australia: official FuelWatch RSS feed, map/list, cheapest station, distance, directions
  - Sri Lanka: latest official national prices read from Ceypetco when available
  - Unsupported regions: fuel tracking still works; live prices are not invented
- Location fallback: if GPS/location is unavailable, the user can enter a WA suburb manually
- Directions open an external mapping app / Google Maps web fallback

## Data sources and attribution

Western Australia station prices use the official FuelWatch RSS feed. FuelWatch requires acknowledgement when its data is used in an app. NEVIRO displays this acknowledgement in the Fuel Prices screen.

Map tiles use OpenStreetMap and display OpenStreetMap attribution.

Sri Lanka national prices are read from the official Ceypetco marketing/sales page. If the source page is unavailable or changes format, NEVIRO shows an unavailable message instead of inventing prices.

## Build on GitHub Actions

The repository contains:

- `.github/workflows/android.yml` — APK + AAB build
- `.github/workflows/ios-check.yml` — unsigned iOS release build check

The workflows create the native Android/iOS folders automatically, patch the app name/location permissions, generate launcher icons, analyze, run tests, then build.

### Android

1. Upload this project to a GitHub repository.
2. Open **Actions**.
3. Run **Build NEVIRO Android**.
4. Download the `NEVIRO-APK` artifact to install/test.
5. For Google Play publishing, configure your own Android upload/release key before uploading the AAB. See `RELEASE_SIGNING.md`.

### iOS

The iOS workflow confirms the app can build without code signing. App Store distribution still requires an Apple Developer account, signing certificate, App Store provisioning, and an Archive/IPA created under your Apple account.

## Bundle/application ID

The build workflows create the native app using:

`com.neviro.neviro`

Before publishing, confirm this ID is the one you want to keep permanently.

## Privacy

NEVIRO does not require an account and does not send the user's fuel-history database to a NEVIRO cloud service. Location permission is requested only for nearby price discovery. See `PRIVACY_POLICY.md` for a store-ready draft that should be hosted publicly before release.

## Important release note

The source is prepared for both stores, but neither Google Play nor Apple App Store can be published without the developer accounts and signing credentials owned by the publisher.
