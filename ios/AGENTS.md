# iOS development guide

For design-system work, consult `/Users/guilhermefranco/coding/monorepo/docs/design/DESIGNING_APPS.md` and `ACCESSIBILITY.md` as guiding references. Adapt their principles to this small SwiftUI app; do not import the monorepo’s organizational or tooling complexity. Prefer native platform APIs and add abstractions only when a current feature needs them. The existing Android app remains separate.

## Organization and design

- Use semantic design tokens for shared colors, spacing, typography, and other repeated visual decisions. Support light and dark appearances and Dynamic Type. Add values as needs arise instead of inventing a complete system up front.
- Keep reusable, product-agnostic components separate from reader- and catalog-specific views. Generic components receive their visible copy from callers and do not fetch data or choose a language.
- Use native controls and accessibility semantics. Give icon-only controls meaningful localized labels; do not rely on color alone. Check VoiceOver, text scaling, contrast, and touch targets on a simulator or device before considering a screen finished.

## Localization and content

- Support English, Brazilian Portuguese, and Spanish. Keep user-facing copy in a single localization layer, not embedded in generic components. Use stable semantic keys and localized plural and number formatting when introducing a replacement for the current helper.
- Add translations for all supported languages in the same change. Tests should detect missing keys and placeholder mismatches; do not silently fall back to English for missing translations.
- Use clear, specific, actionable copy, especially for empty and error states. Catalog content comes from the selected archive language and is not translated by the app.

## Testing

- Add meaningful tests for each new or changed behavior in the same change: core parsing and localization, network/cache boundaries, and component or screen behavior where feasible. Exercise failures and important edge cases, not just implementation details.
- Use deterministic fixtures and mock network boundaries for routine tests. Cover the real reader journey and accessibility on an iOS simulator or device as a separate layer.
- Run `swift test --package-path ios` for core tests and build the Xcode project. Record simulator/device checks and any untested behavior honestly. A successful compile is not a UI or accessibility test.

## Current gaps

The MVP has a small token/component layer documented in DESIGN_SYSTEM.md, typed localization keys, and core catalog, localization, and palette tests. It does not yet meet the complete component, networking, reader, UI, or accessibility test expectations above. The Spanish catalog is a limited starter selection, not the full Spanish archive.
