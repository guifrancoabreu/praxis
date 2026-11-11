import XCTest
@testable import ReaderCore

final class CatalogTests: XCTestCase {
    func testCatalogDecodesAuthorsAndWorkMetadata() throws {
        let data = Data(#"{"generated":"2026-01-01","authors":[{"id":"marx","name":"Marx","dates":"1818–1883","sections":["Books"],"works":[["Capital","capital.htm","1867",0]]}]}"#.utf8)
        let catalog = try Catalog.decode(data)
        XCTAssertEqual(catalog.generated, "2026-01-01")
        XCTAssertEqual(catalog.authors.first?.works.first?.title, "Capital")
        XCTAssertEqual(catalog.authors.first?.works.first?.section, 0)
        XCTAssertEqual(catalog.authors.first?.dates, "1818–1883")
    }

    func testInvalidCatalogFails() {
        XCTAssertThrowsError(try Catalog.decode(Data("{}".utf8)))
    }

    func testTranslationsAndArchiveBases() {
        XCTAssertEqual(Language.pt.text("Autores", "Writers"), "Autores")
        XCTAssertEqual(Language.en.text("Autores", "Writers"), "Writers")
        XCTAssertEqual(Language.es.text("Autores", "Writers"), "Autores")
        XCTAssertEqual(Language.pt.base, "https://www.marxists.org/portugues/")
        XCTAssertEqual(Language.en.base, "https://www.marxists.org/")
        XCTAssertEqual(Language.es.base, "https://www.marxists.org/espanol/")
    }

    func testBundledCatalogSnapshotsDecode() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        for code in ["pt", "en", "es"] {
            let catalog = try Catalog.decode(Data(contentsOf: root.appendingPathComponent("Praxis/Resources/catalog-\(code).json")))
            XCTAssertGreaterThan(catalog.authors.count, 5)
            XCTAssertTrue(catalog.authors.contains { !$0.works.isEmpty })
        }
    }
}
