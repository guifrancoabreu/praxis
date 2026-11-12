import XCTest
import PDFKit
@testable import ReaderCore

final class PageCacheTests: XCTestCase {
    func testHTMLCacheAndInvalidPDF() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let cache = PageCache(directory: directory)
        let htmlURL = try XCTUnwrap(URL(string: "https://www.marxists.org/example.htm"))
        let pdfURL = try XCTUnwrap(URL(string: "https://www.marxists.org/example.pdf"))
        let missing = await cache.loadHTML(htmlURL)
        XCTAssertNil(missing)
        await cache.save(Data("<p>Texto</p>".utf8), for: htmlURL)
        let cached = await cache.loadHTML(htmlURL)
        XCTAssertEqual(cached, "<p>Texto</p>")
        let valid = await cache.savePDF(Data("not a PDF".utf8), for: pdfURL)
        XCTAssertFalse(valid)
        let invalid = await cache.loadPDF(pdfURL)
        XCTAssertNil(invalid)
    }
    func testValidPDFRoundTrip() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let cache = PageCache(directory: directory)
        let url = try XCTUnwrap(URL(string: "https://www.marxists.org/example.pdf"))
        let document = PDFDocument()
        document.insert(PDFPage(), at: 0)
        let data = try XCTUnwrap(document.dataRepresentation())
        let saved = await cache.savePDF(data, for: url)
        XCTAssertTrue(saved)
        let restored = await cache.loadPDF(url)
        XCTAssertEqual(restored, data)
    }
}
