import Foundation

/// Locates the catalogs that every platform ships.
///
/// The snapshots live at `shared/catalog/` in the repository root and are read directly by the
/// app target and by the Android assets. Tests resolve them relative to this file instead of a
/// bundle, so the path is defined in exactly one place.
enum SharedCatalog {
    static let directory: URL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent() // Tests
        .deletingLastPathComponent() // ios
        .deletingLastPathComponent() // repository root
        .appendingPathComponent("shared/catalog", isDirectory: true)

    static func data(for code: String) throws -> Data {
        try Data(contentsOf: directory.appendingPathComponent("catalog-\(code).json"))
    }
}
