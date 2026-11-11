# Praxis for iOS

Praxis is a Marxist reading and study app for iOS, built with SwiftUI and drawing on the Marxists Internet Archive (MIA). Its name refers to the connection between theory and practice. The app runs on iOS 17 and later and supports Portuguese, English, and Spanish catalogs.

The app's name is **Praxis**. `Praxis` remains the internal Xcode project, scheme, and source-directory name.

## Open and run

1. Open `ios/Praxis.xcodeproj` in Xcode.
2. Select the `Praxis` scheme and an iOS simulator.
3. Run the app.

For a physical device, choose a development team in **Signing & Capabilities** and set a bundle identifier if needed.

## Project structure

```text
ios/
  Praxis.xcodeproj/       Xcode project and app scheme
  Praxis/
    PraxisApp.swift       SwiftUI screens, reader, and app entry point
    Catalog.swift                Catalog models, loading, and language metadata
    Resources/                   Bundled Portuguese, English, and Spanish catalogs
  Tests/                         Catalog and core behavior tests
  Package.swift                  Swift package for the testable core
tools/
  build_catalog.py               Refresh the Portuguese catalog
  build_catalog_en.py            Refresh the English catalog
  build_catalog_es.py            Refresh the Spanish starter catalog
```

## Catalogs

The app bundles catalog snapshots, so browsing author and topic indexes does not require a catalog API. To refresh them, run the corresponding script from the repository root:

```sh
python3 tools/build_catalog.py
python3 tools/build_catalog_en.py
python3 tools/build_catalog_es.py
```

The scripts write JSON files to `ios/Praxis/Resources/`. They fetch data from the corresponding MIA archive section; an internet connection is required. The Spanish catalog is a starter selection, not a complete mirror of the Spanish archive.

## Tests

Run the catalog and core tests with:

```sh
swift test --package-path ios
```

These tests do not replace running the app and checking reader behavior on an iOS simulator or device.

## Content and attribution

Texts belong to the Marxists Internet Archive and their translators. The app displays archive content with source attribution. [Support the MIA](https://www.marxists.org/admin/volunteers/index.htm).
