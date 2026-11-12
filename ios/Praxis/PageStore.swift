import Foundation
import CryptoKit
import PDFKit

enum PageStore {
    static func load(_ url: URL) async throws -> String {
        if let text = await PageCache.shared.loadHTML(url) { return text }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode), http.url?.host == "www.marxists.org" else { throw URLError(.badServerResponse) }
        guard let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .windowsCP1252) else { throw URLError(.cannotDecodeContentData) }
        await PageCache.shared.save(Data(text.utf8), for: url)
        return text
    }
    static func loadPDF(_ url: URL) async throws -> Data {
        if let data = await PageCache.shared.loadPDF(url) { return data }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode), http.url?.host == "www.marxists.org" else { throw URLError(.badServerResponse) }
        guard await PageCache.shared.savePDF(data, for: url) else { throw URLError(.cannotDecodeContentData) }
        return data
    }
}

// Disk access, cache eviction and PDF parsing stay off the UI actor and are serialized.
actor PageCache {
    static let shared = PageCache()
    private let directory: URL
    init(directory: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("OfflinePages", isDirectory: true)) {
        self.directory = directory
    }
    private func cachedFile(for url: URL, extension ext: String = "") -> URL {
        let key = SHA256.hash(data: Data(url.absoluteString.utf8)).map { String(format: "%02x", $0) }.joined()
        return directory.appendingPathComponent(key + (ext.isEmpty ? "" : ".\(ext)"))
    }
    func loadHTML(_ url: URL) -> String? {
        let file = cachedFile(for: url)
        guard let data = try? Data(contentsOf: file), let text = String(data: data, encoding: .utf8) else { return nil }
        touch(file)
        return text
    }
    func loadPDF(_ url: URL) -> Data? {
        let file = cachedFile(for: url, extension: "pdf")
        guard let data = try? Data(contentsOf: file), PDFDocument(data: data) != nil else { return nil }
        touch(file)
        return data
    }
    func savePDF(_ data: Data, for url: URL) -> Bool {
        guard PDFDocument(data: data) != nil else { return false }
        save(data, for: url, extension: "pdf")
        return true
    }
    func save(_ data: Data, for url: URL, extension ext: String = "") {
        let file = cachedFile(for: url, extension: ext)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? data.write(to: file, options: .atomic)
        var values = URLResourceValues(); values.isExcludedFromBackup = true
        var savedFile = file; try? savedFile.setResourceValues(values)
        trimCache(keepingAtMost: 100 * 1024 * 1024)
    }
    private func touch(_ file: URL) {
        try? FileManager.default.setAttributes([.modificationDate: Date()], ofItemAtPath: file.path)
    }
    private func trimCache(keepingAtMost limit: Int) {
        let manager = FileManager.default
        guard let files = try? manager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey]) else { return }
        let sorted = files.compactMap { url -> (URL, Int, Date)? in
            guard let values = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey]) else { return nil }
            return (url, values.fileSize ?? 0, values.contentModificationDate ?? .distantPast)
        }.sorted { $0.2 > $1.2 }
        var total = 0
        for (url, size, _) in sorted {
            total += size
            if total > limit { try? manager.removeItem(at: url) }
        }
    }
}
