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

    func testCreditResolutionUsesExactPathsAndLeavesUnknownUncredited() throws {
        let data = Data(#"{"authors":[{"id":"a","name":"Archive A","works":[["Known","known.htm","",0,"Actual author"],["Unknown","unknown.htm","",0,""],["Legacy","legacy.htm","",0],["Conflict","conflict.htm","",0,"One"]]},{"id":"b","name":"Archive B","works":[["Conflict","conflict.htm","",0,"Two"]]}]}"#.utf8)
        let catalog = try Catalog.decode(data, language: .en)
        XCTAssertEqual(catalog.credit(forPath: "known.htm"), "Actual author")
        XCTAssertNil(catalog.credit(forPath: "unknown.htm"))
        XCTAssertNil(catalog.credit(forPath: "legacy.htm"))
        XCTAssertNil(catalog.credit(forPath: "missing.htm"))
        XCTAssertNil(catalog.credit(forPath: "conflict.htm"))
    }

    func testCreditsUseCanonicalProfileNamesForAliasesAndKeepOtherAuthors() throws {
        let data = Data(#"{"authors":[{"id":"lenin","name":"Lênin, Vladimir I.","full":"Vladimir Ilitch Lênin","works":[["Herança","lenin.htm","",0,"V. I. Lénine"],["Herança com coautor","joint.htm","",0,"V. I. Lénine e Friedrich Engels"]]},{"id":"debs","name":"Eugene Debs","full":"Eugene Debs","works":[["Interview","interview.htm","",0,"Nellie Bly"]]},{"id":"abramowski","name":"Abramowski, Edward Józef","full":"Edward Józef Abramowski","works":[["Text","abramowski.htm","",0,"Edward Abramowski"]]}]}"#.utf8)
        let catalog = try Catalog.decode(data, language: .pt)

        XCTAssertEqual(catalog.credit(forPath: "lenin.htm"), "Vladimir Ilitch Lênin")
        XCTAssertEqual(catalog.credit(forPath: "joint.htm"), "Vladimir Ilitch Lênin e Friedrich Engels")
        XCTAssertEqual(catalog.credit(forPath: "interview.htm"), "Nellie Bly")
        XCTAssertEqual(catalog.credit(forPath: "abramowski.htm"), "Edward Józef Abramowski")
    }

    func testChapterCreditsUseNearestCataloguedWorkAndRespectUncreditedChildren() throws {
        let data = Data(#"{"authors":[{"id":"marx","name":"Marx","full":"Karl Marx","works":[["Capital","marx/1867/capital/index.htm","",0,"Karl Marx"],["Uncredited volume","marx/1867/capital/livro3/index.htm","",0,""],["Part A","marx/1867/capital/livro4/part-a.htm","",0,"Karl Marx"]]},{"id":"engels","name":"Engels","full":"Friedrich Engels","works":[["Prefaces","marx/1867/capital/livro1/prefacios/index.htm","",0,"Friedrich Engels"],["Part B","marx/1867/capital/livro4/part-b.htm","",0,"Friedrich Engels"]]}]}"#.utf8)
        let catalog = try Catalog.decode(data)
        let base = URL(string: Language.pt.base)!

        XCTAssertEqual(
            catalog.credit(forPath: "https://www.marxists.org/portugues/marx/1867/capital/livro1/cap01/01.htm", base: base),
            "Karl Marx"
        )
        XCTAssertEqual(
            catalog.credit(forPath: "marx/1867/capital/livro1/prefacios/03.htm", base: base),
            "Friedrich Engels"
        )
        XCTAssertNil(
            catalog.credit(forPath: "marx/1867/capital/livro3/cap01/01.htm", base: base),
            "An uncredited nearer catalog entry must block inheritance from the parent book."
        )
        XCTAssertNil(
            catalog.credit(forPath: "marx/1867/capital/livro4/unlisted.htm", base: base),
            "Sibling catalog works with different credits must not cause a guessed attribution."
        )
        XCTAssertEqual(
            catalog.credit(forPath: "https://www.marxists.org/portugues/marx/1867/capital/index.htm", base: base),
            "Karl Marx",
            "Absolute history URLs should resolve the same credit as catalog-relative paths."
        )
    }

    func testRealCapitalChapterAndEngelsPrefaceKeepTheirCatalogCredits() throws {
        let catalog = try portugueseCatalog()
        let base = URL(string: Language.pt.base)!

        XCTAssertEqual(
            catalog.credit(forPath: "https://www.marxists.org/portugues/marx/1867/capital/livro1/cap01/01.htm", base: base),
            "Karl Marx"
        )
        XCTAssertEqual(
            catalog.credit(forPath: "https://www.marxists.org/portugues/marx/1867/capital/livro1/prefacios/05.htm", base: base),
            "Friedrich Engels"
        )
    }

    func testUncreditedDuplicateDoesNotHideExplicitCredit() throws {
        let data = Data(#"{"authors":[{"id":"a","name":"Archive A","works":[["Shared","shared.htm","",0,"Actual author"],["Uncredited","uncredited.htm","",0]]},{"id":"b","name":"Archive B","works":[["Shared","shared.htm","",0]]}]}"#.utf8)
        let catalog = try Catalog.decode(data, language: .en)
        XCTAssertEqual(catalog.credit(forPath: "shared.htm"), "Actual author")
        XCTAssertNil(catalog.credit(forPath: "uncredited.htm"))
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

    func testReleasePinsStoredLanguageToPortuguese() {
        // Existing installations may still have English or Spanish stored.
        // The first release must show Portuguese without deleting that value.
        for storedCode in ["pt", "en", "es", "unknown"] {
            XCTAssertEqual(Language.releaseLanguage(for: storedCode), .pt)
        }
    }

    func testReleaseExposesOnlyPortugueseInLanguageSwitch() {
        XCTAssertEqual(Language.releaseLanguages, [.pt])
    }

    func testEnglishAndSpanishRemainAvailableForFutureRelease() {
        XCTAssertEqual(Language(rawValue: "en"), .en)
        XCTAssertEqual(Language(rawValue: "es"), .es)
        XCTAssertEqual(PrivacyPolicyCopy.forLanguage(.en).title, "Privacy")
        XCTAssertEqual(PrivacyPolicyCopy.forLanguage(.es).title, "Privacidad")
    }

    func testBundledCatalogSnapshotsDecode() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        for code in ["pt", "en", "es"] {
            let catalog = try Catalog.decode(Data(contentsOf: root.appendingPathComponent("Praxis/Resources/catalog-\(code).json")))
            XCTAssertGreaterThan(catalog.authors.count, 5)
            XCTAssertTrue(catalog.authors.contains { !$0.works.isEmpty })
        }
    }

    private func portugueseCatalog() throws -> Catalog {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        return try Catalog.decode(Data(contentsOf: root.appendingPathComponent("Praxis/Resources/catalog-pt.json")))
    }
}
