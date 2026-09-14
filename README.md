# NEVIRO v1.1

NEVIRO is a Flutter fuel tracker and fuel-price comparison app.

## V1.1 features

- Light premium green NEVIRO interface
- No login, Firebase, or demo data
- Fuel history stored locally on the device
- Automatic country/region and currency detection, with manual override in Settings
- Extra Australia detection for phones configured with an English (UK) locale, avoiding an incorrect GBP default on Australian time zones
- Region-specific fuel types
- Receipt scan/upload from camera or gallery using on-device ML Kit text recognition
- Receipt scan can prefill date, station, fuel type, price per litre and litres when those values can be detected; the user checks/edits before saving
- Fuel Prices automatically requests/uses location when the Fuel Prices tab is opened
- Fuel Prices refreshes when the tab is opened again, plus a manual Refresh button
- “Updated just now” / last-updated status
- Western Australia FuelWatch results are filtered to a fixed 10 km radius when station coordinates and device location are available
- Map/List views, station distance, cheapest result, Directions, and Use Price
- Sri Lanka official national prices from Ceypetco when available
- Home dashboard, History, Reports, Excel export, and Settings

## Important FuelWatch limitation

The official FuelWatch RSS feed returns up to the 10 cheapest results for a suburb/town search. NEVIRO filters those returned results to 10 km when location coordinates are available. This means the app should not claim that the RSS feed guarantees every physical service station inside the 10 km circle.

## Build on GitHub Actions

The repository contains `.github/workflows/main.yml`, which builds both an Android APK and Play Store AAB.

1. Upload the project files to the GitHub repository root.
2. Open **Actions** and run **Build NEVIRO Android** (or push to `main`).
3. Download `NEVIRO-Android-APK` to install on an Android phone.
4. Download `NEVIRO-PlayStore-AAB` for Google Play preparation.

The workflow creates the Android platform, applies `tool/patch_platforms.py`, installs dependencies, generates launcher icons, analyzes the source, runs the fuel math test, and builds the release APK/AAB.

## Data sources

Western Australia station prices use the official FuelWatch RSS feed. NEVIRO includes FuelWatch acknowledgement in the Fuel Prices screen.

Map tiles use OpenStreetMap and display OpenStreetMap attribution.

Sri Lanka national prices are read from the official Ceypetco marketing/sales page. If the official source is unavailable or changes format, NEVIRO shows an unavailable message instead of inventing prices.

## Privacy

No account is required. Fuel entries stay in local app storage. Receipt text recognition is performed on-device by the ML Kit plugin. Location is used for nearby fuel-price discovery. See `PRIVACY_POLICY.md` and complete the publisher/contact placeholders before store submission.
