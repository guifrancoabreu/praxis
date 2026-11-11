import Foundation

/// Primitive values shared across themes and components.
enum RefTokens {
    enum Spacing {
        // Monorepo reference scale; each step maps to 4 pt on iOS.
        static let s0: CGFloat = 0
        static let s1: CGFloat = 4
        static let s2: CGFloat = 8
        static let s3: CGFloat = 12
        static let s4: CGFloat = 16
        static let s5: CGFloat = 20
        static let s6: CGFloat = 24
        static let s8: CGFloat = 32
        static let s10: CGFloat = 40
        static let s12: CGFloat = 48
        static let s16: CGFloat = 64
        static let s20: CGFloat = 80
        static let s24: CGFloat = 96
    }

    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let full: CGFloat = 999
    }

    enum Colors {
        static let accentLight = "#940008"
        static let accentDark = "#FF7A7A"
        static let backgroundLight = "#FBFAF7"
        static let backgroundDark = "#1A1816"
        static let surfaceLight = "#FFFEFC"
        static let surfaceDark = "#262320"
        static let secondarySurfaceLight = "#E8E3D9"
        static let secondarySurfaceDark = "#33302B"
        static let coverOchre = "#8A5C26"
        static let coverRust = "#85382E"
        static let coverOlive = "#4D593D"
        static let coverBlue = "#365768"
        static let coverStoneLight = "#E8DECC"
        static let coverStoneDark = "#302B26"
    }

    enum Opacity {
        static let separator: CGFloat = 0.45
        static let coverOutline: CGFloat = 0.08
        static let coverShadow: CGFloat = 0.08
    }

    enum Shadow {
        static let coverRadius: CGFloat = 4
        static let coverOffsetY: CGFloat = 2
    }

    enum Typography {
        // Prefer native SwiftUI text styles in app UI; these sizes are for custom artwork only.
        static let bookCoverTitleCompact: CGFloat = 9
        static let bookCoverTitle: CGFloat = 10
        static let bookCoverBrand: CGFloat = 7
    }
}
