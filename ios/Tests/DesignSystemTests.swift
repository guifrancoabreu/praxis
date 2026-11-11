import XCTest
@testable import ReaderCore

final class DesignSystemTests: XCTestCase {
    private func luminance(_ hex: String) -> Double {
        let value = Int(hex.dropFirst(), radix: 16)!
        func channel(_ shift: Int) -> Double {
            let c = Double((value >> shift) & 255) / 255
            return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(16) + 0.7152 * channel(8) + 0.0722 * channel(0)
    }

    private func contrast(_ foreground: String, _ background: String) -> Double {
        let a = luminance(foreground), b = luminance(background)
        return (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }

    func testReaderTextAndLinksMeetNormalTextContrastInBothThemes() {
        let reader = DesignTokens.Reader.self
        for (foreground, background) in [
            (reader.lightForeground, reader.lightBackground), (reader.lightLink, reader.lightBackground),
            (reader.darkForeground, reader.darkBackground), (reader.darkLink, reader.darkBackground)
        ] {
            XCTAssertGreaterThanOrEqual(contrast(foreground, background), 4.5)
        }
    }
}
