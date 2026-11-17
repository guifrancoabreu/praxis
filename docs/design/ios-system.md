# iOS design system

This small system follows the principles in the monorepo’s design and accessibility guides, adapted to SwiftUI. It grows from real screens rather than mirroring the monorepo's packages or tooling.

## Tokens

`design/tokens.json` at the repository root is the single source of truth. `tools/gen_tokens.py --write` generates both `Praxis/RefTokens.swift` and the Android `Tokens.kt`; `--check` fails in CI when either file is stale, so never edit a generated file. `RefTokens.Spacing` is the numbered scale from `broto/packages/design-system/src/tokens/ref.ts` (each step is 4 pt on iOS), with radii, palette colors, opacity, shadows and custom illustration type sizes beside it.

`SystemTokens` in `Praxis/SystemTokens.swift` composes the light and dark themes from the generated `Semantic` roles — paired background/foreground, `card`, `muted`, `primary` with `primaryForeground`, `border`, `separator` — and exposes them as adaptive `SystemTokens.Colors` roles. Screens use those roles, never raw hex, and a color that belongs on both platforms is added to the JSON first. Type sizes come from the `TypeScale` group (`display` through `micro`); `PraxisFont` still owns Dynamic Type scaling. Reader palettes are a separate `Reader` group because the reader theme is user state, not a light/dark appearance role.

Preserve the Praxis color palette and native Dynamic Type roles; the Broto hex colors and web font sizes are references, not values to copy directly. The web reader's stylesheet and scripts live in `shared/reader` and are shared with the Android app; `ReaderAssets` composes them and is the only place that fills in the reader's placeholders. Prefer SwiftUI text styles where the platform already supplies the role and accessibility behavior; colors come from `SystemTokens` instead, so the two apps cannot drift apart. Add a token when a shared visual decision emerges; avoid inventing unused scales.

### Spacing and rhythm

Gaps, padding and line height follow [spacing.md](spacing.md), which both apps share: a gap expresses one of three relationships, each with exactly one value, section gaps live in the parent stack, and section headings sit in a 48-high row shared with the tap target. Do not pick a gap value per screen; if a relationship is missing from that table, add it there first.

### Typography

Headings, titles, and section headers use Literata; body copy, labels, and controls use Inter. Both faces ship as variable TTFs in `Praxis/Fonts` (SIL Open Font License, with the licenses alongside them; the copies are generated from `shared/assets/fonts/` by `python3 tools/sync_assets.py --write`) and are registered for the process at launch with CoreText, because the generated Info.plist has no `UIAppFonts` key. Build fonts through `PraxisFont` in `Praxis/PraxisFonts.swift` — `heading(_:weight:)`, `body(_:weight:)`, and `fixed(_:weight:heading:)` — instead of `.system(design: .serif)` or bare text styles, so Dynamic Type keeps scaling from the same Large-size defaults. Named weights resolve through the fonts' variable axes, so check every weight on a device; a simulated render is not proof the instances differ visually.

## Components

`ListRow` and `BookCover` are reusable presentation components in `Praxis/Components.swift`; their visible content comes from callers. `GlassSurface` provides the adaptive glass/material treatment for floating controls. Catalog-bound rows and artwork stay with the app. Place it inside a native `NavigationLink` so the platform supplies interaction, focus, and accessibility semantics. Screen-specific behavior, data, and translated copy belong to the caller.

## Verification

Run the core tests and build described in the iOS README. Reader palette tests check contrast mathematically; they do not establish accessibility compliance. Before considering a screen finished, inspect both appearances, large text, VoiceOver, and touch targets in a simulator or on a device. The WebKit reader's response to text-size changes and archive-specific HTML still requires device verification.
