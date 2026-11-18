# Icons (Android + iOS)

One icon set for both apps. Each platform used to draw the same meaning its own way — an SF Symbol on iOS, a Material icon on Android — so the app's own icons are vendored Lucide SVGs, and one master generates the asset for both. Platform chrome still belongs to the platform.

## 1. Where the icons come from

Masters live in `shared/assets/icons/`, at one Lucide release for the whole set (ISC, notices alongside). `python3 tools/sync_icons.py --write` generates an iOS `.imageset` that keeps the SVG vector and template-rendering flags, and an Android vector drawable with every `circle`, `rect`, `line`, `polyline` and `polygon` reduced to path data, because vector drawables cannot hold those elements. `--check` fails CI when a generated icon is stale or missing, or when a generated asset has no master — never edit one by hand.

Render through `PraxisIcon` and `PraxisIconView` (`Praxis/Components.swift`, `design/components/PraxisIcon.kt`), and choose the icon by what it means, not by what the file is called. The enum member is the vocabulary: a screen that needs a new picture adds a member, not a local file reference.

## 2. What stays native

Platform chrome keeps the platform's own glyph: navigation and back, toolbars, share and sheet affordances, and field controls such as search and clear. Users expect those to move with the OS, and a redrawn back arrow reads as a bug, not as a brand. Lucide covers only what the app draws for itself — entry cards, row indicators, empty states and content metadata.

One exception: `ContentUnavailableView` on iOS takes a system image by contract. Where it wraps an app error state, a system glyph there is not drift.

## 3. Sizes

Lucide draws a 2-wide stroke on a 24 grid, so the stroke scales with the frame: one size does not fit every slot. Use the optical size that comes with the enum member.

| Context | Size | Where it appears |
|---|---|---|
| Entry-card leading icon | 20 | stats, support and feedback cards |
| Row indicator and metadata | 16 | chevrons, external-link arrows, the author's country |
| Empty state | 28 | stats, and the library's no-results, saved and history states |
| Standalone page lead | 38 | the Support page |

Tint is `textSecondary` unless the icon leads a card, an empty state or a page, where it takes `accent`.

## 4. Adding one

Vendor the SVG at the set's release into `shared/assets/icons/`, run `--write`, add the case to both `PraxisIcon` enums with its optical size, and use it by name. If the icon would sit on chrome, don't add it at all.
