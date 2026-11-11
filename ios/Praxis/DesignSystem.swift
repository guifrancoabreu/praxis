import Foundation

/// Shared visual roles. Keep product data and localized copy in the calling screen.
enum DesignTokens {
    enum Spacing {
        static let compact: CGFloat = 4
        static let rowInset: CGFloat = 4
        static let standard: CGFloat = 16
    }

    enum Reader {
        static let lightBackground = "#FBFAF7"
        static let lightForeground = "#1D1B19"
        static let lightLink = "#9A0007"
        static let darkBackground = "#1C1C1E"
        static let darkForeground = "#F2F2F7"
        static let darkLink = "#FF9B96"

        // WebKit's system body font tracks the device's preferred text size.
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
}

#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import UIKit

extension DesignTokens {
    static let accent = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 1, green: 0.48, blue: 0.48, alpha: 1)
            : UIColor(red: 0.58, green: 0, blue: 0.03, alpha: 1)
    })
    static let paper = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.10, green: 0.095, blue: 0.09, alpha: 1)
            : UIColor(red: 0.984, green: 0.98, blue: 0.969, alpha: 1)
    })
    static let surface = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.15, green: 0.14, blue: 0.13, alpha: 1)
            : UIColor(red: 1, green: 0.998, blue: 0.989, alpha: 1)
    })
    static let muted = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.secondaryLabel
            : UIColor(red: 0.32, green: 0.30, blue: 0.28, alpha: 1)
    })
    static let filterSurface = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.20, green: 0.19, blue: 0.18, alpha: 1)
            : UIColor(red: 0.91, green: 0.89, blue: 0.85, alpha: 1)
    })
    static let ink = Color(uiColor: .label)
    static let rule = Color(uiColor: .separator).opacity(0.45)
    static let coverOchre = Color(red: 0.54, green: 0.36, blue: 0.15)
    static let coverRust = Color(red: 0.52, green: 0.22, blue: 0.18)
    static let coverOlive = Color(red: 0.30, green: 0.35, blue: 0.24)
    static let coverBlue = Color(red: 0.21, green: 0.34, blue: 0.41)
    static let coverStone = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.19, green: 0.17, blue: 0.15, alpha: 1)
            : UIColor(red: 0.91, green: 0.87, blue: 0.80, alpha: 1)
    })
    static let rowSpacing: CGFloat = 4
}

/// A neutral list label; NavigationLink supplies the interaction and accessibility role.
struct ListRow: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.compact) {
            Text(title).font(.headline)
            if !subtitle.isEmpty {
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, DesignTokens.Spacing.rowInset)
    }
}
#endif
