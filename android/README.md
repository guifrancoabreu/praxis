# Android app

Native Kotlin + Jetpack Compose port of Praxis. It aims to look and behave like the iOS app in
`ios/`, and both read the same content:

- `shared/catalog/` — catalog snapshots, wired as Gradle assets.
- `shared/reader/` — the archive reader's stylesheet and scripts (used from Fase 4 onward).
- `design/tokens.json` — primitive design values; `Tokens.kt` in `design/` is generated from it.
- `app/src/main/res/font/` — Literata (headings) and Inter (body) as single variable TTFs, wired up in
  `design/PraxisFonts.kt`; their OFL license texts sit in `app/src/main/res/raw/`.

## Build and run

Requirements: JDK 17+, Android SDK with platform 37 (`compileSdk = 37`; `targetSdk` stays at 36).

```sh
export ANDROID_HOME=$HOME/Library/Android/sdk
./gradlew assembleDebug
./gradlew installDebug     # with a device or emulator attached
```

The debug build uses the `br.praxis.android.debug` application id so it can sit next to a release
install.

## Tests

```sh
./gradlew testDebugUnitTest
```

`CatalogSnapshotTest` parses the same snapshots the app ships and asserts the counts the iOS tests
expect, which is the cheapest way to catch a parser that drifted.

## Layout

```text
app/src/main/kotlin/br/praxis/android/
  data/     catalog parsing, language policy, portraits, editorial ranking, search
  design/   Tokens.kt (generated), PraxisTheme, components
  ui/       library, and later the other screens
```

## Status

Feature-complete against `docs/plan-android.md` for a Portuguese release: library with chips,
featured text, popular writers, saved works, reading log, search and footer; author, collection,
support and privacy screens; the archive reader with the six themes, custom colours, bookmark,
source link and 100 MB offline cache; the optional TelemetryDeck consent flow.

Still open before publishing: PDF works open in the system browser (no in-app renderer yet),
portrait cropping uses a centred crop instead of face detection, and tablet layouts are out of
scope. Play packaging lives in `docs/play-listing-pt-BR.md`.
