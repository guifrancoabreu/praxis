# Spacing pattern (Android + iOS)

One spacing language for the reading app. iOS is the visual reference; where iOS disagrees with itself, this doc decides. Gaps, insets and line height only — colors, type sizes, radii and art sizes are out of scope.

## 1. Principle

Spacing encodes grouping: the tighter two things sit, the more they read as one thing. A gap may only be one of three strengths — inside a unit (`s1`, `s2`), inside a block (`s3`, `s4`), between blocks (`s4`, `s6`, `s8`). Any other value is a local call, not a variation: it means that screen was built without this doc. Users see optical distance, so a value that a container inflates (a 48-high heading row, card padding) is chosen for the visible result, not the container math.

## 2. Allowed values

- Gaps and padding: only `s0 s1 s2 s3 s4 s5 s6 s8 s10 s12 s16 s20 s24` (0, 4, 8, 12, 16, 20, 24, 32, 40, 48, 64, 80, 96). Nothing between.
- **Banned going forward:** every value off that scale (`3`, `5`, `7`, `10`, `11`, `14`, `18`, `22`, `26`, `28`, …). `44` is retired as a height — see §4.
- Allowed raw literals, because no step fits: `1` (hairline, §7) and `48` (tap target, expressed as `s12`). Non-gap sizes (art, avatar, icon, divider thickness) keep their own tokens.

## 3. Relationship table

| Relationship | Value | Expression |
|---|---|---|
| Inside a text group: title→subtitle, title→author, label→value | `s1` (4) | `Tokens.Spacing.s1` / `RefTokens.Spacing.s1` |
| Card media → title | `s2` (8) | `Tokens.Spacing.s2` / `RefTokens.Spacing.s2` |
| Card title → meta (name→count, date→byline) | `s1` (4) | `Tokens.Spacing.s1` / `RefTokens.Spacing.s1` |
| Card internal padding | `s4` (16) | `Tokens.Spacing.s4` / `RefTokens.Spacing.s4` |
| Card ↔ card in a carousel or grid | `s3` (12) | `Tokens.Spacing.s3` / `RefTokens.Spacing.s3` |
| List-row vertical padding | `s3` (12) | `Tokens.Spacing.s3` / `RefTokens.Spacing.s3` |
| First list row under a heading | **no top padding** — the heading gap owns it | n/a |
| List-row leading art → text | `s3` (12) | `Tokens.Spacing.s3` / `RefTokens.Spacing.s3` |
| Section heading → content | `s3` (12) | `Tokens.Spacing.s3` / `RefTokens.Spacing.s3` |
| Section → section (owned by the parent stack) | `s6` (24) | `Tokens.Spacing.s6` / `RefTokens.Spacing.s6` |
| Screen horizontal inset | `s5` (20) | `Tokens.Spacing.s5` / `RefTokens.Spacing.s5` |
| Scroll content top inset | `s4` (16) | `Tokens.Spacing.s4` / `RefTokens.Spacing.s4` |
| Scroll content bottom inset | `s8` (32) above the safe area; screens with a floating overlay add the overlay's height instead | `RefTokens.Spacing.s8` / `Tokens.Spacing.s8` |
| Before a footer or legal group (after a hairline) | `s8` (32) | `Tokens.Spacing.s8` / `RefTokens.Spacing.s8` |
| Sheet top inset (first element under the grabber) | `s6` (24) | `Tokens.Spacing.s6` / `RefTokens.Spacing.s6` |

The library's filters and first feed section form one group with no gap between their layout bounds. The first heading's 48-point row still contains space above its label. Keep this relationship in the parent stack; do not cancel the outer stack's spacing with negative padding. Library sections use an `s4` (16) parent gap because the heading row adds visible space above its label.

## 4. Section component contract

- **Row height `s12` (48) on both.** One number satisfies Android's 48dp guideline and clears iOS's 44pt minimum. It is both the row height and the action's tap target; nothing else in the row is tappable.
- **Action:** hit area ≥ 48×48, label `s1` inside it, trailing edge on the screen inset (`s5`). Android's current ~26dp (`design/components/Components.kt:157`) is an a11y miss, not a style choice.
- **The label and the action are bottom-anchored in the row**, `s1` above its bottom edge — not centered. The row's 30 of slack then falls entirely above the label, where it merges into the section gap, instead of opening a gap between a heading and the content it labels. Centering the label is what makes a heading look detached from its own block.
- **Heading → content = `s3` (12)**, measured from the row's bottom edge.
- **Label type is 15 semibold, tracking 0.8, on both** (Android `bodyMedium` + `SemiBold`; iOS `PraxisFont.body(.subheadline, weight: .semibold)`). The heading and the action were previously inverted on Android — a 13sp heading above a 15sp action — which made the action look like the more important element.
- **A list that starts a section drops its first row's top padding.** Rows carry `s3` above and below for the tap target, so left alone a list section would sit `s3` looser under its heading than a carousel section does — measured 32.7 vs 15.3 on one render. The heading gap is the only thing allowed to separate a heading from its first row.
- **The section gap lives in the parent stack, never in the section.** A child cannot know what follows it; parent-owned gaps cannot double up, and the last section before the footer needs no special case. Sections expose no outer margin.
- **No heading?** A filtered list is a subset of the same section, so it **keeps its heading**; Android dropping headings in filter mode is a bug. If a section truly has none, it emits content only and the parent gap still applies — no phantom `s12` slot.

## 5. Optical note

A 48-tall row holding an 18-tall label carries 30 of slack, and where that slack sits decides what the screen looks like:

| Where | Container | Visible |
|---|---|---|
| last content → heading label | `s6` 24 + 26 | ≈ 54 |
| heading label → its content | `s1` 4 + `s3` 12 + ~4 descent | ≈ 20 |

Bottom-anchoring is what produces that split. Centering the label splits the slack 15/15 and hands half of it to the gap below the heading, which is why a centered 48-tall row measured 41 above / 34 below on a render (1.2 — two sections read as one block) and why the same screen with a 32 parent gap still felt wrong: the heading floated between its label and its content. Anchor the label low and the ratio lands near 2.7, with no per-section tuning and no extra parent gap. Verified on both platforms: Android 19.3dp / 54.2dp, iOS 20.0pt / 56.0pt, with list sections and carousel sections measuring identically. Measuring heading→content from the **row**, not from the label, is what lets one rule serve every section; per-section fudging is what produced the 4/7/8/10/12 spread.

## 6. Line height

Type **sizes** already match across platforms. Line **boxes** do not: Android sets an explicit `lineHeight` per style (`PraxisTheme.kt:88-142`), iOS passes none and inherits the bundled fonts' own leading (~1.2×). Body sizes agree within a point, but Android's title styles are set far looser, which puts invisible height above every title on every screen:

| Role | Android today | Font's own leading (≈ iOS today) | Target, both |
|---|---|---|---|
| Large title | 34/50 (1.47) | 34/41 (1.20) | 34/41 |
| Title | 22/33 (1.50) | 22/26 (1.20) | 22/27 |
| Heading / titleMedium | 17/25 (1.47) | 17/20 (1.21) | 17/21 |
| Body, label, caption | 17/21, 15/18, 13/16, 12/15 | same, ±1 | keep |

Android's title boxes are the single largest source of the "different rhythm" feeling: a 50-tall box around a 34sp title adds ~9 of invisible height above every screen header, and 25 around 17 adds ~4.5 above every section row. **Fixing Android to the fonts' own leading makes it match iOS without touching iOS at all**, and collapses two ratios into one: line height ≈ 1.2× the size. Keep sizes relative (`sp` / `Font.custom(_:size:relativeTo:)`) so Dynamic Type still scales, and keep `LineHeightStyle(Alignment.Center, Trim.None)` so the leading splits symmetrically; on iOS, if a style ever needs it, split leading inside the box rather than `.lineSpacing`, which appends below and reopens the drift.


## 7. Dividers

A divider starts where the row's **primary text column** starts and ends on the screen inset. Express it once, never at call sites: `InsetDivider(leadingArt: Dp? = null)` computes `inset + (art + s3 if art else 0)`, with a SwiftUI equivalent wrapping the row. Retire the literals `0/16/40/63/64/65/68` (`Components.kt:239`, `PraxisApp.swift:776`, `:789`).

## 8. Migration

| Platform | Current → target |
|---|---|
| Android | display/title/titleMedium lineHeight 50 / 33 / 25 → **41 / 27 / 21** (§6) |
| Android | two section-header impls (`design/components/Components.kt:140`, `LibraryScreen.kt:373`) → **one**, 48 tall; "See all" hit 26 (`Components.kt:157`) → **48** |
| Android | collection heading→content 4, search results 24 → **12**; library already 12, section gap → **24** |
| Android | stats heading→content → **12**; stats section gap 24 already correct |
| Android | support + privacy section gap 24 already correct; author section gap 0 → **24** |
| Android | filter-mode sections with no heading → **keep the heading** |
| Android | `RoundIconTile` 42 → **48**; dividers 16 / 64 / 68 / 0 → **text column** |
| iOS | every heading→content 4 / 7 / 8 / 10 → **12**: `startHere` `:691`, `writerShelf` `:715`, `popularWorkList` `:783`, `countryList` `:594`, `savedPreview` `:523`, `continueReading` `:631`, `figureList` `:577`, writer/work/collection/history, support, privacy, stats Activity |
| iOS | section gaps 22 (support, privacy) → **24**; stats root and library `LazyVStack` 16 → **24** |
| iOS | heading rows 44 tall, label centered → **48, label bottom-anchored** (`:433`, `:515`, `:523`, `:533`, `:634`, `:715`, `:783`, `:815`) |
| iOS | card `VStack` 5 (work row) and 3 (info/footer) → **4**; list-row vertical padding 10 → **12** |
| iOS | dividers 40 / 63 / 65, and 0 on art rows → **text column** |

## 9. Tokens and placement

This file. Add to `design/tokens.json` with both mirrors: `sizing.touchTarget = 48`, `sizing.hairline = 1`. No new spacing step, and no line-height ratio token — line height follows the bundled fonts' own leading (§6).

## 10. Order

1. Doc + tokens (`sizing.*`); no UI change.
2. One `Section` per platform, 48-tall centered heading, adopted in the library feed only.
3. One divider component; migrate the library and list rows off literal insets.
4. Android sweep to §3 (stats, support, privacy, collection, author, search, filter-mode headings).
5. iOS sweep to §3 (sections, cards 5/3→4, rows 10→12, 44-tall heading rows).
6. Android line-height fix (§6) — the largest visible change — then diff both apps against the same screenshots.
