import SwiftUI

#if canImport(SwiftUI) && canImport(UIKit)
import CoreText
import UIKit
#endif

/// Praxis's bundled typefaces.
///
/// Headings and titles use Literata; body copy, labels, and controls use Inter.
/// Both families ship as variable TTFs in `Praxis/Fonts` and are registered with
/// CoreText at launch (the generated Info.plist has no `UIAppFonts`). Each helper
/// scales with Dynamic Type exactly like the system text style it stands in for.
enum PraxisFont {
    static let headingFamily = "Literata"
    static let bodyFamily = "Inter"

    /// A heading, title, or section header in Literata, scaled like `style`.
    static func heading(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        #if canImport(SwiftUI) && canImport(UIKit)
        return Font.custom(headingFamily, size: basePointSize(for: style), relativeTo: style).weight(weight)
        #else
        return .system(style, design: .serif).weight(weight)
        #endif
    }

    /// Body copy, labels, and controls in Inter, scaled like `style`.
    static func body(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        #if canImport(SwiftUI) && canImport(UIKit)
        return Font.custom(bodyFamily, size: basePointSize(for: style), relativeTo: style).weight(weight)
        #else
        return .system(style, design: .default).weight(weight)
        #endif
    }

    /// An explicit point size for the few decorative sizes (cover lettering).
    static func fixed(_ size: CGFloat, weight: Font.Weight = .regular, heading: Bool = false) -> Font {
        #if canImport(SwiftUI) && canImport(UIKit)
        return Font.custom(heading ? headingFamily : bodyFamily, fixedSize: size).weight(weight)
        #else
        return .system(size: size, design: heading ? .serif : .default).weight(weight)
        #endif
    }

    /// Large-size defaults for the system text styles, used as the base size that
    /// Dynamic Type scales from.
    static func basePointSize(for style: Font.TextStyle) -> CGFloat {
        basePointSizes[style] ?? 17
    }

    private static let basePointSizes: [Font.TextStyle: CGFloat] = [
        .largeTitle: 34,
        .title: 28,
        .title2: 22,
        .title3: 20,
        .headline: 17,
        .subheadline: 15,
        .body: 17,
        .callout: 16,
        .footnote: 13,
        .caption: 12,
        .caption2: 11
    ]

    /// Registers the bundled TTFs for this process. Safe to call more than once;
    /// the registration runs lazily on the first call.
    static func registerBundledFonts() {
        #if canImport(SwiftUI) && canImport(UIKit)
        _ = registration
        #endif
    }

    #if canImport(SwiftUI) && canImport(UIKit)
    private static let registration: Void = {
        let urls = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? []
        for url in urls {
            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                if let error {
                    print("PraxisFont: could not register \(url.lastPathComponent): \(error.takeRetainedValue())")
                } else {
                    print("PraxisFont: could not register \(url.lastPathComponent)")
                }
            }
        }
    }()
    #endif
}
