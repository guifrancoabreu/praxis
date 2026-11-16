import Foundation

/// Reader assets shared with the Android app.
///
/// The stylesheet and the scripts live in `shared/reader` at the repository root and are bundled as
/// resources by each app. Both platforms must inject the same text, so this type is the only place
/// that composes the document script; a platform supplies just the host shim and the placeholders.
enum ReaderAssets {
    enum File: String {
        case stylesheet = "reader.css"
        case document = "reader.js"
        case link = "reader-link.js"
        case progress = "reader-progress.js"
        case images = "reader-images.js"

        var name: String { URL(fileURLWithPath: rawValue).deletingPathExtension().lastPathComponent }
        var pathExtension: String { URL(fileURLWithPath: rawValue).pathExtension }
    }

    static func text(_ file: File) -> String {
        if let url = Bundle.main.url(forResource: file.name, withExtension: file.pathExtension),
           let text = try? String(contentsOf: url, encoding: .utf8) {
            return text
        }
        // SwiftPM tests run without the app bundle; resolve the repository copy instead.
        let repository = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // Praxis
            .deletingLastPathComponent() // ios
            .deletingLastPathComponent() // repository root
            .appendingPathComponent("shared/reader", isDirectory: true)
            .appendingPathComponent(file.rawValue)
        if let text = try? String(contentsOf: repository, encoding: .utf8) { return text }
        assertionFailure("Missing shared reader asset: \(file.rawValue)")
        return ""
    }

    /// The script injected into every archive page, after the host defines its shim.
    static func documentScript(source: URL, appearance: ReaderAppearance, initialProgress: Double) -> String {
        let script = text(.document)
            .replacingOccurrences(of: "__READER_CSS__", with: jsonString(text(.stylesheet)))
            .replacingOccurrences(of: "__READER_IMAGES__", with: text(.images))
            .replacingOccurrences(of: "__READER_LINK__", with: text(.link))
            .replacingOccurrences(of: "__READER_PROGRESS__", with: text(.progress))
            .replacingOccurrences(of: "__INITIAL_APPEARANCE__", with: appearance.encoded)
            .replacingOccurrences(of: "__INITIAL_PROGRESS__", with: String(min(1, max(0, initialProgress))))
            .replacingOccurrences(of: "__INITIAL_FRAGMENT__", with: source.fragment.map(jsonString) ?? "null")
            .replacingOccurrences(of: "__SOURCE_URL__", with: jsonString(source.absoluteString))
        return script
    }

    /// Encodes a Swift string as a JSON string literal, so it can be embedded in the injected script.
    static func jsonString(_ value: String) -> String {
        guard let data = try? JSONEncoder().encode(value), let json = String(data: data, encoding: .utf8) else {
            return "\"\""
        }
        return json
    }
}
