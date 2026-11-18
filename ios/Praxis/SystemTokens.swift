#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import UIKit

/// Semantic roles composed from the primitive reference palette.
enum SystemTokens {
    struct Theme {
        let accent: Color
        let primaryForeground: Color
        let background: Color
        let surface: Color
        let secondarySurface: Color
        let textPrimary: Color
        let textSecondary: Color
        let separator: Color
        let coverOchre: Color
        let coverRust: Color
        let coverOlive: Color
        let coverBlue: Color
        let coverStone: Color
    }

    static let light = Theme(
        accent: Color(refHex: RefTokens.Semantic.primaryLight),
        primaryForeground: Color(refHex: RefTokens.Semantic.primaryForegroundLight),
        background: Color(refHex: RefTokens.Semantic.backgroundLight),
        surface: Color(refHex: RefTokens.Semantic.cardLight),
        secondarySurface: Color(refHex: RefTokens.Semantic.mutedLight),
        textPrimary: Color(refHex: RefTokens.Semantic.foregroundLight),
        textSecondary: Color(refHex: RefTokens.Semantic.mutedForegroundLight),
        separator: Color(refHex: RefTokens.Semantic.separatorLight),
        coverOchre: Color(refHex: RefTokens.Colors.coverOchre),
        coverRust: Color(refHex: RefTokens.Colors.coverRust),
        coverOlive: Color(refHex: RefTokens.Colors.coverOlive),
        coverBlue: Color(refHex: RefTokens.Colors.coverBlue),
        coverStone: Color(refHex: RefTokens.Colors.coverStoneLight)
    )

    static let dark = Theme(
        accent: Color(refHex: RefTokens.Semantic.primaryDark),
        primaryForeground: Color(refHex: RefTokens.Semantic.primaryForegroundDark),
        background: Color(refHex: RefTokens.Semantic.backgroundDark),
        surface: Color(refHex: RefTokens.Semantic.cardDark),
        secondarySurface: Color(refHex: RefTokens.Semantic.mutedDark),
        textPrimary: Color(refHex: RefTokens.Semantic.foregroundDark),
        textSecondary: Color(refHex: RefTokens.Semantic.mutedForegroundDark),
        separator: Color(refHex: RefTokens.Semantic.separatorDark),
        coverOchre: Color(refHex: RefTokens.Colors.coverOchre),
        coverRust: Color(refHex: RefTokens.Colors.coverRust),
        coverOlive: Color(refHex: RefTokens.Colors.coverOlive),
        coverBlue: Color(refHex: RefTokens.Colors.coverBlue),
        coverStone: Color(refHex: RefTokens.Colors.coverStoneDark)
    )

    enum Colors {
        static let accent = adaptive(\.accent)
        static let primaryForeground = adaptive(\.primaryForeground)
        static let background = adaptive(\.background)
        static let surface = adaptive(\.surface)
        static let secondarySurface = adaptive(\.secondarySurface)
        static let textPrimary = adaptive(\.textPrimary)
        static let textSecondary = adaptive(\.textSecondary)
        static let separator = adaptive(\.separator)
        static let coverOchre = adaptive(\.coverOchre)
        static let coverRust = adaptive(\.coverRust)
        static let coverOlive = adaptive(\.coverOlive)
        static let coverBlue = adaptive(\.coverBlue)
        static let coverStone = adaptive(\.coverStone)

        private static func adaptive(_ keyPath: KeyPath<Theme, Color>) -> Color {
            Color(uiColor: UIColor { traits in
                let color = traits.userInterfaceStyle == .dark ? SystemTokens.dark[keyPath: keyPath] : SystemTokens.light[keyPath: keyPath]
                return UIColor(color)
            })
        }
    }
}

private extension Color {
    /// Parses the generated `#RRGGBB` and `#AARRGGBB` reference values.
    init(refHex: String) {
        let hex = refHex.hasPrefix("#") ? String(refHex.dropFirst()) : refHex
        let value = Int(hex, radix: 16) ?? 0
        let hasAlpha = hex.count == 8
        let alpha = hasAlpha ? Double((value >> 24) & 0xff) / 255 : 1
        self.init(.sRGB,
                  red: Double((value >> 16) & 0xff) / 255,
                  green: Double((value >> 8) & 0xff) / 255,
                  blue: Double(value & 0xff) / 255,
                  opacity: alpha)
    }
}
#endif
