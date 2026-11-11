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
        "The catalog could not be opened.": "No se pudo abrir el catálogo.", "Praxis": "Praxis",
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
        "Support this app": "Apoya esta app", "Choose how to support": "Elige cómo apoyar",
        "Help keep the reader free and improving.": "Ayuda a mantener gratis y mejorar el lector.",
        "Support on Ko-fi": "Apoyar en Ko-fi", "Ko-fi profile link pending": "Enlace del perfil de Ko-fi pendiente",
        "Support Marxists.org": "Apoya Marxists.org", "Help preserve the Marxists Internet Archive.": "Ayuda a preservar el Archivo Marxists Internet.",
        "Donate to Marxists.org": "Donar a Marxists.org", "Volunteer with the archive": "Colabora como voluntario del archivo",
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

struct PrivacyPolicyCopy {
    let title: String
    let intro: String
    let onDeviceTitle: String
    let onDeviceBody: String
    let archiveTitle: String
    let archiveBody: String
    let analyticsTitle: String
    let analyticsBody: String
    let analyticsUnavailable: String
    let analyticsConsentTitle: String
    let analyticsConsentDetail: String
    let analyticsPolicyLink: String
    let thirdPartyTitle: String
    let thirdPartyBody: String
    let retentionTitle: String
    let retentionBody: String
    let contactTitle: String
    let contactBody: String
    let contactEmail: String

    static func forLanguage(_ language: Language) -> PrivacyPolicyCopy {
        switch language {
        case .pt:
            PrivacyPolicyCopy(
                title: "Privacidade",
                intro: "O Praxis não exige uma conta. Não vendemos dados nem usamos anúncios. Seus dados de leitura ficam no aparelho, salvo quando você autoriza o envio opcional de análises descrito abaixo.",
                onDeviceTitle: "No seu aparelho",
                onDeviceBody: "Favoritos, histórico, posição de leitura, idioma, ordenação e aparência são guardados no armazenamento do app para manter sua biblioteca como você deixou. Textos e PDFs abertos também podem ficar no cache local, limitado a 100 MB. Esses dados não são enviados à equipe do app.",
                archiveTitle: "Conteúdo do arquivo",
                archiveBody: "Ao abrir um texto ou PDF, ou ao carregar um retrato, o app solicita esse conteúdo diretamente a marxists.org. O servidor do arquivo pode ver qual página ou arquivo foi solicitado e recebe dados técnicos da conexão, como seu endereço IP. O app não controla as práticas de privacidade do arquivo.",
                analyticsTitle: "Análises opcionais",
                analyticsBody: "Quando ativas e autorizadas, as análises enviam eventos gerais ao TelemetryDeck: filtros escolhidos, uso da busca, abertura de autores e textos, favoritos, controles de leitura e toques em links de apoio. A busca é registrada sem o termo digitado. Não enviamos títulos, nomes de autores, caminhos do arquivo ou posição de leitura. O SDK também envia um identificador pseudônimo desta instalação, ID da sessão, data e hora e dados do app e aparelho, como versão, versão do iOS, modelo do aparelho, idioma, região e fuso horário. O TelemetryDeck informa que não armazena endereços IP. Esses dados são usados para entender o uso do app, não para publicidade ou rastreamento entre apps.",
                analyticsUnavailable: "As análises ainda não estão ativas nesta versão. Nenhum dado de uso está sendo enviado.",
                analyticsConsentTitle: "Compartilhar dados de uso",
                analyticsConsentDetail: "Opcional e desativado por padrão. Você pode mudar esta escolha a qualquer momento.",
                analyticsPolicyLink: "Política de privacidade do TelemetryDeck",
                thirdPartyTitle: "Serviços externos",
                thirdPartyBody: "Links de apoio podem abrir sites como Ko-fi ou Marxists.org. Ao sair do app, valem as políticas desses serviços. O TelemetryDeck recebe análises somente quando você ativa a opção acima.",
                retentionTitle: "Armazenamento e remoção",
                retentionBody: "As preferências e o histórico ficam no armazenamento local do app até você apagar o app. O cache apaga arquivos antigos quando passa de 100 MB. Desative as análises acima para interromper o envio de novos eventos. Eventos já recebidos pelo TelemetryDeck seguem a retenção do plano; no plano gratuito atual, são três meses. O serviço permite excluir dados por mês, mas não localizar e excluir os dados de uma instalação específica. Consulte a política do serviço para detalhes.",
                contactTitle: "Contato",
                contactBody: "Para dúvidas ou solicitações sobre privacidade, escreva para:",
                contactEmail: "guifrancoabreu@gmail.com"
            )
        case .en:
            PrivacyPolicyCopy(
                title: "Privacy",
                intro: "Praxis does not require an account. We do not sell data or use ads. Reading data stays on your device unless you choose to share the optional analytics described below.",
                onDeviceTitle: "On your device",
                onDeviceBody: "Saved works, reading history, reading position, language, sorting, and reader appearance are stored in the app so your library stays as you left it. Opened texts and PDFs may also be kept in a local cache capped at 100 MB. This data is not sent to the app team.",
                archiveTitle: "Archive content",
                archiveBody: "When you open a text or PDF, or when a portrait loads, the app requests that content directly from marxists.org. The archive’s server can see which page or file was requested and receives connection details such as your IP address. The app does not control the archive’s privacy practices.",
                analyticsTitle: "Optional analytics",
                analyticsBody: "When enabled and authorized, analytics send general events to TelemetryDeck: selected filters, search use, author and work openings, bookmarks, reader controls, and support-link taps. Search is recorded without the query. We do not send titles, author names, archive paths, or reading positions. The SDK also sends a pseudonymous identifier for this installation, a session ID, date and time, and app and device details such as app version, iOS version, device model, language, region, and time zone. TelemetryDeck says it does not store IP addresses. This data helps us understand app usage; it is not used for advertising or cross-app tracking.",
                analyticsUnavailable: "Analytics are not active in this version yet. No usage data is being sent.",
                analyticsConsentTitle: "Share app usage data",
                analyticsConsentDetail: "Optional and off by default. You can change this choice at any time.",
                analyticsPolicyLink: "TelemetryDeck privacy policy",
                thirdPartyTitle: "External services",
                thirdPartyBody: "Support links may open sites such as Ko-fi or Marxists.org. Their policies apply after you leave the app. TelemetryDeck receives analytics only when you turn on the option above.",
                retentionTitle: "Storage and deletion",
                retentionBody: "Preferences and reading history stay in the app’s local storage until you delete the app. The cache removes older files when it exceeds 100 MB. Turn off analytics above to stop new events from being sent. Events received by TelemetryDeck follow your plan’s retention period; the current free plan keeps them for three months. The service lets customers delete data by month, but it cannot locate and delete data from one specific installation. See its policy for details.",
                contactTitle: "Contact",
                contactBody: "For privacy questions or requests, email:",
                contactEmail: "guifrancoabreu@gmail.com"
            )
        case .es:
            PrivacyPolicyCopy(
                title: "Privacidad",
                intro: "Praxis no requiere una cuenta. No vendemos datos ni usamos anuncios. Los datos de lectura permanecen en tu dispositivo, salvo que aceptes compartir las analíticas opcionales descritas abajo.",
                onDeviceTitle: "En tu dispositivo",
                onDeviceBody: "Los textos guardados, el historial, la posición de lectura, el idioma, el orden y la apariencia del lector se guardan en la app para conservar tu biblioteca. Los textos y PDF abiertos también pueden permanecer en una caché local limitada a 100 MB. Estos datos no se envían al equipo de la app.",
                archiveTitle: "Contenido del archivo",
                archiveBody: "Al abrir un texto o PDF, o al cargar un retrato, la app solicita ese contenido directamente a marxists.org. El servidor del archivo puede ver qué página o archivo se solicitó y recibe datos técnicos de conexión, como tu dirección IP. La app no controla las prácticas de privacidad del archivo.",
                analyticsTitle: "Analíticas opcionales",
                analyticsBody: "Cuando están activas y las aceptas, las analíticas envían eventos generales a TelemetryDeck: filtros elegidos, uso de búsqueda, apertura de autores y textos, marcadores, controles de lectura y toques en enlaces de apoyo. La búsqueda se registra sin el texto consultado. No enviamos títulos, nombres de autores, rutas del archivo ni posiciones de lectura. El SDK también envía un identificador seudónimo de esta instalación, un ID de sesión, fecha y hora, y datos de la app y el dispositivo, como versiones, modelo, idioma, región y zona horaria. TelemetryDeck indica que no almacena direcciones IP. Estos datos ayudan a entender el uso de la app; no se usan para publicidad ni seguimiento entre apps.",
                analyticsUnavailable: "Las analíticas aún no están activas en esta versión. No se envían datos de uso.",
                analyticsConsentTitle: "Compartir datos de uso",
                analyticsConsentDetail: "Opcional y desactivado por defecto. Puedes cambiar esta elección cuando quieras.",
                analyticsPolicyLink: "Política de privacidad de TelemetryDeck",
                thirdPartyTitle: "Servicios externos",
                thirdPartyBody: "Los enlaces de apoyo pueden abrir sitios como Ko-fi o Marxists.org. Al salir de la app, se aplican las políticas de esos servicios. TelemetryDeck recibe analíticas solo si activas la opción anterior.",
                retentionTitle: "Almacenamiento y eliminación",
                retentionBody: "Las preferencias y el historial permanecen en el almacenamiento local de la app hasta que borres la app. La caché elimina archivos antiguos al superar 100 MB. Desactiva las analíticas arriba para detener el envío de nuevos eventos. Los eventos recibidos por TelemetryDeck siguen la retención de tu plan; el plan gratuito actual los conserva durante tres meses. El servicio permite borrar datos por mes, pero no localizar y borrar los datos de una instalación específica. Consulta su política para más detalles.",
                contactTitle: "Contacto",
                contactBody: "Para consultas o solicitudes sobre privacidad, escribe a:",
                contactEmail: "guifrancoabreu@gmail.com"
            )
        }
    }
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

