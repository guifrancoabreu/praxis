# iOS design system

This small system follows the principles in the monorepo’s design and accessibility guides, adapted to SwiftUI. It grows from real screens rather than mirroring the monorepo's packages or tooling.

## Tokens

`DesignTokens` in `Praxis/DesignSystem.swift` owns shared semantic values. Use `accent` for interactive emphasis, `Spacing` for recurring layout, and `Reader` for the web reader's light/dark palette and stylesheet. Prefer native semantic colors and SwiftUI text styles where the platform already supplies the role and accessibility behavior. Add a token when a shared visual decision emerges; avoid inventing unused scales.

## Components

`ListRow(title:subtitle:)` is a product-agnostic label for list navigation. The caller supplies both strings; an empty subtitle is omitted. Place it inside a native `NavigationLink` so the platform supplies interaction, focus, and accessibility semantics. Screen-specific behavior, data, and translated copy belong to the caller.

## Verification

Run the core tests and build described in the iOS README. Reader palette tests check contrast mathematically; they do not establish accessibility compliance. Before considering a screen finished, inspect both appearances, large text, VoiceOver, and touch targets in a simulator or on a device. The WebKit reader's response to text-size changes and archive-specific HTML still requires device verification.
