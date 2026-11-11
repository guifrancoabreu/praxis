# iOS MVP

A SwiftUI iOS 17+ prototype, sharing the repository's Portuguese, English, and Spanish catalog snapshots (the Spanish starter catalog covers the archive’s selected Marxist writers). It supports language selection, browsing authors and their works, searching author names and work titles, reading HTML works, and caching opened pages. PDFs open externally. Cached pages may be removed by iOS when storage is needed; images are not guaranteed to be available offline.

Open `MarxistReader.xcodeproj` in Xcode, select the MarxistReader scheme and an iPhone simulator, then run. For a physical device, select your development team and, if necessary, change the bundle identifier in Signing & Capabilities. The catalog files are referenced directly from `../www/data`, so rebuilding after updating them includes the new snapshots.

This is an MVP, not Android feature parity: it does not yet include favorites, history, reading position, appearance controls, topics, countries, or glossary browsing. Links within a displayed page use WebKit navigation and have not yet been integrated with the native reader's offline cache. Run core tests with `swift test --package-path ios`. UI, network, and reader interactions still need automated coverage. Test representative pages, link navigation, and offline behavior on a device before release. Check rights and permissions for the original app code and archive content before distribution.

## Project conventions

See [AGENTS.md](AGENTS.md) for the lightweight development conventions and [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) for the shared tokens and components. These are the direction for future work; the current MVP does not yet meet every convention.
