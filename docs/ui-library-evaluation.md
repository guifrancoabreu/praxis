# shadcn/ui and Vercel UI SDK — what applies to Praxis

Status: exploration, branch `spike/web-ui-sdk-adoption`. Not a plan of record until reviewed.

## 1. Short answer

Neither library can be installed in this repo. Both render the DOM: shadcn/ui is React source you copy in, and Vercel's UI SDK is headless primitives with React, Vue, Svelte, Solid and web-component adapters. Praxis ships SwiftUI and Jetpack Compose. There is no official native port of either, and the community ones are too small — or AGPL — to build a design language on.

What is worth taking is the model behind them, and it fits this repo better than expected, because Praxis already does the hard half: values live in `design/tokens.json`, drift is checked in CI, and `docs/spacing-pattern.md` already fixes one visual language across platforms. Two mechanisms are missing, and they are exactly the two these libraries supply:

1. **a semantic token layer generated for both platforms.** `SystemTokens.swift` and `PraxisTheme.kt` are hand-maintained twins today, with no check between them.
2. **a component registry with a parity check.** iOS has 5 shared components across 13 screens; Android has 10 shared composables among 84. The styling rules exist in prose, but nothing lists which components exist and whether both platforms agree.

There is also one place where the literal library belongs later: a web surface that does not exist yet. The in-app reader (`shared/reader`) is web tech but deliberately dependency-free, so it is not that surface.

## 2. What each one actually is

**Vercel UI SDK** (public beta, `vercel-labs/ui`, Apache-2.0) is a TypeScript library of UI *behaviors*, not components. You describe a primitive with `definePrimitive({ name, state, api, slots })` — popup, typeahead, selection, focus recovery — and render its parts per framework. Parts ship no markup and no component CSS: only `data-slot` / `data-state` attributes and a `css()` helper for custom properties, which you style yourself. Packages: `@ui-sdk/core` plus `@ui-sdk/react` (React 19), `@ui-sdk/vue`, `@ui-sdk/svelte`, `@ui-sdk/solid`, `@ui-sdk/web`. ESM-only, no React Server Components requirement, no Vercel hosting requirement.

**shadcn/ui** is not a dependency. A CLI (`shadcn@4`) copies source files into your project from a *registry*: a small JSON manifest per component listing its files, npm dependencies, registry dependencies, CSS variables and target path. Styling is Tailwind v4 plus CSS custom properties with paired semantic names (`background`/`foreground`, `primary`/`primary-foreground`, a derived `--radius` scale). Primitives come in Base UI, React Aria and Radix flavors. Components are yours after `add`; only the CLI is a dependency.

## 3. What does not carry over

- **Direct installation.** There is no React, npm or build step in the native apps. UI SDK's core is DOM-bound (`document.documentElement`, `HTMLInputElement`), and its only "mobile" guidance is web-on-phone helpers — viewport binding, keyboard avoidance, safe areas. No React Native or native adapter exists.
- **Community native ports.** These are ports of the *look*, at small scale, none endorsed by shadcn:

  | Port | Platform | Size | License | State |
  | --- | --- | --- | --- | --- |
  | RikkaUi | Compose Multiplatform | 186★ | Apache-2.0 | 0.3.0, Apr 2026 |
  | ShadKit | SwiftUI | 52★ | MIT | no releases |
  | komoui | Compose | 41★ | non-standard | early |
  | swiftui-flx | SwiftUI | 37★ | **AGPL-3.0** | disqualified for an app |

  Depending on any of them means inheriting an unversioned API surface for a visual language Praxis already owns in `tokens.json`. Read them as references; do not take the dependency.
- **Tailwind and oklch values.** The convention transfers; the utility classes and the specific color space do not need to.

## 4. What does carry over

### 4.1 Semantic tokens, generated for both platforms

Primitive values already flow from `design/tokens.json`: `tools/gen_tokens.py --write` emits `android/.../design/Tokens.kt`, and `--check` diffs the hand-written `ios/Praxis/RefTokens.swift` against the JSON, in CI.

The layer *above* the primitives does not flow. `ios/Praxis/SystemTokens.swift` (semantic light/dark theme) and `PraxisTheme.kt`'s `PraxisColors` are written twice by hand, and nothing verifies that the two agree. That is shadcn's most transferable idea: name colors by role and pair every surface with its text color, so a screen never picks a raw value.

The mapping is almost direct, because the palette already has the right roles under different names:

| Role | Praxis source | Light / dark |
| --- | --- | --- |
| `background` | `background` | `#FBFAF7` / `#1A1816` |
| `foreground` | `textPrimary` | `.label` / `#FFF` |
| `card`, `popover` | `surface` | `#FFFEFC` / `#262320` |
| `muted` | `secondarySurface` | `#E8E3D9` / `#33302B` |
| `muted-foreground` | `textSecondary` | `#524D47` / `.secondaryLabel` |
| `primary` | `accent` (brand red) | `#940008` / `#FF7A7A` |
| `border`, `input` | `separator` | unresolved, see below |
| `ring` | `accent`, new role | no value change |

Naming choices that keep the two systems from colliding:

- **`accent` must not mean red.** In shadcn, `accent` is the quiet hover tint and `primary` is the brand color. Praxis's `accent` is the brand red, so red becomes `primary` only, and `accent` aliases `muted`.
- **Skip `destructive` and `chart-1..5`.** Nothing in the product needs a destructive role, and `cover*` colors are cover artwork, not data visualization.
- **Reader themes are a separate group, not theme roles.** Reader light's foreground (`#1d1b19`) is not `foreground` (`#000000`), and its link (`#b3121d`) is not `primary` (`#940008`); the reader theme is user state, independent of system appearance, and custom themes are runtime hex. So the palette is data: `reader.{light,sepia,gray,dark,black,red}` → `{background, foreground, link}`, generated like everything else. That table is also hand-duplicated today (`ios/Praxis/DesignSystem.swift:20-25` mirroring `android/.../reader/ReaderAppearance.kt:42-49`).

Doing this exercise surfaced drift the repo does not currently catch:

- **`primary-foreground` was never tokenized.** The primary button inverts white/black inline (`ios/Praxis/Components.swift:60`, `android/.../components/Components.kt:53`), and Android picks it from `isSystemInDarkTheme()`, so it produces the wrong text color under a forced `PraxisTheme(darkTheme = …)`. Tokenizing it fixes a bug, not just a name.
- **`separator` disagrees.** iOS uses `.separator` at 0.45 opacity; Android uses fixed `#123C3C43` / `#20545458`.
- **Chips exist only on Android**, as four extra roles plus three literal hexes, and `chipBackground` (`#E9E4DA`) is one step off `secondarySurface` (`#E8E3D9`). iOS inlines the chip in `PraxisApp.swift:452-453`.
- **Material mapping sets only four roles** (`primary`, `background`, `surface`, `on*`), so Material `Card` and `TextField` fall back to framework defaults. Neither platform defines a focus color at all.
- **Non-color drift:** `44` is still the row height in `ListRow` and `PraxisChip` on both platforms even though `sizing.touchTarget` is 48 and `spacing-pattern.md` §4 retires 44; chip padding is 15/10, off the 4-point scale; heading tracking is `-0.4` on Android and `-0.5` on iOS; and Android has no equivalent for three sizes iOS uses (title1 28, title3 20, caption 12).

The same treatment applies to type. `tokens.json` has no UI type scale — `typography` in it only sizes book-cover artwork — so type is declared three times: `PraxisFonts.swift`, `PraxisApp.swift`, and `PraxisTheme.kt`. One `typography.ui` group, built only from sizes already in use:

| Step | Size / leading | Family / weight | Pairs with (Android) |
| --- | --- | --- | --- |
| `display` | 34 / 50 | Literata Bold | `displayLarge` |
| `title1` | 28 / 42 | Literata Semibold | missing |
| `title2` | 22 / 33 | Literata Semibold | `titleLarge` |
| `title3` | 20 / 30 | Literata Semibold | missing |
| `headline` | 17 / 25 | Literata Semibold | `titleSmall` |
| `heading` | 17 / 25 | Literata Medium | `titleMedium` |
| `body` | 17 / 21 | Inter Regular | `bodyLarge` |
| `subhead` | 15 / 18 | Inter Regular | `bodyMedium` |
| `subhead-medium` | 15 / 18 | Inter Medium | `labelLarge` |
| `footnote` | 13 / 16 | Inter Regular | `labelMedium` |
| `caption` | 12 / 15 | Inter Regular | missing |
| `overline` | 15 / 18, +0.8 tracking, uppercase | Inter Semibold | `labelSmall` |
| `micro` | 12 / 15, +0.8 tracking | Inter Semibold | `labelSmall` |

Leading comes from the 1.485 Literata / 1.21 Inter ratios already asserted in `PraxisTheme.kt:80-82`, so nothing is invented. Three steps exist only on iOS today; writing the scale down is what makes that visible.

### 4.2 A component registry instead of prose-only contracts

`docs/spacing-pattern.md` already reads like a component contract — it names relationships, allowed values and tap targets. What it cannot do is tell you which components exist on each platform, or fail a build when iOS gains a component Android never gets.

A registry is a small manifest, adapted from shadcn's item schema:

```json
{
  "name": "book-cover",
  "platforms": ["ios", "android"],
  "files": {
    "ios": "ios/Praxis/Components.swift#BookCover",
    "android": "android/app/src/main/kotlin/br/praxis/android/design/components/Components.kt#BookCover"
  },
  "tokens": ["radius.cover", "colors.surface", "spacing.s2"],
  "spec": "Cover art 2:3, rounded per radius scale, optional progress badge."
}
```

Two checks make it real, both in the shape this repo already uses for catalogs and tokens: every file/symbol named must exist, and every component present on one platform must be declared on both with a `spec`. That is what turns "one visual language" from a doc people remember into a build failure.

The six components it should carry first are the ones Android already owns and iOS inlines, or the reverse:

| Component | Android | iOS today | Spec to write down |
| --- | --- | --- | --- |
| `InsetDivider` | `Components.kt:274`, 8 uses | inlined 6× | 1 hairline of `border`, start inset `s4` |
| `Chevron` | `Components.kt:285`, 10 uses | inlined 8× | 18×18, `muted-foreground`, accessibility-hidden |
| `SectionHeader` | `Components.kt:163`, 11 uses | inlined 3× | uppercase `overline`, row `s12`, trailing action ≥48×48 |
| `FilterChip` | `Components.kt:199` | inlined once | `radius.full`, height 48, `muted`/`foreground` pair |
| `AuthorArtwork` | `Components.kt:223`, 3 uses | inlined | monogram in `primary`, adaptive corner |
| `RoundIconTile` | `Components.kt:295` | 42×42 circle | diameter parameter, `muted` field, centered glyph |

It also gives the `PraxisApp.swift` split somewhere to land: 13 screens in 1843 lines, styled ad hoc (`.padding(.horizontal, 20)` where `s5` is the rule), against 10 shared Android composables. Extract a component, register it, delete the local copy.

### 4.3 Behavior vs presentation, for the reader

UI SDK's real contribution is separating behavior from presentation: keyboard handling, focus recovery, typeahead, dismissal and ARIA state live in the primitive, styling lives with you. That contract is renderer-independent even though the adapters are not, so the questions it asks are worth answering when the reader's controls grow.

It is not worth installing. `shared/reader/reader.js` is vanilla JS loaded into a WKWebView/WebView on purpose; adding a bundler, React 19 and a beta dependency to that payload trades the reader's main asset (fast start on old phones) for behaviors a single reading screen does not need. Revisit only if the reader gains app-like panels.

## 5. Where the literal library fits: a web surface

There is no web app today. `docs/` is a 27-line static support page on GitHub Pages with a hand-written `style.css` that mirrors the palette; `feedback-worker/` is a dependency-free Cloudflare Worker that forwards JSON to Resend.

If a landing page, public web reader or share-link page is ever on the roadmap, that is the build where shadcn earns its cost: Astro or Next, shadcn for the interactive parts, and a small generator from `design/tokens.json` to CSS custom properties using the same semantic names proposed above. For a 27-line page, a React runtime and a Tailwind build are not justifiable.

## 6. Recommendation

| Action | Verdict | Cost | Why |
| --- | --- | --- | --- |
| Semantic color layer + UI type scale in `tokens.json`, generated to Swift and Kotlin | Do next | 1–2 days | Removes a hand-maintained twin; the audit already found a forced-theme bug and four color drifts |
| Component registry + parity check in CI | Do after the token layer | 2–3 days | Makes `spacing-pattern.md` enforceable and indexes the `PraxisApp.swift` split |
| Split screens out of `PraxisApp.swift`, registering each component | Incremental, per screen | per screen | Real problem today: 1843 lines, literals that break the spacing rules |
| Vercel UI SDK in the reader | No | — | Beta, DOM-bound, bundler cost in a WebView |
| Community native ports | No, read only | — | Small, unversioned, one AGPL |
| shadcn/ui on a future web surface | Yes, if one ships | — | The only place the literal library fits |

## 7. First PR

Small, behavior-preserving, and it proves the generation path before anything depends on it:

- add a `semantic` group (role-paired colors, light and dark), a `reader.*` palette group and a `typography.ui` scale to `design/tokens.json`
- extend `tools/gen_tokens.py --write` to emit both layers to Swift as well as Kotlin, and `--check` to verify both
- fix `primary-foreground` while there; it is currently computed from `isSystemInDarkTheme()` on Android and wrong under a forced theme
- change no screens. Colors resolve from the new layer; nothing moves on screen.

Verify with `python3 tools/gen_tokens.py --check`, `python3 tools/check_shared.py` and `swift test --package-path ios`.
