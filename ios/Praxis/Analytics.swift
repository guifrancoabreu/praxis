import Foundation
import TelemetryDeck

/// Explicit event allowlist. Never add work titles, author names, search text,
/// archive paths, or reading positions to analytics properties.
enum Analytics {
    enum Event {
        case filterSelected(LibraryFilter)
        case searchUsed
        case authorProfileOpened
        case workOpened
        case bookmarkChanged(isSaved: Bool)
        case readerAppearanceOpened
        case archiveSourceOpened
        case supportPageOpened
        case supportDestinationOpened(SupportDestination)

        var name: String {
            switch self {
            case .filterSelected: "Library.Filter.Selected"
            case .searchUsed: "Library.Search.Used"
            case .authorProfileOpened: "Library.AuthorProfile.Opened"
            case .workOpened: "Reader.Work.Opened"
            case .bookmarkChanged: "Reader.Bookmark.Changed"
            case .readerAppearanceOpened: "Reader.Appearance.Opened"
            case .archiveSourceOpened: "Reader.ArchiveSource.Opened"
            case .supportPageOpened: "Support.Page.Opened"
            case .supportDestinationOpened: "Support.Destination.Opened"
            }
        }

        var parameters: [String: String] {
            switch self {
            case .filterSelected(let filter): ["filter": filter.rawValue]
            case .bookmarkChanged(let isSaved): ["saved": isSaved ? "true" : "false"]
            case .supportDestinationOpened(let destination): ["destination": destination.rawValue]
            default: [:]
            }
        }
    }

    private static let appID = "YOUR-TELEMETRYDECK-APP-ID"
    private static var isConfigured = false
    private static var configuration: TelemetryDeck.Config?

    static func configure() {
        guard !appID.isEmpty, appID != "YOUR-TELEMETRYDECK-APP-ID" else {
            UserDefaults.standard.set(false, forKey: "analyticsConsent")
            return
        }
        let config = TelemetryDeck.Config(appID: appID)
        config.analyticsDisabled = !UserDefaults.standard.bool(forKey: "analyticsConsent")
        TelemetryDeck.initialize(config: config)
        configuration = config
        isConfigured = true
    }

    static var isAvailable: Bool { isConfigured }

    static func setConsent(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "analyticsConsent")
        configuration?.analyticsDisabled = !enabled
    }

    static func track(_ event: Event) {
        guard isConfigured, configuration?.analyticsDisabled == false else { return }
        TelemetryDeck.signal(event.name, parameters: event.parameters)
    }
}

enum SupportDestination: String {
    case kofi
    case archive
    case volunteer
}
