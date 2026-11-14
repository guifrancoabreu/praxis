import Foundation

enum ReaderTokens {
    static let lightBackground = "#FBFAF7"
    static let lightForeground = "#1D1B19"
    static let lightLink = "#9A0007"
    static let darkBackground = "#1C1C1E"
    static let darkForeground = "#F2F2F7"
    static let darkLink = "#FF9B96"

    static let stylesheet = """
    :root { color-scheme: light dark; }
    html { -webkit-text-size-adjust: 100%; }
    body { max-width: 44rem; margin: auto; padding: 24px 20px 60px;
        background: \(lightBackground); color: \(lightForeground);
        font: -apple-system-body; font-family: Georgia, serif; line-height: 1.65;
        overflow-wrap: anywhere; }
    img, table { max-width: 100%; height: auto; }
    a { color: \(lightLink); }
    @media (prefers-color-scheme: dark) {
        body { background: \(darkBackground); color: \(darkForeground); }
        a { color: \(darkLink); }
    }
    """
}


struct ReaderAppearance: Codable, Equatable {
    static let builtInThemes = ["light", "sepia", "gray", "dark", "black", "red"]
    var font = "serif"
    var size = 19
    var lineSpacing = 1.6
    var margin = 18
    var alignment = "left"
    var theme = "light"
    var background = "#fbfaf7"
    var foreground = "#1d1b19"
    var link = "#b3121d"
    var encoded: String { (try? String(data: JSONEncoder().encode(self), encoding: .utf8)) ?? "" }
    static func decode(_ data: String) -> ReaderAppearance {
        (try? JSONDecoder().decode(ReaderAppearance.self, from: Data(data.utf8))) ?? ReaderAppearance()
    }
    mutating func setTheme(_ value: String) {
        theme = value
        let palette: [String: (String, String, String)] = [
            "light": ("#fbfaf7", "#1d1b19", "#b3121d"), "sepia": ("#f4ecd8", "#3b2f22", "#9c2a12"),
            "gray": ("#d9d9d6", "#202020", "#8e0d16"), "dark": ("#1c1c1e", "#dedede", "#ff8a80"),
            "black": ("#000000", "#c9c9c9", "#ff6e6e"), "red": ("#4a0808", "#fbe9d0", "#ffcc00")
        ]
        if let colors = palette[value] { background = colors.0; foreground = colors.1; link = colors.2 }
    }
}

enum ColorContrast {
    private static func luminance(_ hex: String) -> Double? {
        guard hex.count == 7, hex.first == "#", let value = Int(hex.dropFirst(), radix: 16) else { return nil }
        func channel(_ shift: Int) -> Double {
            let c = Double((value >> shift) & 255) / 255
            return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(16) + 0.7152 * channel(8) + 0.0722 * channel(0)
    }

    static func ratio(_ foreground: String, _ background: String) -> Double? {
        guard let a = luminance(foreground), let b = luminance(background) else { return nil }
        return (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }
}

// Give relative archive links a base without making the initial WebKit navigation remote.
enum ReaderHTML {
    static let imageLoadingScript = """
    document.querySelectorAll('img').forEach((img, i) => { if (i >= 2) img.loading = 'lazy'; img.decoding = 'async'; });
    """
    static func withBaseURL(_ url: URL, in html: String) -> String {
        let escaped = url.absoluteString.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "<", with: "&lt;")
        let base = "<base href=\"\(escaped)\">"
        guard let head = html.range(of: "<head(?:\\s[^>]*)?>", options: [.regularExpression, .caseInsensitive]) else {
            return base + html
        }
        var result = html
        result.insert(contentsOf: base, at: head.upperBound)
        return result
    }
}

// Limit messages across the WebKit bridge while keeping the final scroll position.
enum ReaderProgress {
    static let javascript = """
    let progressTimer = null;
    const scheduleReport = () => { if (progressTimer === null) progressTimer = setTimeout(() => { progressTimer = null; report(); }, 500); };
    const flushReport = () => { if (progressTimer !== null) { clearTimeout(progressTimer); progressTimer = null; report(); } };
    window.addEventListener('scroll', scheduleReport, { passive: true });
    window.addEventListener('scrollend', flushReport);
    window.addEventListener('pagehide', flushReport);
    """
}

enum ReaderLink {
    enum Destination: Equatable {
        case archive(URL)
        case external(URL)
        case unsupported
    }
    static func destination(for url: URL) -> Destination {
        guard let scheme = url.scheme?.lowercased(), ["http", "https"].contains(scheme),
              let host = url.host?.lowercased() else { return .unsupported }
        let ext = url.pathExtension.lowercased()
        if ["www.marxists.org", "marxists.org"].contains(host), ["", "htm", "html", "pdf"].contains(ext),
           var components = URLComponents(url: url, resolvingAgainstBaseURL: true),
           components.user == nil, components.password == nil, components.port == nil {
            components.scheme = "https"
            components.host = "www.marxists.org"
            if let target = components.url { return .archive(target) }
        }
        return .external(url)
    }

    static let javascript = """
    const scrollToReaderAnchor = (fragment) => {
        let id; try { id = decodeURIComponent(fragment); } catch (_) { id = fragment; }
        if (!id || id.toLowerCase() === 'top') { window.scrollTo(0, 0); return true; }
        const target = document.getElementById(id) || document.getElementsByName(id)[0];
        if (!target) return false;
        target.scrollIntoView(); return true;
    };
    document.addEventListener('click', event => {
        const link = event.target.closest && event.target.closest('a[href]');
        if (!link) return;
        const href = link.getAttribute('href');
        if (href === '#') { event.preventDefault(); window.scrollTo(0, 0); return; }
        let destination, source;
        try { destination = new URL(href, sourceURL); source = new URL(sourceURL); } catch (_) { return; }
        if (destination.hash && destination.origin === source.origin && destination.pathname === source.pathname && destination.search === source.search) {
            event.preventDefault(); scrollToReaderAnchor(destination.hash.slice(1)); return;
        }
        event.preventDefault();
        window.webkit.messageHandlers.readerLink.postMessage({url: destination.href, title: (link.textContent || '').trim()});
    });
    """
}
