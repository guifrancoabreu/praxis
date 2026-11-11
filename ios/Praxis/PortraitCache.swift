import Foundation
import CryptoKit

/// Disposable on-disk cache; the system may remove it when storage is needed.
actor PortraitCache {
    static let shared = PortraitCache()
    private let directory: URL
    private let fetch: (URL) async throws -> (Data, URLResponse)
    private let isValid: (Data) -> Bool
    private let maxAge: TimeInterval

    init(directory: URL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("Portraits", isDirectory: true),
         maxAge: TimeInterval = 30 * 24 * 60 * 60,
         isValid: @escaping (Data) -> Bool = { !$0.isEmpty },
         fetch: @escaping (URL) async throws -> (Data, URLResponse) = { try await URLSession.shared.data(from: $0) }) {
        self.directory = directory
        self.maxAge = maxAge
        self.isValid = isValid
        self.fetch = fetch
    }

    func data(for url: URL, validate: ((Data) -> Bool)? = nil) async throws -> Data {
        let valid = validate ?? isValid
        let key = SHA256.hash(data: Data(url.absoluteString.utf8)).map { String(format: "%02x", $0) }.joined()
        let file = directory.appendingPathComponent(key)
        if let attributes = try? FileManager.default.attributesOfItem(atPath: file.path),
           let modified = attributes[.modificationDate] as? Date,
           Date().timeIntervalSince(modified) < maxAge,
           let data = try? Data(contentsOf: file), valid(data) {
            return data
        }
        let (data, response) = try await fetch(url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode), valid(data) else {
            throw URLError(.cannotDecodeContentData)
        }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? data.write(to: file, options: .atomic)
        return data
    }
}
