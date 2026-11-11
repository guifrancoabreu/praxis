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

    func testSharedArchiveUsesSourceCredits() throws {
        let data = Data(#"{"authors":[{"id":"marx","name":"Marx","full":"Karl Marx Friedrich Engels","sections":[""],"works":[["Engels work","engels.htm","",0,"Friedrich Engels"],["Joint work","joint.htm","",0,"Karl Marx e Friedrich Engels"],["Unknown","unknown.htm","",0,""]]}]}"#.utf8)
        let catalog = try Catalog.decode(data)
        let marx = try XCTUnwrap(catalog.authors.first { $0.id == "marx" })
        let engels = try XCTUnwrap(catalog.authors.first { $0.id == "engels" })
        XCTAssertEqual(marx.works.map(\.path), ["joint.htm", "unknown.htm"])
        XCTAssertEqual(engels.works.map(\.path), ["engels.htm", "joint.htm"])
        XCTAssertEqual(marx.works.last?.credit, "")
        XCTAssertEqual(marx.works.first?.credit, "Karl Marx e Friedrich Engels")
    }

    func testCreditResolutionUsesExactPathsAndExplicitUnknown() throws {
        let data = Data(#"{"authors":[{"id":"a","name":"Archive A","works":[["Known","known.htm","",0,"Actual author"],["Unknown","unknown.htm","",0,""],["Legacy","legacy.htm","",0],["Conflict","conflict.htm","",0,"One"]]},{"id":"b","name":"Archive B","works":[["Conflict","conflict.htm","",0,"Two"]]}]}"#.utf8)
        let catalog = try Catalog.decode(data, language: .en)
        XCTAssertEqual(catalog.credit(forPath: "known.htm"), "Actual author")
        XCTAssertEqual(catalog.credit(forPath: "unknown.htm"), "")
        XCTAssertEqual(catalog.credit(forPath: "legacy.htm"), "")
        XCTAssertNil(catalog.credit(forPath: "missing.htm"))
        XCTAssertNil(catalog.credit(forPath: "conflict.htm"))
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
