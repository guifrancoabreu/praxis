import Foundation

enum Language: String, CaseIterable, Identifiable {
    case pt, en, es
    var id: String { rawValue }
    var label: String { switch self { case .pt: return "Português"; case .en: return "English"; case .es: return "Español" } }
    var base: String { switch self { case .pt: return "https://www.marxists.org/portugues/"; case .en: return "https://www.marxists.org/"; case .es: return "https://www.marxists.org/espanol/" } }
    func text(_ pt: String, _ en: String) -> String {
        if self == .pt { return pt }
        if self == .en { return en }
        return Self.spanish[en] ?? en
    }
    func workCount(_ count: Int) -> String {
        self == .es ? "\(count) obras" : text("\(count) textos", "\(count) works")
    }
    func readingProgress(_ percent: Int) -> String {
        if self == .pt { return "\(percent)% lido" }
        if self == .es { return "\(percent)% leído" }
        return "\(percent)% read"
    }
    private static let spanish: [String: String] = [
        "Language": "Idioma", "Writers": "Autores", "works": "obras", "Works": "Obras",
        "No results found.": "No se encontraron resultados.", "No results found": "No se encontraron resultados.", "Catalog updated": "Catálogo actualizado el",
        "Search writers and works": "Buscar autores y obras", "Catalog unavailable": "Catálogo no disponible",
        "The catalog could not be opened.": "No se pudo abrir el catálogo.", "Marxist Reader": "Lector Marxista",
        "This work is a PDF.": "Esta obra está en PDF.", "Open PDF": "Abrir PDF",
        "Could not load the work": "No se pudo cargar la obra", "Check your connection and try again.": "Comprueba tu conexión e inténtalo de nuevo.",
        "Try again": "Intentar de nuevo", "Loading…": "Cargando…", "Open source": "Abrir fuente",
        "Popular writers": "Autores populares", "Editorial selection": "Selección editorial",
        "Explore": "Explorar", "Subjects": "Temas", "History": "Historia", "Reading log": "Historial de lectura", "People": "Personas", "Countries": "Países", "Support": "Apoyar",
        "A–Z": "A–Z", "Movements": "Movimientos", "Other": "Otros", "Subjects and history": "Temas e historia",
        "Popularity": "Popularidad", "Z–A": "Z–A", "Date": "Fecha", "Sort": "Ordenar",
        "Try another search.": "Prueba otra búsqueda.", "Search for a person.": "Busca una persona.",
        "Try another term.": "Prueba otro término.", "Glossary of people": "Glosario de personas", "People only": "Solo personas",
        "No reading history yet": "Aún no hay historial de lectura", "Works you open will appear here.": "Los textos que abras aparecerán aquí.",
        "No countries found": "No se encontraron países", "Country data is available in the Portuguese catalog.": "Los datos de países están disponibles en el catálogo en portugués.",
        "Recently read": "Leído recientemente", "Full history": "Historial completo", "Reading history": "Historial de lectura",
        "Read more": "Leer más", "Read less": "Leer menos", "Full biography": "Biografía completa", "Biography": "Biografía",
        "Open in archive": "Abrir en el archivo", "Support the archive": "Apoya el archivo",
        "From the library": "De la biblioteca", "Estimated editorial ranking": "Clasificación editorial estimada", "Popular texts": "Textos populares", "Popular": "Popular",
        "The Marxists Internet Archive is maintained by volunteers. Your support helps preserve and share this collection.": "El Archivo Marxists Internet está mantenido por voluntarios. Tu apoyo ayuda a preservar y compartir esta colección.",
        "Code copied": "Código copiado", "Copy Pix code": "Copiar código Pix",
        "In a Brazilian banking app, choose Pix → Copy and Paste and paste the code.": "En una app bancaria brasileña, elige Pix → Copiar y pegar y pega el código.",
        "Other ways to help": "Otras formas de ayudar", "Text": "Texto", "Font": "Fuente", "Serif": "Serif", "Sans serif": "Sin serifas", "Book": "Libro", "Condensed": "Condensada", "Monospaced": "Monoespaciada", "Casual": "Informal",
        "Size": "Tamaño", "Line spacing": "Interlineado", "Margins": "Márgenes", "Alignment": "Alineación", "Left": "Izquierda", "Justified": "Justificado",
        "Colours": "Colores", "Theme": "Tema", "Light": "Claro", "Sepia": "Sepia", "Gray": "Gris", "Dark": "Oscuro", "Black": "Negro", "Red": "Rojo", "Custom": "Personalizado", "Customize colours": "Personalizar colores", "Background": "Fondo", "Links": "Enlaces", "Restore defaults": "Restaurar valores predeterminados",
        "Text appearance": "Apariencia del texto",
        "From the archive": "Del archivo", "Saved works": "Textos guardados", "All works": "Todos los textos",
        "Your library starts here": "Tu biblioteca empieza aquí", "Save works to find them quickly later.": "Guarda textos para encontrarlos fácilmente después.",
        "Try another writer or title.": "Prueba con otro autor o título.", "Clear search": "Borrar búsqueda", "Continue reading": "Seguir leyendo",
        "CURRENTLY READING": "LEYENDO", "A good place to start": "Un buen texto para empezar", "FROM THE ARCHIVE": "DEL ARCHIVO",
        "Start reading": "Empezar a leer", "See all": "Ver todos", "All": "Todo", "Saved": "Guardados",
        "Decrease text size": "Reducir tamaño del texto", "Increase text size": "Aumentar tamaño del texto", "Reset text size": "Restablecer tamaño",
        "Remove from saved": "Quitar de guardados", "Save work": "Guardar texto"
    ]
}

enum CatalogSort: String, CaseIterable, Identifiable {
    case popularity, az, za, date
    var id: String { rawValue }
    func title(_ language: Language) -> String {
        switch self {
        case .popularity: language.text("Popularidade", "Popularity")
        case .az: "A–Z"
        case .za: "Z–A"
        case .date: language.text("Data", "Date")
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

struct CatalogItem: Identifiable, Hashable {
    let title: String
    let path: String
    var person = false
    var id: String { path + title }
    var work: Work { Work(title: title, path: path, date: "", section: 0) }
}

struct CatalogGroup: Identifiable {
    let name: String
    let items: [CatalogItem]
    var id: String { name }
}

struct CatalogCollection: Identifiable {
    let id: String
    let title: String
    let group: String
    let groups: [CatalogGroup]
}

struct Author: Identifiable {
    let id: String
    let name: String
    let full: String
    let dates: String
    let avatar: String?
    let bio: String
    let sections: [String]
    let works: [Work]
    let country: String
    let groups: [String]
    let photo: String?
    let bioPath: String?
}

struct Catalog {
    let authors: [Author]
    let generated: String
    let themes: [CatalogCollection]
    let history: [CatalogCollection]
    let figures: [CatalogItem]

    static func load(_ language: Language) throws -> Catalog {
        guard let url = Bundle.main.url(forResource: "catalog-\(language.rawValue)", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try decode(Data(contentsOf: url), language: language)
    }

    static func decode(_ data: Data, language: Language = .pt) throws -> Catalog {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rows = root["authors"] as? [[String: Any]] else { throw CocoaError(.fileReadCorruptFile) }
        let parsedAuthors = rows.compactMap { row -> Author? in
            guard let id = row["id"] as? String, let name = row["name"] as? String else { return nil }
            let works = (row["works"] as? [[Any]] ?? []).compactMap { values -> Work? in
                guard values.count >= 2, let title = values[0] as? String, let path = values[1] as? String else { return nil }
                return Work(title: title, path: path, date: values.count > 2 ? values[2] as? String ?? "" : "", section: values.count > 3 ? values[3] as? Int ?? 0 : 0)
            }
            return Author(id: id, name: name, full: row["full"] as? String ?? name,
                          dates: row["dates"] as? String ?? row["years"] as? String ?? "",
                          avatar: row["avatar"] as? String ?? row["photo"] as? String,
                          bio: row["bio"] as? String ?? "", sections: row["sections"] as? [String] ?? [], works: works,
                          country: row["country"] as? String ?? "", groups: row["groups"] as? [String] ?? [],
                          photo: row["photo"] as? String, bioPath: row["bioPath"] as? String)
        }
        func collections(_ key: String) -> [CatalogCollection] {
            (root[key] as? [[String: Any]] ?? []).map { row in
                let groups = (row["groups"] as? [[String: Any]] ?? []).map { group in
                    let items = (group["works"] as? [[Any]] ?? []).compactMap { values -> CatalogItem? in
                        guard values.count >= 2, let title = values[0] as? String, let path = values[1] as? String else { return nil }
                        return CatalogItem(title: title, path: path)
                    }
                    return CatalogGroup(name: group["name"] as? String ?? "", items: items)
                }
                return CatalogCollection(id: row["id"] as? String ?? row["title"] as? String ?? UUID().uuidString,
                                         title: row["title"] as? String ?? "", group: row["group"] as? String ?? "", groups: groups)
            }
        }
        let figures = (root["figures"] as? [[String: Any]] ?? []).compactMap { row -> CatalogItem? in
            guard let name = row["name"] as? String, let path = row["path"] as? String else { return nil }
            return CatalogItem(title: name, path: path, person: row["person"] as? Bool ?? false)
        }
        let authors = language == .pt ? separateMarxAndEngels(in: parsedAuthors) : parsedAuthors
        return Catalog(authors: authors, generated: root["generated"] as? String ?? "",
                       themes: collections("themes"), history: collections("history"), figures: figures)
    }

    private static func separateMarxAndEngels(in authors: [Author]) -> [Author] {
        guard let index = authors.firstIndex(where: { $0.id == "marx" }),
              authors[index].full.localizedCaseInsensitiveContains("Friedrich Engels") else { return authors }

        let source = authors[index]
        let engelsOnlyTitles = [
            "Princípios Básicos do Comunismo", "Progresso do Comunismo na Alemanha", "A Imprensa e os Déspotas Alemães",
            "Esboço de uma Crítica da Economia Política", "Às classes trabalhadoras da Grã-Bretanha", "As guerras camponesas na Alemanha",
            "Revolução e Contra-Revolução na Alemanha", "Guerra nas Montanhas no Passado e no Presente", "Lições da Guerra Americana",
            "A Guerra Civil americana e os navios encouraçados", "Discurso Sobre a Acção Política da Classe Operária",
            "Para a Questão da Habitação", "Sobre a Autoridade", "Os Bakuninistas em Ação", "Programa dos Refugiados Blanquistas",
            "Sobre o Papel do Trabalho na Transformação do Macaco em Homem", "Introdução à \"Dialéctica da Natureza\"",
            "Anti-Dühring", "Do Socialismo Utópico ao Socialismo Cientifico", "Artigo Publicado no Labour Standard",
            "A Dialética da Natureza", "A Origem da Família, da Propriedade Privada e do Estado",
            "Bruno Bauer e o Início do Cristianismo", "Ludwig Feuerbach e o Fim da Filosofia Alemã Clássica",
            "Contribuição Para a História do Cristianismo Primitivo", "A Condição da Classe Operária em Inglaterra"
        ]
        let coauthoredTitles = [
            "Feuerbach. Oposição das Concepções", "Manifesto do Partido Comunista", "Mensagem da Direcção Central à Liga dos Comunistas",
            "Revolução do século XVII na Inglaterra", "Reunião da Direção Central da Liga dos Comunistas",
            "Declaração ao Editor do Neue Deutsche Zeitung", "Declaração Pública aos Editores da Imprensa Inglesa",
            "As Pretensas Cisões na Internacional", "Das Resoluções do Congresso Geral Realizado na Haia",
            "Carta Circular a A. Bebel, W. Liebknecht"
        ]
        func matches(_ work: Work, _ titles: [String]) -> Bool {
            titles.contains { work.title.localizedCaseInsensitiveContains($0) }
        }
        let engelsWorks = source.works.filter { matches($0, engelsOnlyTitles) || matches($0, coauthoredTitles) }
        let marxWorks = source.works.filter { !matches($0, engelsOnlyTitles) || matches($0, coauthoredTitles) }

        let marx = Author(id: source.id, name: "Marx, Karl", full: "Karl Marx", dates: "1818–1883",
                          avatar: nil,
                          bio: "Filósofo, economista e revolucionário alemão, Karl Marx desenvolveu uma crítica da economia política e do capitalismo.",
                          sections: source.sections, works: marxWorks, country: source.country, groups: source.groups,
                          photo: source.photo, bioPath: "dicionario/verbetes/m/marx.htm")
        let engels = Author(id: "engels", name: "Engels, Friedrich", full: "Friedrich Engels", dates: "1820–1895",
                            avatar: source.avatar,
                            bio: source.bio, sections: source.sections, works: engelsWorks, country: source.country,
                            groups: source.groups,
                            photo: "https://www.marxists.org/archive/marx/photo/engels/images/88fe1.jpg",
                            bioPath: "dicionario/verbetes/e/engels.htm")
        var result = authors
        result[index] = marx
        result.insert(engels, at: index + 1)
        return result
    }
}

