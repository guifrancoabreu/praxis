# Android app

Native Kotlin + Jetpack Compose port of Praxis. It aims to look and behave like the iOS app in
`ios/`, and both read the same content:

- `shared/catalog/` — catalog snapshots, wired as Gradle assets.
- `shared/reader/` — the archive reader's stylesheet and scripts (used from Fase 4 onward).
- `design/tokens.json` — primitive design values; `Tokens.kt` in `design/` is generated from it.

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

Fase 0 and the first half of Fase 3 of `docs/plan-android.md`: the library renders chips, the
daily featured text, popular writers with portraits, the work list, search and the footer. Saved
works, reading history, the reader, appearance, author pages and the Play Store release are next.
