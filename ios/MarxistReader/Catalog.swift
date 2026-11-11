import Foundation

enum Language: String, CaseIterable, Identifiable {
    case pt, en, es
    var id: String { rawValue }
    var label: String { switch self { case .pt: return "Português"; case .en: return "English"; case .es: return "Español" } }
    var base: String { switch self { case .pt: return "https://www.marxists.org/portugues/"; case .en: return "https://www.marxists.org/"; case .es: return "https://www.marxists.org/espanol/" } }
    func text(_ key: CopyKey) -> String {
        let translation = key.translations
        switch self { case .pt: return translation.pt; case .en: return translation.en; case .es: return translation.es }
    }

    func workCount(_ count: Int) -> String {
        let number = count.formatted(.number.locale(Locale(identifier: rawValue)))
        switch self {
        case .pt: return "\(number) \(count == 1 ? "texto" : "textos")"
        case .en: return "\(number) \(count == 1 ? "work" : "works")"
        case .es: return "\(number) \(count == 1 ? "obra" : "obras")"
        }
    }
}

enum CopyKey: CaseIterable {
    case language, writers, works, noResults, catalogUpdated, search, catalogUnavailable, catalogError
    case appName, pdfDescription, openPDF, loadError, connectionError, retry, loading, openSource

    var translations: (pt: String, en: String, es: String) {
        switch self {
        case .language: return ("Idioma", "Language", "Idioma")
        case .writers: return ("Autores", "Writers", "Autores")
        case .works: return ("Obras", "Works", "Obras")
        case .noResults: return ("Nenhum resultado encontrado.", "No results found.", "No se encontraron resultados.")
        case .catalogUpdated: return ("Catálogo atualizado em", "Catalog updated", "Catálogo actualizado el")
        case .search: return ("Buscar autores e textos", "Search writers and works", "Buscar autores y obras")
        case .catalogUnavailable: return ("Catálogo indisponível", "Catalog unavailable", "Catálogo no disponible")
        case .catalogError: return ("Não foi possível abrir o catálogo.", "The catalog could not be opened.", "No se pudo abrir el catálogo.")
        case .appName: return ("Leitor Marxista", "Marxist Reader", "Lector Marxista")
        case .pdfDescription: return ("Este texto está em PDF.", "This work is a PDF.", "Esta obra está en PDF.")
        case .openPDF: return ("Abrir PDF", "Open PDF", "Abrir PDF")
        case .loadError: return ("Não foi possível carregar", "Could not load the work", "No se pudo cargar la obra")
        case .connectionError: return ("Verifique sua conexão e tente novamente.", "Check your connection and try again.", "Comprueba tu conexión e inténtalo de nuevo.")
        case .retry: return ("Tentar novamente", "Try again", "Intentar de nuevo")
        case .loading: return ("Carregando…", "Loading…", "Cargando…")
        case .openSource: return ("Abrir fonte", "Open source", "Abrir fuente")
        }
    }

}

struct Work: Identifiable, Hashable {
    let title: String
    let path: String
    let date: String
    let section: Int
    var id: String { path + title }
}

struct Author: Identifiable {
    let id: String
    let name: String
    let full: String
    let dates: String
    let bio: String
    let sections: [String]
    let works: [Work]
}

struct Catalog {
    let authors: [Author]
    let generated: String

    static func load(_ language: Language) throws -> Catalog {
        guard let url = Bundle.main.url(forResource: "catalog-\(language.rawValue)", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try decode(Data(contentsOf: url))
    }

    static func decode(_ data: Data) throws -> Catalog {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rows = root["authors"] as? [[String: Any]] else { throw CocoaError(.fileReadCorruptFile) }
        let authors = rows.compactMap { row -> Author? in
            guard let id = row["id"] as? String, let name = row["name"] as? String else { return nil }
            let works = (row["works"] as? [[Any]] ?? []).compactMap { values -> Work? in
                guard values.count >= 2, let title = values[0] as? String, let path = values[1] as? String else { return nil }
                return Work(title: title, path: path, date: values.count > 2 ? values[2] as? String ?? "" : "", section: values.count > 3 ? values[3] as? Int ?? 0 : 0)
            }
            return Author(id: id, name: name, full: row["full"] as? String ?? name,
                          dates: row["dates"] as? String ?? row["years"] as? String ?? "",
                          bio: row["bio"] as? String ?? "", sections: row["sections"] as? [String] ?? [], works: works)
        }
        return Catalog(authors: authors, generated: root["generated"] as? String ?? "")
    }
}

