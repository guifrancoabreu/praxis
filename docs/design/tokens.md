# Design tokens

One set of values, generated for both apps. This doc is the contract: where a value lives, what is generated, and how to change a visual decision without starting the drift that `docs/ui-library-evaluation.md` describes.

## 1. Where values live

`design/tokens.json` is the single source of truth. Two files are generated from it and must not be edited by hand:

- `ios/Praxis/RefTokens.swift`
- `android/app/src/main/kotlin/br/praxis/android/design/Tokens.kt`

```sh
python3 tools/gen_tokens.py --write   # regenerate both
python3 tools/gen_tokens.py --check   # what CI runs; fails when either file is stale
```

Groups:

| Group | Holds | Consumed by |
| --- | --- | --- |
| `spacing`, `sizing`, `radius`, `opacity`, `shadow` | primitives, no colour | both apps via the generated files |
| `typography` | book-cover artwork sizes only — never UI text | `BookCover` |
| `colors` | the raw palette, suffixed `Light`/`Dark` | `semantic` only |
| `semantic` | role pairs, the layer screens use | `SystemTokens` (iOS), `PraxisTheme` (Android) |
| `type-scale` | the 13 UI text steps | `PraxisFont`, `PraxisTypography` |
| `reader` | the six reader palettes | `DesignSystem.swift`, `ReaderAppearance.kt` |

## 2. Screens use roles, not values

A screen picks a role: `SystemTokens.Colors.background` on iOS, `Praxis.colors.background` on Android. A hex or a raw palette constant in a screen is a bug.

Roles are paired, so a surface and its text move together: `background`/`foreground`, `card`, `popover`, `muted`/`muted-foreground`, `primary`/`primary-foreground`, `border`, `input`, `ring`, `separator`. `primary` is the brand red; there is no `accent` role for it, no `destructive` (nothing in the product needs one) and no `chart-*` (cover colours are artwork, not data).

If a colour is needed on both platforms, it becomes a role in `semantic` first. That is what keeps the two themes from drifting, and it is why `SystemTokens` and `PraxisTheme` compose instead of holding their own literals.

## 3. Type comes from the scale

Thirteen steps, `display` through `micro`, each with size, leading, weight and family. Use a step; do not invent a size. A new step needs a real screen that uses it on iOS first — iOS is the visual reference here, as in `docs/design/spacing.md`.

Material has no slot for `title3` or `caption`, so those two exist as `Typography` extensions in `PraxisTheme.kt`, named after their JSON step and imported at the call site. Keep that pattern for any future step Material cannot express.

## 4. Reader palettes are a separate group

`reader.{light,sepia,gray,dark,black,red}` carry `background`, `foreground` and `link`. Do not fold them into `semantic`: the reader theme is user state, independent of system appearance, and its light foreground (`#1d1b19`) is deliberately not `foreground` (`#000000`). Custom themes are runtime hex by design and stay out of the JSON.

## 5. Changing a visual decision

1. Check whether a role or step already covers it. Usually one does.
2. Otherwise add it to `design/tokens.json` — both `light` and `dark` for a colour.
3. Run `python3 tools/gen_tokens.py --write`.
4. Consume it: `SystemTokens`/`PraxisTheme` for a role, `PraxisFont`/`PraxisTypography` for a step. Never at the call site.
5. Run the checks: `gen_tokens.py --check`, `tools/check_shared.py`, `./gradlew :app:compileDebugKotlin`, `xcodebuild -scheme Praxis`, `swift test --package-path ios`.
6. If users will see the difference, say so in the PR — which platform moves and by how much, in points, not adjectives. `docs/ui-library-evaluation.md` §4.2 shows the format.

## 6. Enforced vs convention

Enforced by CI: the generated token files match the JSON, the shared catalogs and reader assets are intact, both apps build.

A reviewer's job: no literal colours or sizes in screens, spacing follows `docs/design/spacing.md`, type follows the scale, and a new shared component is declared for both platforms. The registry that will check that last one is not built yet — see `docs/ui-library-evaluation.md` §4.3.
