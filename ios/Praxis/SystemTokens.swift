#if canImport(SwiftUI) && canImport(UIKit)
import SwiftUI
import UIKit

/// Semantic roles composed from the primitive reference palette.
enum SystemTokens {
    struct Theme {
        let accent: Color
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
        accent: Color(refHex: RefTokens.Colors.accentLight),
        background: Color(refHex: RefTokens.Colors.backgroundLight),
        surface: Color(refHex: RefTokens.Colors.surfaceLight),
        secondarySurface: Color(refHex: RefTokens.Colors.secondarySurfaceLight),
        textPrimary: Color(uiColor: .label),
        textSecondary: Color(refHex: "#524D47"),
        separator: Color(uiColor: .separator).opacity(RefTokens.Opacity.separator),
        coverOchre: Color(refHex: RefTokens.Colors.coverOchre),
        coverRust: Color(refHex: RefTokens.Colors.coverRust),
        coverOlive: Color(refHex: RefTokens.Colors.coverOlive),
        coverBlue: Color(refHex: RefTokens.Colors.coverBlue),
        coverStone: Color(refHex: RefTokens.Colors.coverStoneLight)
    )

    static let dark = Theme(
        accent: Color(refHex: RefTokens.Colors.accentDark),
        background: Color(refHex: RefTokens.Colors.backgroundDark),
        surface: Color(refHex: RefTokens.Colors.surfaceDark),
        secondarySurface: Color(refHex: RefTokens.Colors.secondarySurfaceDark),
        textPrimary: Color(uiColor: .label),
        textSecondary: Color(uiColor: .secondaryLabel),
        separator: Color(uiColor: .separator).opacity(RefTokens.Opacity.separator),
        coverOchre: Color(refHex: RefTokens.Colors.coverOchre),
        coverRust: Color(refHex: RefTokens.Colors.coverRust),
        coverOlive: Color(refHex: RefTokens.Colors.coverOlive),
        coverBlue: Color(refHex: RefTokens.Colors.coverBlue),
        coverStone: Color(refHex: RefTokens.Colors.coverStoneDark)
    )

    enum Colors {
        static let accent = adaptive(\.accent)
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
    init(refHex: String) {
        let value = Int(refHex.dropFirst(), radix: 16) ?? 0
        self.init(.sRGB,
                  red: Double((value >> 16) & 0xff) / 255,
                  green: Double((value >> 8) & 0xff) / 255,
                  blue: Double(value & 0xff) / 255,
                  opacity: 1)
    }
}
#endif
