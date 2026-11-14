import XCTest
@testable import ReaderCore

final class ReadingHistoryTests: XCTestCase {
    private let base = URL(string: "https://www.marxists.org/portugues/")!
    private let manifesto = "marx/1848/ManifestoDoPartidoComunista/index.htm"
    private let galicianManifesto = "marx/1848/ManifestoDoPartidoComunistaEmGalego/index.htm"

    private func key(_ path: String) -> String {
        ReadingHistory.canonicalKey(for: path, base: base)
    }

    func testLegacyJSONIsMigratedWithoutLosingEntries() throws {
        let json = """
        [
          {"path":"https://www.marxists.org/portugues/marx/1848/ManifestoDoPartidoComunista/prefacio.htm","title":"Prefácio","author":"","progress":0.4},
          {"path":"marx/1848/ManifestoDoPartidoComunista/index.htm","title":"Manifesto do Partido Comunista","author":"Karl Marx","progress":0.25},
          {"path":"https://example.com/long","title":"Other work","author":"","progress":0.5},
          {"path":"https://example.com/short","title":"Another work","author":"","progress":0.1}
        ]
        """

        let migrated = ReadingHistory.migrated(fromJSON: json, base: base, knownWorkPaths: [key(manifesto)])

        XCTAssertEqual(migrated.count, 4, "Legacy entries must not be discarded.")
        XCTAssertEqual(migrated[0].title, "Prefácio")
        XCTAssertEqual(migrated[1].title, "Manifesto do Partido Comunista")
        XCTAssertEqual(migrated[0].workID, key(manifesto))
        XCTAssertEqual(migrated[1].workID, key(manifesto))
        XCTAssertNotEqual(migrated[2].workID, migrated[3].workID)
        XCTAssertEqual(migrated[2].workID, key("https://example.com/long"))
        XCTAssertEqual(migrated[3].workID, key("https://example.com/short"))
    }

    func testLegacyChaptersAreGroupedUnderTheWorkIndex() {
        let json = """
        [
          {"path":"https://www.marxists.org/portugues/marx/1848/ManifestoDoPartidoComunista/prefacio.htm","title":"Prefácio","author":"","progress":0.4},
          {"path":"marx/1848/ManifestoDoPartidoComunista/index.htm","title":"Manifesto do Partido Comunista","author":"Karl Marx","progress":0.25},
          {"path":"https://example.com/long","title":"Other work","author":"","progress":0.5},
          {"path":"https://example.com/short","title":"Another work","author":"","progress":0.1}
        ]
        """

        let history = ReadingHistory.history(fromJSON: json, base: base, knownWorkPaths: [key(manifesto)])

        XCTAssertEqual(history.count, 3)
        XCTAssertEqual(history[0].path, "https://www.marxists.org/portugues/marx/1848/ManifestoDoPartidoComunista/prefacio.htm")
        XCTAssertEqual(history[0].title, "Manifesto do Partido Comunista")
        XCTAssertEqual(history[0].author, "Karl Marx")
        XCTAssertEqual(history[0].progress, 0.4, accuracy: 0.0001)
        XCTAssertEqual(history[1].title, "Other work")
        XCTAssertEqual(history[2].title, "Another work")
    }

    func testLinkNavigationKeepsIdentityInsideTheWorkDirectory() {
        let known = Set([key(manifesto), key(galicianManifesto), key("marx/1848/ManifestoDoPartidoComunista/manifesto.pdf")])
        let work = ReadingWork(path: manifesto, title: "Manifesto do Partido Comunista", author: "Karl Marx", base: base, knownWorkPaths: known)

        let chapter = URL(string: "https://www.marxists.org/portugues/marx/1848/ManifestoDoPartidoComunista/capitulo-1.htm")!
        let same = work.destination(for: chapter, base: base)
        XCTAssertEqual(same, work)
        XCTAssertEqual(same?.title, "Manifesto do Partido Comunista")
        XCTAssertEqual(same?.author, "Karl Marx")

        let preface = URL(string: "https://www.marxists.org/portugues/marx/1848/ManifestoDoPartidoComunista/prefacio-1872.htm")!
        XCTAssertEqual(work.destination(for: preface, base: base), work)
    }

    func testLinksToOtherWorksStartSeparateIdentities() {
        let known = Set([key(manifesto), key(galicianManifesto), key("marx/guerra/04.htm"), key("marx/guerra/05.htm")])
        let work = ReadingWork(path: manifesto, title: "Manifesto do Partido Comunista", author: "Karl Marx", base: base, knownWorkPaths: known)

        let galician = URL(string: "https://www.marxists.org/portugues/marx/1848/ManifestoDoPartidoComunistaEmGalego/index.htm")!
        XCTAssertNil(work.destination(for: galician, base: base))
        let followed = work.following(galician, title: "Manifesto (galego)", base: base)
        XCTAssertNotEqual(followed.id, work.id)
        XCTAssertEqual(followed.title, "Manifesto (galego)")
        XCTAssertEqual(followed.author, "", "A link cannot establish authorship.")

        // These two are different catalogue works even though they share a directory.
        let war = ReadingWork(path: "marx/guerra/04.htm", title: "A Guerra Civil Norte-Americana", author: "Karl Marx", base: base, knownWorkPaths: known)
        let nextWarArticle = URL(string: "https://www.marxists.org/portugues/marx/guerra/05.htm")!
        XCTAssertNil(war.destination(for: nextWarArticle, base: base))
    }

    func testResumeUsesTheLastDestinationAndItsProgress() {
        let workID = key(manifesto)
        let entries = [
            ReadingProgress(path: "https://www.marxists.org/portugues/marx/1848/ManifestoDoPartidoComunista/capitulo-2.htm", title: "Manifesto do Partido Comunista", author: "Karl Marx", progress: 0.72, workID: workID),
            ReadingProgress(path: "https://www.marxists.org/portugues/marx/1848/ManifestoDoPartidoComunista/capitulo-1.htm", title: "Manifesto do Partido Comunista", author: "Karl Marx", progress: 0.9, workID: workID),
            ReadingProgress(path: manifesto, title: "Manifesto do Partido Comunista", author: "Karl Marx", progress: 0.3, workID: workID)
        ]

        let grouped = ReadingHistory.grouped(entries, base: base)

        XCTAssertEqual(grouped.count, 1)
        XCTAssertEqual(grouped[0].path, "https://www.marxists.org/portugues/marx/1848/ManifestoDoPartidoComunista/capitulo-2.htm")
        XCTAssertEqual(grouped[0].progress, 0.72, accuracy: 0.0001)
        XCTAssertEqual(grouped[0].title, "Manifesto do Partido Comunista")
        XCTAssertEqual(grouped[0].author, "Karl Marx")
    }

    func testMigrationDoesNotMergeUnrelatedDirectoriesOrMissingWorks() {
        let json = """
        [
          {"path":"https://example.com/one","title":"One","author":"","progress":0.1},
          {"path":"https://example.com/two","title":"Two","author":"","progress":0.2}
        ]
        """

        let history = ReadingHistory.history(fromJSON: json, base: base)
        XCTAssertEqual(history.count, 2)
        XCTAssertEqual(history.map(\.title), ["One", "Two"])
    }

    func testNewWorkIDSurvivesEncodingAndDecoding() throws {
        let entry = ReadingProgress(path: manifesto, title: "Manifesto do Partido Comunista", author: "Karl Marx", progress: 0.25, workID: key(manifesto))
        let data = try JSONEncoder().encode([entry])
        let decoded = try JSONDecoder().decode([ReadingProgress].self, from: data)

        XCTAssertEqual(decoded, [entry])
        XCTAssertEqual(decoded[0].workID, key(manifesto))
    }

    func testPortugueseManifestoGroupsPrefaceLinksAndKeepsCredit() throws {
        let catalog = try portugueseCatalog()
        let known = catalog.workKeys(base: base)
        let author = try XCTUnwrap(catalog.credit(forPath: manifesto))
        XCTAssertEqual(author, "Karl Marx e Friedrich Engels")

        let work = ReadingWork(path: manifesto, title: "Manifesto do Partido Comunista", author: author, base: base, knownWorkPaths: known)

        // The real index links all prefaces from prefacios.htm using fragments.
        let preface = try XCTUnwrap(URL(string: "https://www.marxists.org/portugues/marx/1848/ManifestoDoPartidoComunista/prefacios.htm#ea1872"))
        let resumed = try XCTUnwrap(work.destination(for: preface, base: base))
        XCTAssertEqual(resumed.id, key(manifesto))
        XCTAssertEqual(resumed.title, "Manifesto do Partido Comunista")
        XCTAssertEqual(resumed.author, author)

        let chapter = try XCTUnwrap(URL(string: "https://www.marxists.org/portugues/marx/1848/ManifestoDoPartidoComunista/cap1.htm"))
        XCTAssertEqual(work.destination(for: chapter, base: base), work)

        // The Galician edition is a separate catalogue work in another folder.
        let galician = try XCTUnwrap(URL(string: "https://www.marxists.org/portugues/marx/1848/ManifestoDoPartidoComunistaEmGalego/index.htm"))
        XCTAssertNil(work.destination(for: galician, base: base))

        // Legacy entries for the preface page and the index must collapse into
        // one resume point that keeps the work title and credit.
        let entries = [
            ReadingProgress(path: preface.absoluteString, title: "Prefácio à edição alemã de 1872", author: "", progress: 0.4),
            ReadingProgress(path: manifesto, title: "Manifesto do Partido Comunista", author: author, progress: 0.2),
            ReadingProgress(path: galician.absoluteString, title: "Manifesto do Partido Comunista", author: author, progress: 0.1)
        ]
        let history = ReadingHistory.history(fromJSON: String(data: try JSONEncoder().encode(entries), encoding: .utf8)!, base: base, knownWorkPaths: known)
        XCTAssertEqual(history.count, 2)
        XCTAssertEqual(history[0].path, preface.absoluteString)
        XCTAssertEqual(history[0].title, "Manifesto do Partido Comunista")
        XCTAssertEqual(history[0].author, author)
        XCTAssertEqual(history[1].path, galician.absoluteString)
    }

    func testDirectoryStyleIndexStillGroupsItsChapters() throws {
        let indexPath = "https://www.marxists.org/portugues/marx/1848/ManifestoDoPartidoComunista/"
        let prefacePath = "https://www.marxists.org/portugues/marx/1848/ManifestoDoPartidoComunista/prefacios.htm#ea1872"
        let work = ReadingWork(path: indexPath, title: "Manifesto do Partido Comunista", author: "Karl Marx", base: base)

        let preface = try XCTUnwrap(URL(string: prefacePath))
        XCTAssertEqual(work.destination(for: preface, base: base), work)

        let entries = [
            ReadingProgress(path: prefacePath, title: "Prefácio", author: "", progress: 0.6),
            ReadingProgress(path: indexPath, title: "Manifesto do Partido Comunista", author: "Karl Marx", progress: 0.2)
        ]
        let migrated = ReadingHistory.migrated(entries, base: base, knownWorkPaths: [key(indexPath)])
        XCTAssertEqual(migrated.compactMap(\.workID), [key(indexPath), key(indexPath)])

        let grouped = ReadingHistory.grouped(migrated, base: base)
        XCTAssertEqual(grouped.count, 1)
        XCTAssertEqual(grouped[0].path, prefacePath)
        XCTAssertEqual(grouped[0].title, "Manifesto do Partido Comunista")
        XCTAssertEqual(grouped[0].author, "Karl Marx")
    }

    func testLegacyPrefaceJoinsAnIndexThatAlreadyCarriesANewWorkID() {
        // The index was rewritten in the new format, so its directory-style
        // path already points at the canonical index page through `workID`.
        // A preface stored only by the old format must join that identity
        // instead of starting a second work in the same directory.
        let workID = key(manifesto)
        let indexPath = "https://www.marxists.org/portugues/marx/1848/ManifestoDoPartidoComunista/"
        let prefacePath = "https://www.marxists.org/portugues/marx/1848/ManifestoDoPartidoComunista/prefacios.htm#ea1872"

        let entries = [
            ReadingProgress(path: prefacePath, title: "Prefácio à edição alemã de 1872", author: "", progress: 0.6),
            ReadingProgress(path: indexPath, title: "Manifesto do Partido Comunista", author: "Karl Marx", progress: 0.2, workID: workID)
        ]

        let migrated = ReadingHistory.migrated(entries, base: base, knownWorkPaths: [workID])

        XCTAssertEqual(migrated.count, 2, "Migration must not discard entries.")
        XCTAssertEqual(migrated[0].workID, workID, "The legacy preface must adopt the index's new work identity.")
        XCTAssertEqual(migrated[1].workID, workID, "The index keeps its own new work identity.")

        let grouped = ReadingHistory.grouped(migrated, base: base)

        XCTAssertEqual(grouped.count, 1, "Index and preface are one work, not two.")
        XCTAssertEqual(grouped[0].workID, workID)
        XCTAssertEqual(grouped[0].path, prefacePath)
        XCTAssertEqual(grouped[0].progress, 0.6, accuracy: 0.0001)
        XCTAssertEqual(grouped[0].author, "Karl Marx")
    }

    func testLegacyArchiveURLsNormalizeSchemeAndFragments() {
        let legacy = "http://marxists.org/portugues/marx/1848/ManifestoDoPartidoComunista/prefacios.htm#ea1872"
        XCTAssertEqual(ReadingHistory.canonicalKey(for: legacy, base: base), key("marx/1848/ManifestoDoPartidoComunista/prefacios.htm"))
    }

    private func portugueseCatalog() throws -> Catalog {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let data = try Data(contentsOf: root.appendingPathComponent("Praxis/Resources/catalog-pt.json"))
        return try Catalog.decode(data, language: .pt)
    }
}
