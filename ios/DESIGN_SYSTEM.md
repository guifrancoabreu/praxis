# iOS design system

This small system follows the principles in the monorepo’s design and accessibility guides, adapted to SwiftUI. It grows from real screens rather than mirroring the monorepo's packages or tooling.

## Tokens

`RefTokens` in `Praxis/RefTokens.swift` owns primitive values; `SystemTokens` in `Praxis/SystemTokens.swift` composes semantic light and dark themes. Use `RefTokens.Spacing` as the numbered scale from `broto/packages/design-system/src/tokens/ref.ts` (each step is 4 pt on iOS), with reference radii, palette colors, opacity, shadows, and custom illustration type sizes beside it. Use `SystemTokens.light` and `.dark` as semantic theme definitions, and `SystemTokens.Colors` for adaptive roles in views. Preserve the Praxis color palette and native Dynamic Type roles; the Broto hex colors and web font sizes are references, not values to copy directly. The web reader's stylesheet and scripts live in `shared/reader` and are shared with the Android app; `ReaderAssets` composes them and is the only place that fills in the reader's placeholders. Prefer native semantic colors and SwiftUI text styles where the platform already supplies the role and accessibility behavior. Add a token when a shared visual decision emerges; avoid inventing unused scales.

### Typography

Headings, titles, and section headers use Literata; body copy, labels, and controls use Inter. Both faces ship as variable TTFs in `Praxis/Fonts` (SIL Open Font License, with the licenses alongside them) and are registered for the process at launch with CoreText, because the generated Info.plist has no `UIAppFonts` key. Build fonts through `PraxisFont` in `Praxis/PraxisFonts.swift` — `heading(_:weight:)`, `body(_:weight:)`, and `fixed(_:weight:heading:)` — instead of `.system(design: .serif)` or bare text styles, so Dynamic Type keeps scaling from the same Large-size defaults. Named weights resolve through the fonts' variable axes, so check every weight on a device; a simulated render is not proof the instances differ visually.

## Components

`ListRow` and `BookCover` are reusable presentation components in `Praxis/Components.swift`; their visible content comes from callers. `GlassSurface` provides the adaptive glass/material treatment for floating controls. Catalog-bound rows and artwork stay with the app. Place it inside a native `NavigationLink` so the platform supplies interaction, focus, and accessibility semantics. Screen-specific behavior, data, and translated copy belong to the caller.

## Verification

Run the core tests and build described in the iOS README. Reader palette tests check contrast mathematically; they do not establish accessibility compliance. Before considering a screen finished, inspect both appearances, large text, VoiceOver, and touch targets in a simulator or on a device. The WebKit reader's response to text-size changes and archive-specific HTML still requires device verification.
