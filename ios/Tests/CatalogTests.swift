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
        XCTAssertEqual(Language.pt.text(.writers), "Autores")
        XCTAssertEqual(Language.en.text(.writers), "Writers")
        XCTAssertEqual(Language.es.text(.writers), "Autores")
        XCTAssertEqual(Language.pt.base, "https://www.marxists.org/portugues/")
        XCTAssertEqual(Language.en.base, "https://www.marxists.org/")
        XCTAssertEqual(Language.es.base, "https://www.marxists.org/espanol/")
    }

    func testEveryCopyKeyHasNonemptyTranslations() {
        for key in CopyKey.allCases {
            for language in Language.allCases {
                XCTAssertFalse(language.text(key).trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "Missing \(key) for \(language)")
            }
        }
    }

    func testWorkCountsUseSingularAndPluralInEachLanguage() {
        XCTAssertEqual(Language.en.workCount(1), "1 work")
        XCTAssertEqual(Language.en.workCount(2), "2 works")
        XCTAssertEqual(Language.pt.workCount(1), "1 texto")
        XCTAssertEqual(Language.pt.workCount(2), "2 textos")
        XCTAssertEqual(Language.es.workCount(1), "1 obra")
        XCTAssertEqual(Language.es.workCount(2), "2 obras")
    }

    func testBundledCatalogSnapshotsDecode() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        for code in ["pt", "en", "es"] {
            let catalog = try Catalog.decode(Data(contentsOf: root.appendingPathComponent("www/data/catalog-\(code).json")))
            XCTAssertGreaterThan(catalog.authors.count, 5)
            XCTAssertTrue(catalog.authors.contains { !$0.works.isEmpty })
        }
    }
}
