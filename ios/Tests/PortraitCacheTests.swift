import XCTest
@testable import ReaderCore

final class PortraitCacheTests: XCTestCase {
    func testCacheSurvivesNewInstanceAndAvoidsNetwork() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = URL(string: "https://example.com/portrait.jpg")!
        let bytes = Data("portrait".utf8)
        let first = PortraitCache(directory: directory, fetch: { url in
            (bytes, HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!)
        })
        let downloaded = try await first.data(for: url)
        XCTAssertEqual(downloaded, bytes)
        let second = PortraitCache(directory: directory, fetch: { _ in throw URLError(.notConnectedToInternet) })
        let cached = try await second.data(for: url)
        XCTAssertEqual(cached, bytes)
    }

    func testInvalidResponseIsNotCached() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = URL(string: "https://example.com/portrait.jpg")!
        let cache = PortraitCache(directory: directory, fetch: { url in
            (Data("error".utf8), HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: nil)!)
        })
        do { _ = try await cache.data(for: url); XCTFail("Expected failure") } catch {}
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.path))
    }
}
