import SwiftUI
import WebKit
import CryptoKit
import UIKit
import PDFKit
import Vision
import ImageIO

@main
struct PraxisApp: App {
    init() { Analytics.configure() }

    var body: some Scene { WindowGroup { LibraryView() } }
}

struct LibraryView: View {
    @AppStorage("language") private var languageCode = Language.pt.rawValue
    @AppStorage("savedWorkPaths") private var savedWorkPaths = "[]"
    @AppStorage("recentReadings") private var recentReadings = "[]"
    @State private var query = ""
    @State private var filter: LibraryFilter = .all
    @State private var catalog: Catalog?
    @State private var error = false
    @AppStorage("groupWritersByMovement") private var groupWriters = true
    @AppStorage("catalogSortOrder") private var catalogSortRaw = CatalogSort.popularity.rawValue
    @AppStorage("glossaryPeopleOnly") private var peopleOnly = true
    private var language: Language { Language(rawValue: languageCode) ?? .pt }
    private var catalogSort: CatalogSort { CatalogSort(rawValue: catalogSortRaw) ?? .popularity }
    private var savedPaths: Set<String> { Set((try? JSONDecoder().decode([String].self, from: Data(savedWorkPaths.utf8))) ?? []) }
    private var recentEntries: [ReadingProgress] { (try? JSONDecoder().decode([ReadingProgress].self, from: Data(recentReadings.utf8))) ?? [] }
    private var allWorks: [(Author, Work)] {
        guard let catalog else { return [] }
        var seenPaths = Set<String>()
        return catalog.authors.flatMap { author in
            author.works.filter { seenPaths.insert($0.path).inserted }.map { (author, $0) }
        }
    }
    private var matchingAuthors: [Author] {
        guard let catalog else { return [] }
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return q.isEmpty ? catalog.authors : catalog.authors.filter { ($0.name + " " + $0.full + " " + $0.country + " " + $0.groups.joined(separator: " ")).localizedStandardContains(q) }
    }
    private var popularAuthors: [Author] {
        guard let catalog else { return [] }
        // A hand-curated editorial order based on broad historical recognition,
        // not a measurement of activity in this app.
        let rankedIDs: [String]
        switch language {
        case .pt: rankedIDs = ["marx", "lenin", "engels", "gramsci", "luxemburgo", "trotsky", "guevara", "mao", "castro", "bukharin"]
        case .en: rankedIDs = ["archive/marx", "archive/lenin", "archive/luxemburg", "archive/trotsky", "archive/gramsci", "archive/guevara", "reference/archive/mao", "history/cuba/archive/castro"]
        case .es: rankedIDs = ["m-e/index.htm", "lenin/index.htm", "luxem/index.htm", "trotsky/index.htm", "gramsci/index.htm", "guevara/index.htm", "bujarin/index.htm"]
        }
        return rankedIDs.compactMap { id in catalog.authors.first { $0.id == id } }
    }
    private func sortedAuthors(_ authors: [Author]) -> [Author] {
        switch catalogSort {
        case .popularity:
            let ranks = Dictionary(uniqueKeysWithValues: popularAuthors.enumerated().map { ($0.element.id, $0.offset) })
            return authors.sorted {
                let lhs = ranks[$0.id] ?? Int.max
                let rhs = ranks[$1.id] ?? Int.max
                return lhs == rhs ? $0.full.localizedStandardCompare($1.full) == .orderedAscending : lhs < rhs
            }
        case .az: return authors.sorted { $0.full.localizedStandardCompare($1.full) == .orderedAscending }
        case .za: return authors.sorted { $0.full.localizedStandardCompare($1.full) == .orderedDescending }
        case .date:
            return authors.sorted {
                let lhs = Self.firstYear($0.dates) ?? Int.min
                let rhs = Self.firstYear($1.dates) ?? Int.min
                return lhs == rhs ? $0.full.localizedStandardCompare($1.full) == .orderedAscending : lhs > rhs
            }
        }
    }
    private func sortedWorks(_ works: [(Author, Work)]) -> [(Author, Work)] {
        switch catalogSort {
        case .popularity:
            let ranks = Dictionary(uniqueKeysWithValues: popularWorks.enumerated().map { ($0.element.1.path, $0.offset) })
            return works.sorted {
                let lhs = ranks[$0.1.path] ?? Int.max
                let rhs = ranks[$1.1.path] ?? Int.max
                return lhs == rhs ? $0.1.title.localizedStandardCompare($1.1.title) == .orderedAscending : lhs < rhs
            }
        case .az: return works.sorted { $0.1.title.localizedStandardCompare($1.1.title) == .orderedAscending }
        case .za: return works.sorted { $0.1.title.localizedStandardCompare($1.1.title) == .orderedDescending }
        case .date:
            return works.sorted {
                let lhs = Self.firstYear($0.1.date) ?? Int.min
                let rhs = Self.firstYear($1.1.date) ?? Int.min
                return lhs == rhs ? $0.1.title.localizedStandardCompare($1.1.title) == .orderedAscending : lhs > rhs
            }
        }
    }
    private static func firstYear(_ text: String) -> Int? {
        guard let range = text.range(of: #"\d{3,4}"#, options: .regularExpression) else { return nil }
        return Int(text[range])
    }
    private var matchingWorks: [(Author, Work)] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }
        return Array(allWorks.lazy.filter { $0.1.title.localizedStandardContains(q) }.prefix(100))
    }
    private var matchingTopics: [CatalogCollection] {
        guard let catalog else { return [] }
        return (catalog.themes + catalog.history).filter { $0.title.localizedStandardContains(query) || $0.group.localizedStandardContains(query) }
    }
    private var matchingFigures: [CatalogItem] {
        guard let catalog, !query.isEmpty else { return [] }
        return Array(catalog.figures.lazy.filter { (!peopleOnly || $0.person) && $0.title.localizedStandardContains(query) }.prefix(80))
    }
    private var matchingCountries: [String] {
        Array(Set((catalog?.authors ?? []).map(\.country).filter { !$0.isEmpty && $0.localizedStandardContains(query) })).sorted()
    }
    private var savedWorks: [(Author, Work)] { allWorks.filter { savedPaths.contains($0.1.path) } }
    private var historyWorks: [(Author, Work)] {
        recentEntries.compactMap { entry in
            if let match = allWorks.first(where: { $0.1.path == entry.path }) { return match }
            return (Author(id: entry.path, name: "", full: "", dates: "", avatar: nil, bio: "", sections: [], works: [], country: "", groups: [], photo: nil, bioPath: nil), Work(title: entry.title, path: entry.path, date: "", section: 0, credit: ""))
        }
    }
    private var hasReadingProgress: Bool { recentEntries.contains { $0.progress > 0 } }
    private var popularWorks: [(Author, Work)] {
        guard let catalog else { return [] }
        let preferred = language == .pt ? Self.popularPortugueseTitles : Self.popularEnglishTitles
        // Only use works listed under an author; a URL prefix alone is not
        // evidence of authorship, especially in shared or nested archives.
        let sources = catalog.authors.flatMap { author in author.works.map { (author, $0) } }
        var chosen: [(Author, Work)] = []
        let expectedAuthors = language == .pt ? Self.portugueseWorkAuthors : Self.englishWorkAuthors
        for signature in preferred {
            guard let authorID = expectedAuthors[signature] else { continue }
            if let match = sources.first(where: {
                $0.0.id == authorID && $0.1.title.localizedCaseInsensitiveCompare(signature) == .orderedSame
            }) ?? sources.first(where: {
                $0.0.id == authorID && $0.1.title.lowercased().hasPrefix(signature.lowercased())
            }), !chosen.contains(where: { $0.1.path == match.1.path }) {
                chosen.append(match)
            }
        }
        // The Spanish catalog is a small starter set; fill remaining places from its
        // canonical author pages. This remains a visible editorial estimate.
        let fallbackIDs = language == .pt ? ["marx", "engels", "lenin", "luxemburgo", "trotsky", "mao", "gramsci", "bukharin", "reed"] :
            language == .en ? ["archive/marx", "archive/lenin", "archive/luxemburg", "archive/trotsky", "archive/gramsci", "reference/archive/mao", "archive/bukharin", "archive/reed"] :
            ["m-e/index.htm", "lenin/index.htm", "luxem/index.htm", "trotsky/index.htm", "gramsci/index.htm", "bujarin/index.htm"]
        let fallbackAuthors = fallbackIDs.compactMap { id in catalog.authors.first(where: { $0.id == id }) }
        let fallbackWorks = fallbackAuthors.map { author in sources.filter { $0.0.id == author.id } }
        for offset in 0..<500 where chosen.count < 50 {
            for authorWorks in fallbackWorks where chosen.count < 50 {
                guard offset < authorWorks.count else { continue }
                let candidate = authorWorks[offset]
                if !chosen.contains(where: { $0.1.path == candidate.1.path }) { chosen.append(candidate) }
            }
        }
        return Array(chosen.prefix(50))
    }
    // Match curated works within their author's catalog to avoid selecting commentary
    // or another work that happens to contain the same title.
    private static let portugueseWorkAuthors: [String: String] = [
        "Manifesto do Partido Comunista": "marx", "O Capital - Crítica": "marx",
        "O Estado e a Revolução": "lenin", "O Imperialismo, Fase Superior": "lenin",
        "Reforma ou Revolução": "luxemburgo", "Do Socialismo Utópico": "engels",
        "A Origem da Família": "engels", "Crítica do Programa de Gotha": "marx",
        "Que Fazer?": "lenin", "Trabalho Assalariado e Capital": "marx",
        "A Doença Infantil": "lenin", "O 18 de Brumário": "marx",
        "Guerra Civil na França": "marx", "A Ideologia Alemã": "marx",
        "Valor, Preço e Lucro": "marx", "Miséria da Filosofia": "marx",
        "Manuscritos Econômico-Filosóficos": "marx", "Anti-Dühring": "engels",
        "Greve de massas": "luxemburgo", "A Acumulação do Capital": "luxemburgo",
        "A Revolução Traída": "trotsky", "A Revolução Permanente": "trotsky",
        "Dez Dias que Abalaram o Mundo": "reed", "Teses sobre Feuerbach": "marx",
        "ABC do Comunismo": "bukharin", "Citações do Presidente Mao": "mao",
        "Sobre a Prática": "mao", "Sobre a Contradição": "mao",
        "O Desenvolvimento do Capitalismo na Rússia": "lenin", "A Situação da Classe Trabalhadora": "engels",
        "A Guerra de Guerrilhas": "lenin", "Três Fontes": "lenin", "A Questão Judaica": "marx",
        "A Sagrada Família": "marx", "O Programa de Gotha": "marx", "O Direito à Preguiça": "lafargue",
        "A Revolução Russa": "luxemburgo", "O Materialismo Dialético": "stalin",
        "O Imperialismo e a Economia Mundial": "bukharin", "A Guerra Civil": "marx",
        "O Desenvolvimento do Capitalismo": "lenin", "O Socialismo e as Igrejas": "luxemburgo",
        "O Estado": "lenin", "O Que Fazer": "lenin", "A Mulher e o Socialismo": "bebel",
        "O Trabalho Assalariado": "marx", "A Revolução Proletária": "lenin"
    ]
    private static let englishWorkAuthors: [String: String] = [
        "The Communist Manifesto": "archive/marx", "Capital: A Critique": "archive/marx",
        "The State and Revolution": "archive/lenin", "Imperialism, the Highest Stage": "archive/lenin",
        "Reform or Revolution": "archive/luxemburg", "Socialism: Utopian and Scientific": "archive/marx",
        "Origin of the Family, Private Property": "archive/marx", "Critique of the Gotha Program": "archive/marx",
        "What Is to Be Done?": "archive/lenin", "Wage Labour and Capital": "archive/marx",
        "Left-Wing Communism": "archive/lenin", "The Eighteenth Brumaire": "archive/marx",
        "The Civil War in France": "archive/marx", "The German Ideology": "archive/marx",
        "Value, Price and Profit": "archive/marx", "The Poverty of Philosophy": "archive/marx",
        "Economic and Philosophical Manuscripts": "archive/marx", "Anti-Dühring": "archive/marx",
        "The Mass Strike": "archive/luxemburg", "The Accumulation of Capital": "archive/luxemburg",
        "The Revolution Betrayed": "archive/trotsky", "The Permanent Revolution": "archive/trotsky",
        "Ten Days That Shook the World": "archive/reed", "Theses on Feuerbach": "archive/marx",
        "ABC of Communism": "archive/bukharin", "Quotations from Chairman Mao": "reference/archive/mao",
        "On Practice": "reference/archive/mao", "On Contradiction": "reference/archive/mao",
        "The Development of Capitalism in Russia": "archive/lenin", "The Condition of the Working Class": "archive/marx",
        "The Peasant War in Germany": "archive/marx", "The Jewish Question": "archive/marx",
        "The Holy Family": "archive/marx", "The Right to Be Lazy": "archive/lafargue",
        "The Russian Revolution": "archive/luxemburg", "Dialectical and Historical Materialism": "reference/archive/stalin",
        "Imperialism and the World Economy": "archive/bukharin", "The State": "archive/lenin",
        "The Junius Pamphlet": "archive/luxemburg", "History of the Russian Revolution": "archive/trotsky",
        "Selections from the Prison Notebooks": "archive/gramsci", "The Conquest of Bread": "reference/archive/kropotkin-peter",
        "The Wretched of the Earth": "subject/africa/fanon", "The Origin of the Family": "archive/marx"
    ]
    private static let popularPortugueseTitles = [
        "Manifesto do Partido Comunista", "O Capital - Crítica", "O Estado e a Revolução", "O Imperialismo, Fase Superior",
        "Reforma ou Revolução", "Do Socialismo Utópico", "A Origem da Família", "Crítica do Programa de Gotha", "Que Fazer?",
        "Trabalho Assalariado e Capital", "A Doença Infantil", "O 18 de Brumário", "Guerra Civil na França", "A Ideologia Alemã",
        "Valor, Preço e Lucro", "Miséria da Filosofia", "Manuscritos Econômico-Filosóficos", "Anti-Dühring", "Greve de massas",
        "A Acumulação do Capital", "A Revolução Traída", "A Revolução Permanente", "Dez Dias que Abalaram o Mundo",
        "Teses sobre Feuerbach", "ABC do Comunismo", "Citações do Presidente Mao", "Sobre a Prática", "Sobre a Contradição",
        "O Desenvolvimento do Capitalismo na Rússia", "A Situação da Classe Trabalhadora", "A Guerra de Guerrilhas",
        "Três Fontes", "A Questão Judaica", "A Sagrada Família", "O Programa de Gotha", "O Direito à Preguiça",
        "A Revolução Russa", "O Materialismo Dialético", "O Imperialismo e a Economia Mundial", "A Guerra Civil",
        "O Desenvolvimento do Capitalismo", "O Socialismo e as Igrejas", "O Estado", "A Origem da Família",
        "O Que Fazer", "A Mulher e o Socialismo", "O Trabalho Assalariado", "O Partido", "A Revolução Proletária"
    ]
    private static let popularEnglishTitles = [
        "The Communist Manifesto", "Capital: A Critique", "The State and Revolution", "Imperialism, the Highest Stage",
        "Reform or Revolution", "Socialism: Utopian and Scientific", "Origin of the Family, Private Property",
        "Critique of the Gotha Program", "What Is to Be Done?", "Wage Labour and Capital", "Left-Wing Communism",
        "The Eighteenth Brumaire", "The Civil War in France", "The German Ideology", "Value, Price and Profit",
        "The Poverty of Philosophy", "Economic and Philosophical Manuscripts", "Anti-Dühring", "The Mass Strike",
        "The Accumulation of Capital", "The Revolution Betrayed", "The Permanent Revolution", "Ten Days That Shook the World",
        "Theses on Feuerbach", "ABC of Communism", "Quotations from Chairman Mao", "On Practice", "On Contradiction",
        "The Development of Capitalism in Russia", "The Condition of the Working Class", "The Peasant War in Germany",
        "The Jewish Question", "The Holy Family", "The Right to Be Lazy", "The Russian Revolution",
        "Dialectical and Historical Materialism", "Imperialism and the World Economy", "The State", "The Junius Pamphlet",
        "History of the Russian Revolution", "Selections from the Prison Notebooks", "The Conquest of Bread",
        "The Wretched of the Earth", "The Communist Manifesto", "The German Ideology", "The Mass Strike",
        "The Eighteenth Brumaire", "What Is to Be Done?", "The Origin of the Family", "The Civil War in France"
    ]
    private var featuredPopularWork: (Author, Work)? {
        guard !popularWorks.isEmpty else { return nil }
        let day = Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0
        return popularWorks[(day - 1) % popularWorks.count]
    }
    var body: some View {
        NavigationStack {
            Group {
                if let catalog {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 24) {
                            header
                            filterBar
                            if query.isEmpty && filter == .all {
                                if hasReadingProgress {
                                    continueReadingShelf(recentEntries)
                                } else if let featuredPopularWork {
                                    startHere(featuredPopularWork)
                                }
                                if !popularAuthors.isEmpty { writerShelf(popularAuthors, title: language.text("Autores populares", "Popular writers")) }
                                if !savedWorks.isEmpty { savedPreview }
                                popularWorkList(Array(popularWorks.prefix(8)), title: language.text("Da biblioteca", "From the library"), showAll: true)
                            } else if !query.isEmpty {
                                switch filter {
                                case .all:
                                    if !matchingAuthors.isEmpty { writerList(matchingAuthors) }
                                    if !matchingWorks.isEmpty { workList(matchingWorks, title: language.text("Textos", "Works")) }
                                    if !matchingTopics.isEmpty { collectionList(matchingTopics, title: language.text("Temas e história", "Subjects and history")) }
                                    if !matchingFigures.isEmpty { figureList(matchingFigures) }
                                    if !matchingCountries.isEmpty { countryList(matchingCountries) }
                                    if matchingAuthors.isEmpty && matchingWorks.isEmpty && matchingTopics.isEmpty && matchingFigures.isEmpty && matchingCountries.isEmpty {
                                        emptyState(title: language.text("Nada encontrado", "No results found"), detail: language.text("Tente outro autor ou título.", "Try another writer or title."))
                                    }
                                case .writers: writerList(matchingAuthors)
                                case .works: workList(matchingWorks, title: language.text("Textos", "Works"))
                                case .saved: workList(savedWorks.filter { $0.1.title.localizedStandardContains(query) || $0.0.full.localizedStandardContains(query) }, title: language.text("Salvos", "Saved works"))
                                case .readingHistory: workList(historyWorks.filter { $0.1.title.localizedStandardContains(query) || $0.0.full.localizedStandardContains(query) }, title: language.text("Histórico de leitura", "Reading history"))
                                case .topics: collectionList(catalog.themes.filter { $0.title.localizedStandardContains(query) }, title: language.text("Temas", "Subjects"))
                                case .history: collectionList(catalog.history.filter { $0.title.localizedStandardContains(query) }, title: language.text("História", "History"))
                                case .figures: figureList(matchingFigures)
                                case .countries: countryList(matchingCountries)
                                case .popular: popularWorkList(popularWorks.filter { $0.1.title.localizedStandardContains(query) || $0.0.full.localizedStandardContains(query) }, title: language.text("Textos populares", "Popular texts"))
                                }
                            } else {
                                switch filter {
                                case .all: EmptyView()
                                case .saved:
                                    if savedWorks.isEmpty {
                                        emptyState(title: language.text("Sua biblioteca começa aqui", "Your library starts here"), detail: language.text("Salve textos para encontrá-los rapidamente depois.", "Save works to find them quickly later."))
                                    } else { workList(savedWorks, title: language.text("Salvos", "Saved works")) }
                                case .writers: writerList(matchingAuthors)
                                case .works: workList(Array(sortedWorks(allWorks).prefix(60)), title: language.text("Todos os textos", "All works"))
                                case .readingHistory:
                                    if historyWorks.isEmpty { emptyState(title: language.text("Histórico vazio", "No reading history yet"), detail: language.text("Os textos que você abrir aparecem aqui.", "Works you open will appear here.")) }
                                    else { workList(historyWorks, title: language.text("Histórico de leitura", "Reading log")) }
                                case .topics: collectionList(catalog.themes, title: language.text("Temas", "Subjects"))
                                case .history: collectionList(catalog.history, title: language.text("História", "History"))
                                case .figures: figureList(catalog.figures.filter { !peopleOnly || $0.person })
                                case .countries: countryList(Array(Set(catalog.authors.map(\.country).filter { !$0.isEmpty })).sorted())
                                case .popular: popularWorkList(popularWorks, title: language.text("Textos populares", "Popular texts"))
                                }
                            }
                            Text(language.text("Catálogo atualizado em", "Catalog updated") + " " + catalog.generated + " · Marxists Internet Archive")
                                .font(.footnote).foregroundStyle(DesignTokens.muted).frame(maxWidth: .infinity, alignment: .center).padding(.vertical, 12)
                            if query.isEmpty && filter == .all {
                                supportFooter
                                privacyFooter
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 14)
                        .padding(.bottom, 28)
                    }
                    .id(filter)
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        searchField
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            .padding(.bottom, 8)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .background(DesignTokens.paper.ignoresSafeArea())
                } else if error {
                    ContentUnavailableView(language.text("Catálogo indisponível", "Catalog unavailable"), systemImage: "books.vertical", description: Text(language.text("Não foi possível abrir o catálogo.", "The catalog could not be opened.")))
                } else { ProgressView().tint(DesignTokens.accent) }
            }
            .toolbar(.hidden, for: .navigationBar)
            .tint(DesignTokens.accent)
            .background(DesignTokens.paper.ignoresSafeArea())
            .task(id: languageCode) {
                query = ""
                do { catalog = try Catalog.load(language); error = false } catch { catalog = nil; self.error = true }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text(language.text("Biblioteca", "Library"))
                    .font(.system(.largeTitle, design: .serif, weight: .medium)).tracking(-0.5)
                Text(language.text("Arquivo Marxista na Internet", "Marxists Internet Archive"))
                    .font(.subheadline).foregroundStyle(DesignTokens.muted)
            }
            Spacer()
            Menu {
                Picker(language.text("Idioma", "Language"), selection: $languageCode) {
                    ForEach(Language.allCases) { Text($0.label).tag($0.rawValue) }
                }
            } label: {
                Image(systemName: "globe").font(.system(size: 17, weight: .medium))
                    .foregroundStyle(DesignTokens.ink).frame(width: 44, height: 44)
                    .background(DesignTokens.surface, in: Circle())
            }
            .accessibilityLabel(language.text("Idioma", "Language"))
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(primaryFilters) { item in
                    Button {
                        Analytics.track(.filterSelected(item))
                        withAnimation(.easeOut(duration: 0.18)) { filter = item }
                    } label: {
                        Text(item.title(language)).font(.subheadline.weight(.medium))
                            .padding(.horizontal, 15).frame(minHeight: 44)
                            .background(filter == item ? DesignTokens.ink : DesignTokens.filterSurface, in: Capsule())
                            .foregroundStyle(filter == item ? DesignTokens.paper : DesignTokens.ink)
                    }.buttonStyle(.plain)
                        .accessibilityAddTraits(filter == item ? .isSelected : [])
                }
            }
        }.contentMargins(.trailing, 2)
    }

    private var primaryFilters: [LibraryFilter] {
        guard let catalog else { return [.all, .saved, .writers, .works, .readingHistory] }
        var result: [LibraryFilter] = [.all, .saved, .writers, .works, .readingHistory]
        if !catalog.themes.isEmpty { result.append(.topics) }
        if !catalog.history.isEmpty { result.append(.history) }
        if !catalog.figures.isEmpty { result.append(.figures) }
        if catalog.authors.contains(where: { !$0.country.isEmpty }) { result.append(.countries) }
        return result
    }

    private var supportFooter: some View {
        NavigationLink { SupportView(language: language) } label: {
            HStack(spacing: 13) {
                Image(systemName: "heart").font(.title3).foregroundStyle(DesignTokens.accent)
                VStack(alignment: .leading, spacing: 3) {
                    Text(language.text("Apoie", "Support")).font(.system(.headline, design: .serif, weight: .semibold)).foregroundStyle(DesignTokens.ink)
                    Text(language.text("Escolha como apoiar", "Choose how to support")).font(.subheadline).foregroundStyle(DesignTokens.muted)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(DesignTokens.muted)
            }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
                .background(DesignTokens.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(DesignTokens.rule, lineWidth: 1))
        }.buttonStyle(.plain)
    }

    private var privacyFooter: some View {
        NavigationLink { PrivacyPolicyView(language: language) } label: {
            Text(PrivacyPolicyCopy.forLanguage(language).title)
                .font(.footnote)
                .foregroundStyle(DesignTokens.muted)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var savedPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack { sectionHeading(language.text("Salvos", "Saved")); Spacer(); Button(language.text("Ver todos", "See all")) { filter = .saved }.font(.subheadline.weight(.medium)).foregroundStyle(DesignTokens.accent).frame(minHeight: 44).contentShape(Rectangle()) }
            ForEach(Array(savedWorks.prefix(4)), id: \.1.id) { author, work in
                NavigationLink { ReaderView(work: work, authorName: work.displayCredit(archiveName: author.full), language: language) } label: { WorkListRow(work: work, author: work.displayCredit(archiveName: author.full)) }
                    .buttonStyle(.plain).foregroundStyle(DesignTokens.ink)
            }
        }
    }

    private func popularWorkList(_ works: [(Author, Work)], title: String, showAll: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack { sectionHeading(title); Spacer(); if showAll { Button(language.text("Ver todos", "See all")) { filter = .popular }.font(.subheadline.weight(.medium)).foregroundStyle(DesignTokens.accent).frame(minHeight: 44).contentShape(Rectangle()) } }
            if !showAll {
                Text(language.text("Ranking editorial estimado", "Estimated editorial ranking"))
                    .font(.caption).foregroundStyle(DesignTokens.muted)
            }
            LazyVStack(spacing: 0) {
                ForEach(Array(works.enumerated()), id: \.offset) { index, item in
                    NavigationLink { ReaderView(work: item.1, authorName: item.1.displayCredit(archiveName: item.0.full), language: language) } label: {
                        HStack(spacing: 12) {
                            if !showAll {
                                Text(String(format: "%02d", index + 1)).font(.system(.caption, design: .monospaced, weight: .medium)).foregroundStyle(DesignTokens.muted).frame(width: 28, alignment: .leading)
                            }
                            WorkListRow(work: item.1, author: item.1.displayCredit(archiveName: item.0.full))
                        }
                    }.buttonStyle(.plain).foregroundStyle(DesignTokens.ink)
                    if index < works.count - 1 { Rectangle().fill(DesignTokens.rule).frame(height: 1).padding(.leading, showAll ? 63 : 40) }
                }
            }
        }
    }

    private func collectionList(_ collections: [CatalogCollection], title: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading(title)
            let grouped = Dictionary(grouping: collections, by: { $0.group })
            ForEach(grouped.keys.sorted(), id: \.self) { group in
                if !group.isEmpty { Text(group).font(.system(.headline, design: .serif)).padding(.top, 4) }
                ForEach(grouped[group] ?? []) { collection in
                    NavigationLink { CollectionDetailView(collection: collection, language: language, catalog: catalog) } label: {
                        HStack {
                            Text(collection.title).font(.system(.body, design: .serif, weight: .medium)).foregroundStyle(DesignTokens.ink)
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(DesignTokens.muted)
                        }.padding(.vertical, 10).contentShape(Rectangle())
                    }.buttonStyle(.plain)
                    Rectangle().fill(DesignTokens.rule).frame(height: 1)
                }
            }
            if collections.isEmpty { emptyState(title: language.text("Nada encontrado", "No results found"), detail: language.text("Tente outro termo.", "Try another search.")) }
        }
    }

    private func figureList(_ figures: [CatalogItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading(language.text("Figuras históricas", "Glossary of people"))
            Toggle(language.text("Somente pessoas", "People only"), isOn: $peopleOnly).font(.subheadline)
            LazyVStack(spacing: 0) {
                ForEach(figures) { figure in
                    NavigationLink { ReaderView(work: figure.work, authorName: "", language: language) } label: {
                        LibraryRow(title: figure.title, subtitle: "")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }.buttonStyle(.plain).foregroundStyle(DesignTokens.ink)
                    Rectangle().fill(DesignTokens.rule).frame(height: 1)
                }
            }
            if figures.isEmpty { emptyState(title: language.text("Nada encontrado", "No results found"), detail: language.text("Busque por uma pessoa.", "Search for a person.")) }
        }
    }

    private func countryList(_ countries: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeading(language.text("Países", "Countries"))
            if let catalog {
                ForEach(countries, id: \.self) { country in
                    NavigationLink { CountryWritersView(country: country, authors: catalog.authors, language: language) } label: {
                        HStack { Text(country).foregroundStyle(DesignTokens.ink); Spacer(); Text(catalog.authors.filter { $0.country == country }.count.formatted()).foregroundStyle(DesignTokens.muted); Image(systemName: "chevron.right").font(.caption).foregroundStyle(DesignTokens.muted) }
                            .padding(.vertical, 10)
                    }.buttonStyle(.plain)
                }
            }
            if countries.isEmpty { emptyState(title: language.text("Nenhum país encontrado", "No countries found"), detail: language.text("Os países estão disponíveis no catálogo em português.", "Country data is available in the Portuguese catalog.")) }
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundStyle(DesignTokens.muted)
            TextField(language.text("Buscar autores e textos", "Search writers and works"), text: $query)
                .textInputAutocapitalization(.never).autocorrectionDisabled()
                .onSubmit {
                    if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Analytics.track(.searchUsed)
                    }
                }
            if !query.isEmpty {
                Button { query = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(DesignTokens.muted) }
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
                    .accessibilityLabel(language.text("Limpar busca", "Clear search"))
            }
        }
        .font(.body).padding(.horizontal, 18).frame(minHeight: 54)
        .modifier(SearchGlass())
    }

    private func continueReadingShelf(_ entries: [ReadingProgress]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeading(language.text("Continue lendo", "Continue reading"))
                Spacer()
                Button(language.text("Ver histórico", "Full history")) { filter = .readingHistory }
                    .font(.subheadline.weight(.medium)).foregroundStyle(DesignTokens.accent).frame(minHeight: 44).contentShape(Rectangle())
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(entries) { entry in
                        let credit = catalog?.credit(forPath: entry.path) ?? ""
                        NavigationLink { ReaderView(work: Work(title: entry.title, path: entry.path, date: "", section: 0), authorName: credit, language: language) } label: {
                            HStack(alignment: .top, spacing: 11) {
                                    BookCover(title: entry.title, compact: false).frame(width: 64, height: 86)
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(entry.title)
                                            .font(.system(.headline, design: .serif, weight: .semibold))
                                            .multilineTextAlignment(.leading)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        if !credit.isEmpty { Text(credit).font(.caption).foregroundStyle(DesignTokens.muted) }
                                        Spacer(minLength: 2)
                                        ProgressView(value: entry.progress).tint(DesignTokens.accent)
                                        Text(language.readingProgress(Int(entry.progress * 100)))
                                            .font(.caption).foregroundStyle(DesignTokens.muted)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .frame(minHeight: 86, alignment: .topLeading)
                                }
                            .padding(12).frame(width: 236, alignment: .leading)
                            .background(DesignTokens.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(DesignTokens.rule, lineWidth: 1))
                            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }.buttonStyle(.plain).foregroundStyle(DesignTokens.ink)
                    }
                }
            }.contentMargins(.trailing, 2).scrollTargetBehavior(.viewAligned)
        }
    }

    private func startHere(_ item: (Author, Work)) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeading(language.text("Uma boa leitura para começar", "A good place to start"))
            NavigationLink { ReaderView(work: item.1, authorName: item.1.displayCredit(archiveName: item.0.full), language: language) } label: {
                HStack(spacing: 15) {
                    BookCover(title: item.1.title, compact: false).frame(width: 76, height: 104)
                    VStack(alignment: .leading, spacing: 7) {
                        Text(item.1.title).font(.system(.title3, design: .serif, weight: .semibold)).multilineTextAlignment(.leading)
                        if !item.1.displayCredit(archiveName: item.0.full).isEmpty {
                            Text(item.1.displayCredit(archiveName: item.0.full)).font(.subheadline).foregroundStyle(DesignTokens.muted)
                        }
                        Text(language.text("Começar a ler", "Start reading"))
                            .font(.subheadline.weight(.semibold)).foregroundStyle(DesignTokens.accent).padding(.top, 2)
                    }
                    Spacer(minLength: 0)
                }
                .padding(14)
                .background(DesignTokens.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(DesignTokens.rule, lineWidth: 1))
            }.buttonStyle(.plain)
        }
    }

    private func writerShelf(_ authors: [Author], title: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                HStack { sectionHeading(title); Spacer(); Button(language.text("Ver todos", "See all")) { filter = .writers }.font(.subheadline.weight(.medium)).foregroundStyle(DesignTokens.accent).frame(minHeight: 44).contentShape(Rectangle()) }
                if title == language.text("Autores populares", "Popular writers") {
                    Text(language.text("Seleção editorial", "Editorial selection"))
                        .font(.caption).foregroundStyle(DesignTokens.muted)
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(authors) { author in
                        NavigationLink { AuthorView(author: author, language: language) } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                AuthorArtwork(author: author, language: language).frame(width: 126, height: 116)
                                Text(author.full).font(.system(.subheadline, design: .serif, weight: .semibold)).multilineTextAlignment(.leading)
                                Text(language.workCount(author.works.count))
                                    .font(.caption).foregroundStyle(DesignTokens.muted)
                            }.frame(width: 126, alignment: .leading)
                        }.buttonStyle(.plain).foregroundStyle(DesignTokens.ink)
                    }
                }
            }.contentMargins(.trailing, 2)
        }
    }

    private func writerList(_ authors: [Author]) -> some View {
        let authors = sortedAuthors(authors)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionHeading(language.text("Autores", "Writers"))
                Spacer()
                sortMenu
                if catalogSort == .popularity && query.isEmpty && authors.contains(where: { !$0.groups.isEmpty }) {
                    Button(groupWriters ? language.text("A–Z", "A–Z") : language.text("Movimentos", "Movements")) { groupWriters.toggle() }
                        .font(.subheadline.weight(.medium)).foregroundStyle(DesignTokens.accent)
                }
            }
            if catalogSort == .popularity && groupWriters && query.isEmpty && authors.contains(where: { !$0.groups.isEmpty }) {
                let map = Dictionary(grouping: authors.flatMap { author in
                    (author.groups.isEmpty ? [language.text("Outros", "Other")] : author.groups).map { ($0, author) }
                }, by: { $0.0 })
                ForEach(map.keys.sorted(), id: \.self) { group in
                    Text(group).font(.system(.headline, design: .serif)).padding(.top, 8)
                    LazyVStack(spacing: 0) {
                        ForEach(map[group, default: []].map(\.1)) { author in writerRow(author) }
                    }
                }
            } else {
                LazyVStack(spacing: 0) { ForEach(authors) { author in writerRow(author) } }
            }
        }
    }

    private func writerRow(_ author: Author) -> some View {
        VStack(spacing: 0) {
            NavigationLink { AuthorView(author: author, language: language) } label: {
                HStack(spacing: 13) {
                    AuthorArtwork(author: author, language: language).frame(width: 52, height: 58)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(author.full).font(.system(.headline, design: .serif, weight: .medium))
                                Text([author.dates, language.workCount(author.works.count)].filter { !$0.isEmpty }.joined(separator: " · "))
                            .font(.subheadline).foregroundStyle(DesignTokens.muted)
                    }
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(DesignTokens.muted)
                }.padding(.vertical, 11).contentShape(Rectangle())
            }.buttonStyle(.plain).foregroundStyle(DesignTokens.ink)
            Rectangle().fill(DesignTokens.rule).frame(height: 1).padding(.leading, 65)
        }
    }

    private func workList(_ works: [(Author, Work)], title: String, showAll: Bool = false) -> some View {
        let works = sortedWorks(works)
        return VStack(alignment: .leading, spacing: 12) {
            HStack { sectionHeading(title); Spacer(); sortMenu; if showAll { Button(language.text("Ver todos", "See all")) { filter = .works }.font(.subheadline.weight(.medium)).foregroundStyle(DesignTokens.accent).frame(minHeight: 44).contentShape(Rectangle()) } }
            LazyVStack(spacing: 0) {
                ForEach(works, id: \.1.id) { author, work in
                    NavigationLink { ReaderView(work: work, authorName: work.displayCredit(archiveName: author.full), language: language) } label: {
                        WorkListRow(work: work, author: work.displayCredit(archiveName: author.full))
                    }.buttonStyle(.plain).foregroundStyle(DesignTokens.ink)
                    if work.id != works.last?.1.id { Rectangle().fill(DesignTokens.rule).frame(height: 1).padding(.leading, 65) }
                }
            }
        }
    }

    private var sortMenu: some View {
        Menu {
            ForEach(CatalogSort.allCases) { option in
                Button {
                    catalogSortRaw = option.rawValue
                    if option != .popularity { groupWriters = false }
                } label: {
                    if catalogSort == option { Label(option.title(language), systemImage: "checkmark") }
                    else { Text(option.title(language)) }
                }
            }
        } label: {
            Label(catalogSort.title(language), systemImage: "arrow.up.arrow.down")
                .font(.subheadline.weight(.medium)).foregroundStyle(DesignTokens.accent)
        }
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .accessibilityLabel(language.text("Ordenar", "Sort"))
    }

    private func sectionHeading(_ title: String) -> some View {
        Text(title.uppercased()).font(.subheadline.weight(.semibold)).tracking(0.8).foregroundStyle(DesignTokens.muted)
            .accessibilityAddTraits(.isHeader)
    }

    private func emptyState(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "books.vertical").font(.title2).foregroundStyle(DesignTokens.accent).padding(.bottom, 4)
            Text(title).font(.system(.title3, design: .serif, weight: .semibold))
            Text(detail).font(.subheadline).foregroundStyle(DesignTokens.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading).padding(20)
        .background(DesignTokens.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

enum LibraryFilter: String, CaseIterable, Identifiable {
    case all, saved, writers, works, readingHistory, topics, history, figures, countries, popular
    var id: String { rawValue }
    func title(_ language: Language) -> String {
        switch self {
        case .all: language.text("Tudo", "All")
        case .saved: language.text("Salvos", "Saved")
        case .writers: language.text("Autores", "Writers")
        case .works: language.text("Textos", "Works")
        case .readingHistory: language.text("Histórico", "Reading log")
        case .topics: language.text("Temas", "Subjects")
        case .history: language.text("História", "History")
        case .figures: language.text("Figuras", "People")
        case .countries: language.text("Países", "Countries")
        case .popular: language.text("Populares", "Popular")
        }
    }
}

struct ReadingProgress: Codable, Identifiable {
    var path: String
    var title: String
    var author: String
    var progress: Double
    var id: String { path }
}

struct BookCover: View {
    let title: String
    var compact = true
    private var tone: Color {
        let seed = title.unicodeScalars.reduce(0) { ($0 &* 31 &+ Int($1.value)) & 0x7fffffff }
        return [DesignTokens.coverOchre, DesignTokens.coverRust, DesignTokens.coverOlive, DesignTokens.coverBlue][seed % 4]
    }
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                tone
                VStack(alignment: .leading, spacing: 0) {
                    Rectangle().fill(.white.opacity(0.72)).frame(width: proxy.size.width * 0.28, height: 2)
                    Spacer(minLength: 6)
                    Text(title).font(.system(size: compact ? 9 : 10, weight: .semibold, design: .serif))
                        .lineLimit(compact ? 4 : 5).minimumScaleFactor(0.75).foregroundStyle(.white)
                    Spacer(minLength: 5)
                    Text("MIA").font(.system(size: 7, weight: .bold, design: .rounded)).tracking(1.2).foregroundStyle(.white.opacity(0.8))
                }.padding(compact ? 7 : 9)
            }
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 7, style: .continuous).stroke(.black.opacity(0.08), lineWidth: 1))
            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        }
    }
}

struct AuthorArtwork: View {
    let author: Author
    let language: Language
    @State private var portrait: UIImage?
    @State private var faceCenter: CGPoint?
    private var url: URL? {
        if let photo = author.photo, let url = URL(string: photo, relativeTo: URL(string: language.base))?.absoluteURL {
            return url
        }
        if let avatar = author.avatar, let url = URL(string: avatar, relativeTo: URL(string: language.base))?.absoluteURL {
            return url
        }
        // The English MIA index groups Marx and Engels, but keeps their portraits
        // in individual photo galleries rather than the writer metadata.
        if language == .en && author.id == "archive/marx" {
            return URL(string: "archive/marx/photo/marx/images/67km1.jpg", relativeTo: URL(string: language.base))?.absoluteURL
        }
        return nil
    }
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                DesignTokens.coverStone
                if let portrait {
                    let scale = max(proxy.size.width / portrait.size.width, proxy.size.height / portrait.size.height)
                    let size = CGSize(width: portrait.size.width * scale, height: portrait.size.height * scale)
                    let center = author.id == "engels" ? CGPoint(x: 0.5, y: 0) : (faceCenter ?? CGPoint(x: 0.5, y: 0.25))
                    let x = min(max((0.5 - center.x) * size.width, -(size.width - proxy.size.width) / 2), (size.width - proxy.size.width) / 2)
                    let y = min(max((0.5 - center.y) * size.height, -(size.height - proxy.size.height) / 2), (size.height - proxy.size.height) / 2)
                    Image(uiImage: portrait).resizable()
                        .frame(width: size.width, height: size.height)
                        .offset(x: x, y: y)
                } else { monogram }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
        .task(id: url) {
            portrait = nil
            faceCenter = nil
            guard let url, let data = try? await PortraitCache.shared.data(for: url, validate: { UIImage(data: $0) != nil }),
                  !Task.isCancelled, let image = UIImage(data: data), image.size.width > 0, image.size.height > 0 else { return }
            portrait = image
            let center = await Task.detached(priority: .utility) { () -> CGPoint? in
                guard let cgImage = image.cgImage else { return nil }
                let orientation: CGImagePropertyOrientation
                switch image.imageOrientation {
                case .up: orientation = .up
                case .down: orientation = .down
                case .left: orientation = .left
                case .right: orientation = .right
                case .upMirrored: orientation = .upMirrored
                case .downMirrored: orientation = .downMirrored
                case .leftMirrored: orientation = .leftMirrored
                case .rightMirrored: orientation = .rightMirrored
                @unknown default: orientation = .up
                }
                let request = VNDetectFaceRectanglesRequest()
                guard (try? VNImageRequestHandler(cgImage: cgImage, orientation: orientation).perform([request])) != nil,
                      let face = request.results?.max(by: { $0.boundingBox.width * $0.boundingBox.height < $1.boundingBox.width * $1.boundingBox.height }) else { return nil }
                return CGPoint(x: face.boundingBox.midX, y: 1 - face.boundingBox.midY)
            }.value
            guard !Task.isCancelled else { return }
            faceCenter = center
        }
    }
    private var monogram: some View {
        Text(author.full.split(separator: " ").first.map(String.init)?.prefix(1) ?? "M")
            .font(.system(.title2, design: .serif, weight: .medium)).foregroundStyle(DesignTokens.accent)
    }
}

struct WorkListRow: View {
    let work: Work
    let author: String
    var body: some View {
        HStack(spacing: 13) {
            BookCover(title: work.title).frame(width: 50, height: 68)
            VStack(alignment: .leading, spacing: 5) {
                Text(work.title).font(.system(.headline, design: .serif, weight: .medium)).multilineTextAlignment(.leading)
                if !author.isEmpty { Text(author).font(.subheadline).foregroundStyle(DesignTokens.muted) }
                if !work.date.isEmpty { Text(work.date).font(.caption).foregroundStyle(DesignTokens.muted) }
            }
            Spacer(minLength: 4)
            Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(DesignTokens.muted)
        }
        .padding(.vertical, 10).contentShape(Rectangle())
    }
}

struct LibraryRow: View {
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.rowSpacing) {
            Text(title).font(.system(.headline, design: .serif, weight: .medium))
            if !subtitle.isEmpty { Text(subtitle).font(.subheadline).foregroundStyle(DesignTokens.muted) }
        }.padding(.vertical, 5).frame(minHeight: 44, alignment: .leading)
    }
}

struct AuthorView: View {
    let author: Author
    let language: Language
    @State private var expandedBio = false
    var body: some View {
        List {
            Section {
                HStack(alignment: .top, spacing: 14) {
                    AuthorArtwork(author: author, language: language).frame(width: 92, height: 112)
                    VStack(alignment: .leading, spacing: 7) {
                        Text(author.full).font(.system(.title2, design: .serif, weight: .semibold))
                        if !author.dates.isEmpty { Text(author.dates).font(.subheadline).foregroundStyle(.secondary) }
                        if !author.country.isEmpty { Label(author.country, systemImage: "globe.americas").font(.caption).foregroundStyle(.secondary) }
                        ForEach(author.groups, id: \.self) { group in Text(group).font(.caption).foregroundStyle(DesignTokens.accent) }
                    }
                }.padding(.vertical, 6)
                if !author.bio.isEmpty {
                    Text(author.bio).font(.body).lineLimit(expandedBio ? nil : 5)
                    Button(expandedBio ? language.text("Ler menos", "Read less") : language.text("Ler mais", "Read more")) { expandedBio.toggle() }
                        .font(.subheadline.weight(.medium))
                }
                if let bioPath = author.bioPath, !bioPath.isEmpty {
                    NavigationLink(language.text("Biografia completa", "Full biography")) {
                        ReaderView(work: Work(title: language.text("Biografia", "Biography"), path: bioPath, date: "", section: 0), authorName: author.full, language: language)
                    }
                }
            }
            ForEach(Array(author.sections.enumerated()), id: \.offset) { index, section in
                let works = author.works.filter { $0.section == index }
                if !works.isEmpty {
                    Section(section.isEmpty ? language.text("Obras", "Works") : section) {
                        ForEach(works) { work in
                            NavigationLink { ReaderView(work: work, authorName: work.displayCredit(archiveName: author.full), language: language) } label: {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(work.title)
                                    if !work.date.isEmpty { Text(work.date).font(.caption).foregroundStyle(.secondary) }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(author.name).navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden).background(DesignTokens.paper.ignoresSafeArea())
        .toolbarBackground(DesignTokens.paper, for: .navigationBar)
        .onAppear { Analytics.track(.authorProfileOpened) }
    }
}

struct CountryWritersView: View {
    let country: String
    let authors: [Author]
    let language: Language
    var body: some View {
        List(authors.filter { $0.country == country }) { author in
            NavigationLink { AuthorView(author: author, language: language) } label: {
                HStack(spacing: 12) {
                    AuthorArtwork(author: author, language: language).frame(width: 48, height: 54)
                    VStack(alignment: .leading) {
                        Text(author.full).font(.system(.headline, design: .serif))
                        Text(author.dates.isEmpty ? "\(author.works.count)" : author.dates).font(.caption).foregroundStyle(.secondary)
                    }
                }.padding(.vertical, 4)
            }
        }.navigationTitle(country).scrollContentBackground(.hidden).background(DesignTokens.paper.ignoresSafeArea())
    }
}

struct CollectionDetailView: View {
    let collection: CatalogCollection
    let language: Language
    let catalog: Catalog?
    var body: some View {
        List {
            ForEach(collection.groups) { group in
                Section(group.name.isEmpty ? collection.title : group.name) {
                    ForEach(group.items) { item in
                        NavigationLink {
                            ReaderView(work: item.work, authorName: catalog?.credit(forPath: item.path) ?? "", language: language)
                        } label: { Text(item.title).font(.system(.body, design: .serif)) }
                    }
                }
            }
            if collection.groups.allSatisfy({ $0.items.isEmpty }) {
                Section { NavigationLink(language.text("Abrir no arquivo", "Open in archive")) {
                    ReaderView(work: Work(title: collection.title, path: collection.id, date: "", section: 0), authorName: "", language: language)
                } }
            }
        }
        .navigationTitle(collection.title).navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden).background(DesignTokens.paper.ignoresSafeArea())
    }
}

struct SupportView: View {
    let language: Language
    private let koFiURL: URL? = nil
    private let archiveDonationURL = URL(string: "https://www.marxists.org/admin/donate/index.htm")!

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: "heart.text.square").font(.system(size: 38)).foregroundStyle(DesignTokens.accent)
                    Text(language.text("Apoie", "Support")).font(.system(.largeTitle, design: .serif, weight: .medium))
                    Text(language.text("Escolha como apoiar", "Choose how to support")).font(.body).foregroundStyle(DesignTokens.muted)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text(language.text("Apoie este app", "Support this app"))
                        .font(.system(.title3, design: .serif, weight: .semibold))
                    Text(language.text("Ajude a manter o leitor gratuito e em evolução.", "Help keep the reader free and improving."))
                        .font(.subheadline).foregroundStyle(DesignTokens.muted)
                    if let koFiURL {
                        supportLink(to: koFiURL, title: "Ko-fi", action: language.text("Apoiar no Ko-fi", "Support on Ko-fi"), icon: "cup.and.saucer.fill")
                    } else {
                        supportCard(title: "Ko-fi", action: language.text("Apoiar no Ko-fi", "Support on Ko-fi"), detail: language.text("Adicione o link do perfil para ativar.", "Ko-fi profile link pending"), icon: "cup.and.saucer.fill")
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text(language.text("Apoie o Marxists.org", "Support Marxists.org"))
                        .font(.system(.title3, design: .serif, weight: .semibold))
                    Text(language.text("Ajude a preservar o Marxists Internet Archive.", "Help preserve the Marxists Internet Archive."))
                        .font(.subheadline).foregroundStyle(DesignTokens.muted)
                    supportLink(to: archiveDonationURL, title: "Marxists.org", action: language.text("Doar ao Marxists.org", "Donate to Marxists.org"), icon: "books.vertical.fill")
                    .padding(.top, 2)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(language.text("Apoie", "Support"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .background(DesignTokens.paper.ignoresSafeArea())
        .onAppear { Analytics.track(.supportPageOpened) }
    }

    private func supportLink(to url: URL, title: String, action: String, icon: String) -> some View {
        Link(destination: url) {
            supportCard(title: title, action: action, detail: nil, icon: icon)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(TapGesture().onEnded {
            let destination: SupportDestination = title == "Ko-fi" ? .kofi : .archive
            Analytics.track(.supportDestinationOpened(destination))
        })
    }

    private func supportCard(title: String, action: String, detail: String?, icon: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.title3).foregroundStyle(DesignTokens.accent)
                .frame(width: 42, height: 42).background(DesignTokens.paper, in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(.headline, design: .serif, weight: .semibold)).foregroundStyle(DesignTokens.ink)
                if let detail { Text(detail).font(.caption).foregroundStyle(DesignTokens.muted) }
                Text(action).font(.subheadline.weight(.medium)).foregroundStyle(DesignTokens.accent)
            }
            Spacer(minLength: 4)
            Image(systemName: "arrow.up.right").font(.caption.weight(.semibold)).foregroundStyle(DesignTokens.muted)
        }
        .padding(16)
        .background(DesignTokens.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(DesignTokens.rule, lineWidth: 1))
    }
}

struct PrivacyPolicyView: View {
    let language: Language
    @AppStorage("analyticsConsent") private var analyticsConsent = false

    private var copy: PrivacyPolicyCopy { .forLanguage(language) }
    private let telemetryDeckPrivacyURL = URL(string: "https://telemetrydeck.com/docs/guides/privacy-faq/")!

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text(copy.intro)
                    .font(.body)
                    .foregroundStyle(DesignTokens.ink)
                    .fixedSize(horizontal: false, vertical: true)

                policySection(copy.onDeviceTitle, body: copy.onDeviceBody)
                policySection(copy.archiveTitle, body: copy.archiveBody)

                VStack(alignment: .leading, spacing: 10) {
                    policyHeading(copy.analyticsTitle)
                    Text(copy.analyticsBody)
                        .font(.subheadline)
                        .foregroundStyle(DesignTokens.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if Analytics.isAvailable {
                        Toggle(isOn: $analyticsConsent) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(copy.analyticsConsentTitle)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(DesignTokens.ink)
                                Text(copy.analyticsConsentDetail)
                                    .font(.footnote)
                                    .foregroundStyle(DesignTokens.muted)
                            }
                        }
                        .tint(DesignTokens.accent)
                        .accessibilityHint(copy.analyticsConsentDetail)
                        .onChange(of: analyticsConsent) { _, enabled in
                            Analytics.setConsent(enabled)
                        }
                    } else {
                        Text(copy.analyticsUnavailable)
                            .font(.footnote)
                            .foregroundStyle(DesignTokens.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Link(copy.analyticsPolicyLink, destination: telemetryDeckPrivacyURL)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(DesignTokens.accent)
                }

                policySection(copy.thirdPartyTitle, body: copy.thirdPartyBody)
                policySection(copy.retentionTitle, body: copy.retentionBody)

                VStack(alignment: .leading, spacing: 7) {
                    policyHeading(copy.contactTitle)
                    Text(copy.contactBody)
                        .font(.subheadline)
                        .foregroundStyle(DesignTokens.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Link(copy.contactEmail, destination: URL(string: "mailto:\(copy.contactEmail)")!)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(DesignTokens.accent)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(copy.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(DesignTokens.paper, for: .navigationBar)
        .background(DesignTokens.paper.ignoresSafeArea())
    }

    private func policySection(_ title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            policyHeading(title)
            Text(body)
                .font(.subheadline)
                .foregroundStyle(DesignTokens.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func policyHeading(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption.weight(.semibold))
            .tracking(1)
            .foregroundStyle(DesignTokens.muted)
    }
}


struct ReaderAppearanceView: View {
    @Binding var appearance: ReaderAppearance
    let language: Language
    var body: some View {
        NavigationStack {
            Form {
                Section(language.text("Texto", "Text")) {
                    Picker(language.text("Fonte", "Font"), selection: $appearance.font) {
                        Text(language.text("Serifada", "Serif")).tag("serif")
                        Text(language.text("Sem serifa", "Sans serif")).tag("sans")
                        Text(language.text("Livro", "Book")).tag("book")
                        Text(language.text("Condensada", "Condensed")).tag("condensed")
                        Text(language.text("Monoespaçada", "Monospaced")).tag("mono")
                        Text(language.text("Casual", "Casual")).tag("casual")
                    }
                    LabeledContent(language.text("Tamanho", "Size"), value: "\(appearance.size) px")
                    Slider(value: Binding(get: { Double(appearance.size) }, set: { appearance.size = Int($0.rounded()) }), in: 13...34, step: 1)
                        .accessibilityLabel(language.text("Tamanho", "Size"))
                        .accessibilityValue("\(appearance.size) px")
                    LabeledContent(language.text("Espaçamento", "Line spacing"), value: appearance.lineSpacing.formatted(.number.precision(.fractionLength(1))))
                    Slider(value: $appearance.lineSpacing, in: 1.2...2.4, step: 0.1)
                        .accessibilityLabel(language.text("Espaçamento", "Line spacing"))
                        .accessibilityValue(appearance.lineSpacing.formatted(.number.precision(.fractionLength(1))))
                    LabeledContent(language.text("Margens", "Margins"), value: "\(appearance.margin) px")
                    Slider(value: Binding(get: { Double(appearance.margin) }, set: { appearance.margin = Int($0.rounded()) }), in: 8...48, step: 2)
                        .accessibilityLabel(language.text("Margens", "Margins"))
                        .accessibilityValue("\(appearance.margin) px")
                    Picker(language.text("Alinhamento", "Alignment"), selection: $appearance.alignment) {
                        Text(language.text("À esquerda", "Left")).tag("left")
                        Text(language.text("Justificado", "Justified")).tag("justified")
                    }.pickerStyle(.segmented)
                }
                Section(language.text("Cores", "Colours")) {
                    Picker(language.text("Tema", "Theme"), selection: Binding(get: { appearance.theme }, set: { appearance.setTheme($0) })) {
                        Text(language.text("Claro", "Light")).tag("light")
                        Text(language.text("Sépia", "Sepia")).tag("sepia")
                        Text(language.text("Cinza", "Gray")).tag("gray")
                        Text(language.text("Escuro", "Dark")).tag("dark")
                        Text(language.text("Preto", "Black")).tag("black")
                        Text(language.text("Vermelho", "Red")).tag("red")
                        Text(language.text("Personalizado", "Custom")).tag("custom")
                    }
                    if appearance.theme == "custom" {
                        ColorPicker(language.text("Fundo", "Background"), selection: hexColor(\.background))
                        ColorPicker(language.text("Texto", "Text"), selection: hexColor(\.foreground))
                        ColorPicker(language.text("Links", "Links"), selection: hexColor(\.link))
                        contrastStatus
                    } else {
                        Button(language.text("Personalizar cores", "Customize colours")) { appearance.theme = "custom" }
                    }
                }
                Section {
                    Button(language.text("Restaurar padrão", "Restore defaults"), role: .destructive) { appearance = ReaderAppearance() }
                }
            }
            .navigationTitle(language.text("Aparência do texto", "Text appearance"))
            .navigationBarTitleDisplayMode(.inline)
        }
        .tint(DesignTokens.accent)
    }
    private var contrastStatus: some View {
        let textRatio = ColorContrast.ratio(appearance.foreground, appearance.background) ?? 0
        let linkRatio = ColorContrast.ratio(appearance.link, appearance.background) ?? 0
        return VStack(alignment: .leading, spacing: 4) {
            Text(language.text("Contraste do texto", "Text contrast") + ": " + textRatio.formatted(.number.precision(.fractionLength(1))) + ":1")
            Text(language.text("Contraste dos links", "Link contrast") + ": " + linkRatio.formatted(.number.precision(.fractionLength(1))) + ":1")
            Text(textRatio >= 4.5 && linkRatio >= 4.5
                 ? language.text("O contraste atende ao mínimo AA.", "Contrast meets the AA minimum.")
                 : language.text("Use cores com contraste de pelo menos 4,5:1 para texto e links.", "Use colors with at least 4.5:1 contrast for text and links."))
        }.font(.footnote).foregroundStyle(DesignTokens.muted)
    }
    private func hexColor(_ keyPath: WritableKeyPath<ReaderAppearance, String>) -> Binding<Color> {
        Binding(get: { Color(hex: appearance[keyPath: keyPath]) }, set: { appearance[keyPath: keyPath] = $0.hexString; appearance.theme = "custom" })
    }
}

extension Color {
    init(hex: String) {
        let value = UInt64(hex.dropFirst().prefix(6), radix: 16) ?? 0xFBFAF7
        self.init(.sRGB, red: Double((value >> 16) & 0xff) / 255, green: Double((value >> 8) & 0xff) / 255, blue: Double(value & 0xff) / 255, opacity: 1)
    }
    var hexString: String {
        let c = UIColor(self).cgColor.components ?? [0, 0, 0, 1]
        return String(format: "#%02x%02x%02x", Int(c[0] * 255), Int(c[1] * 255), Int(c[2] * 255))
    }
}

struct ReaderView: View {
    let work: Work
    let authorName: String
    let language: Language
    @AppStorage("savedWorkPaths") private var savedWorkPaths = "[]"
    @AppStorage("recentReadings") private var recentReadings = "[]"
    @AppStorage("readerAppearance") private var appearanceData = ""
    @State private var appearance: ReaderAppearance
    @State private var showAppearance = false
    @State private var html: String?
    @State private var pdfData: Data?
    @State private var failed = false
    private var sourceURL: URL? { URL(string: work.path, relativeTo: URL(string: language.base))?.absoluteURL }
    private var isPDF: Bool { sourceURL?.pathExtension.lowercased() == "pdf" }
    private var isSaved: Bool {
        ((try? JSONDecoder().decode([String].self, from: Data(savedWorkPaths.utf8))) ?? []).contains(work.path)
    }
    private var initialProgress: Double {
        let entries = (try? JSONDecoder().decode([ReadingProgress].self, from: Data(recentReadings.utf8))) ?? []
        return entries.first(where: { $0.path == work.path })?.progress ?? 0
    }
    init(work: Work, authorName: String, language: Language) {
        self.work = work
        self.authorName = authorName
        self.language = language
        let saved = UserDefaults.standard.string(forKey: "readerAppearance") ?? ""
        _appearance = State(initialValue: ReaderAppearance.decode(saved))
    }
    var body: some View {
        Group {
            if let pdfData {
                PDFReaderView(data: pdfData, initialProgress: initialProgress) { saveProgress($0) }
                    .ignoresSafeArea(edges: .bottom)
            } else if let html, let sourceURL {
                ReaderWebView(html: html, sourceURL: sourceURL, appearance: appearance, initialProgress: initialProgress) { saveProgress($0) }
            } else if failed {
                ContentUnavailableView {
                    Label(language.text("Não foi possível carregar", "Could not load the work"), systemImage: "wifi.slash")
                } description: {
                    Text(language.text("Verifique sua conexão e tente novamente.", "Check your connection and try again."))
                } actions: { Button(language.text("Tentar novamente", "Try again")) { Task { await load() } } }
            } else { ProgressView(language.text("Carregando…", "Loading…")) }
        }
        .navigationTitle(work.title).navigationBarTitleDisplayMode(.inline)
        .background(DesignTokens.paper.ignoresSafeArea())
        .toolbarBackground(DesignTokens.paper, for: .navigationBar)
        .toolbar {
            if !isPDF {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAppearance = true } label: { Image(systemName: "textformat.size") }
                        .accessibilityLabel(language.text("Aparência do texto", "Text appearance"))
                        .simultaneousGesture(TapGesture().onEnded { Analytics.track(.readerAppearanceOpened) })
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button { toggleSaved() } label: { Image(systemName: isSaved ? "bookmark.fill" : "bookmark") }
                    .accessibilityLabel(language.text(isSaved ? "Remover dos salvos" : "Salvar texto", isSaved ? "Remove from saved" : "Save work"))
            }
            if let sourceURL {
                ToolbarItem(placement: .primaryAction) {
                    Link(destination: sourceURL) { Image(systemName: "safari") }
                        .accessibilityLabel(language.text("Abrir fonte", "Open source"))
                        .simultaneousGesture(TapGesture().onEnded { Analytics.track(.archiveSourceOpened) })
                }
            }
        }
        .sheet(isPresented: $showAppearance) { ReaderAppearanceView(appearance: $appearance, language: language).presentationDetents([.medium, .large]) }
        .onChange(of: appearance) { _, updated in appearanceData = updated.encoded }
        .task(id: work.path + language.rawValue) { await load() }
        .onAppear { Analytics.track(.workOpened) }
    }
    private func load() async {
        guard let sourceURL, sourceURL.host == "www.marxists.org" else { failed = true; return }
        failed = false
        do {
            if isPDF {
                let data = try await PageStore.loadPDF(sourceURL)
                guard PDFDocument(data: data) != nil else { throw URLError(.cannotDecodeContentData) }
                pdfData = data
                html = nil
            } else {
                html = try await PageStore.load(sourceURL)
                pdfData = nil
            }
            var entries = (try? JSONDecoder().decode([ReadingProgress].self, from: Data(recentReadings.utf8))) ?? []
            let prior = entries.first { $0.path == work.path }
            entries.removeAll { $0.path == work.path }
            entries.insert(ReadingProgress(path: work.path, title: work.title, author: authorName, progress: prior?.progress ?? 0), at: 0)
            recentReadings = String(data: try JSONEncoder().encode(entries), encoding: .utf8) ?? "[]"
        } catch { pdfData = nil; html = nil; failed = true }
    }
    private func toggleSaved() {
        var paths = (try? JSONDecoder().decode([String].self, from: Data(savedWorkPaths.utf8))) ?? []
        if paths.contains(work.path) { paths.removeAll { $0 == work.path } }
        else { paths.insert(work.path, at: 0) }
        savedWorkPaths = String(data: (try? JSONEncoder().encode(paths)) ?? Data("[]".utf8), encoding: .utf8) ?? "[]"
        Analytics.track(.bookmarkChanged(isSaved: paths.contains(work.path)))
    }
    private func saveProgress(_ progress: Double) {
        var entries = (try? JSONDecoder().decode([ReadingProgress].self, from: Data(recentReadings.utf8))) ?? []
        guard let index = entries.firstIndex(where: { $0.path == work.path }) else { return }
        let updated = min(1, max(0, progress))
        guard Int(entries[index].progress * 100) != Int(updated * 100) else { return }
        entries[index].progress = updated
        recentReadings = String(data: (try? JSONEncoder().encode(entries)) ?? Data("[]".utf8), encoding: .utf8) ?? "[]"
    }
}

enum PageStore {
    private static var directory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("OfflinePages", isDirectory: true)
    }
    private static func cachedFile(for url: URL, extension ext: String = "") -> URL {
        let key = SHA256.hash(data: Data(url.absoluteString.utf8)).map { String(format: "%02x", $0) }.joined()
        return directory.appendingPathComponent(key + (ext.isEmpty ? "" : ".\(ext)"))
    }
    static func load(_ url: URL) async throws -> String {
        let file = cachedFile(for: url)
        if let data = try? Data(contentsOf: file), let text = String(data: data, encoding: .utf8) {
            try? FileManager.default.setAttributes([.modificationDate: Date()], ofItemAtPath: file.path)
            return text
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode), http.url?.host == "www.marxists.org" else { throw URLError(.badServerResponse) }
        guard let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .windowsCP1252) else { throw URLError(.cannotDecodeContentData) }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? text.data(using: .utf8)?.write(to: file, options: .atomic)
        var values = URLResourceValues(); values.isExcludedFromBackup = true
        var savedFile = file; try? savedFile.setResourceValues(values)
        trimCache(in: directory, keepingAtMost: 100 * 1024 * 1024)
        return text
    }
    static func loadPDF(_ url: URL) async throws -> Data {
        let file = cachedFile(for: url, extension: "pdf")
        if let data = try? Data(contentsOf: file), PDFDocument(data: data) != nil {
            try? FileManager.default.setAttributes([.modificationDate: Date()], ofItemAtPath: file.path)
            return data
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode), http.url?.host == "www.marxists.org" else { throw URLError(.badServerResponse) }
        guard PDFDocument(data: data) != nil else { throw URLError(.cannotDecodeContentData) }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? data.write(to: file, options: .atomic)
        var values = URLResourceValues(); values.isExcludedFromBackup = true
        var savedFile = file; try? savedFile.setResourceValues(values)
        trimCache(in: directory, keepingAtMost: 100 * 1024 * 1024)
        return data
    }
    private static func trimCache(in directory: URL, keepingAtMost limit: Int) {
        let manager = FileManager.default
        guard let files = try? manager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey]) else { return }
        let sorted = files.compactMap { url -> (URL, Int, Date)? in
            guard let values = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey]) else { return nil }
            return (url, values.fileSize ?? 0, values.contentModificationDate ?? .distantPast)
        }.sorted { $0.2 > $1.2 }
        var total = 0
        for (url, size, _) in sorted {
            total += size
            if total > limit { try? manager.removeItem(at: url) }
        }
    }
}

struct PDFReaderView: UIViewRepresentable {
    let data: Data
    let initialProgress: Double
    var onProgress: (Double) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(onProgress: onProgress) }
    func makeUIView(context: Context) -> PDFView {
        let view = PDFView(frame: .zero)
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.displaysPageBreaks = true
        view.displayBox = .cropBox
        view.backgroundColor = .secondarySystemBackground
        view.document = PDFDocument(data: data)
        context.coordinator.attach(to: view, restoring: initialProgress)
        return view
    }
    func updateUIView(_ view: PDFView, context: Context) {
        context.coordinator.onProgress = onProgress
    }
    final class Coordinator {
        var onProgress: (Double) -> Void
        weak var pdfView: PDFView?
        private var observer: NSObjectProtocol?
        init(onProgress: @escaping (Double) -> Void) { self.onProgress = onProgress }
        func attach(to view: PDFView, restoring progress: Double) {
            pdfView = view
            observer = NotificationCenter.default.addObserver(forName: .PDFViewPageChanged, object: view, queue: .main) { [weak self] _ in
                self?.reportProgress()
            }
            guard let document = view.document, document.pageCount > 0 else { return }
            let lastIndex = max(0, document.pageCount - 1)
            let pageIndex = Int((Double(lastIndex) * min(1, max(0, progress))).rounded())
            if let page = document.page(at: pageIndex) { view.go(to: page) }
        }
        private func reportProgress() {
            guard let view = pdfView, let document = view.document, document.pageCount > 0,
                  let page = view.currentPage else { return }
            let lastIndex = max(1, document.pageCount - 1)
            onProgress(Double(document.index(for: page)) / Double(lastIndex))
        }
        deinit { if let observer { NotificationCenter.default.removeObserver(observer) } }
    }
}

struct ReaderWebView: UIViewRepresentable {
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1
    private var scaledAppearance: ReaderAppearance {
        var result = appearance
        result.size = Int((CGFloat(appearance.size) * textScale).rounded())
        return result
    }
    let html: String
    let sourceURL: URL
    let appearance: ReaderAppearance
    let initialProgress: Double
    var onProgress: (Double) -> Void
    func makeCoordinator() -> Coordinator { Coordinator(onProgress: onProgress) }
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = false
        configuration.userContentController.add(context.coordinator, name: "readerProgress")
        let config = (try? String(data: JSONEncoder().encode(scaledAppearance), encoding: .utf8)) ?? "{}"
        let script = Self.cleanup
            .replacingOccurrences(of: "__INITIAL_PROGRESS__", with: String(min(1, max(0, initialProgress))))
            .replacingOccurrences(of: "__INITIAL_APPEARANCE__", with: config)
        configuration.userContentController.addUserScript(WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.isOpaque = false
        view.backgroundColor = UIColor(red: 0.984, green: 0.98, blue: 0.969, alpha: 1)
        view.loadHTMLString(html, baseURL: sourceURL)
        return view
    }
    func updateUIView(_ view: WKWebView, context: Context) {
        context.coordinator.onProgress = onProgress
        let json = (try? String(data: JSONEncoder().encode(scaledAppearance), encoding: .utf8)) ?? "{}"
        view.evaluateJavaScript("window.setReaderAppearance && window.setReaderAppearance(\(json))")
    }
    final class Coordinator: NSObject, WKScriptMessageHandler {
        var onProgress: (Double) -> Void
        init(onProgress: @escaping (Double) -> Void) { self.onProgress = onProgress }
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "readerProgress", let value = message.body as? Double else { return }
            DispatchQueue.main.async { self.onProgress(value) }
        }
    }
    static let cleanup = """
    document.querySelectorAll('script,style,link,meta,iframe,form,input,button,select,noscript,object,embed,map,.toplink,.toplink-centro,img.logo,img.logodic,nav,p.title').forEach(e => e.remove());
    document.querySelectorAll('*').forEach(e => { for (const a of [...e.attributes]) { if (a.name.toLowerCase().startsWith('on') || ['style','align','bgcolor','color','face','size','background','border','cellpadding','cellspacing','valign','width','height'].includes(a.name.toLowerCase())) e.removeAttribute(a.name); } });
    const style = document.createElement('style'); style.textContent = 'html { -webkit-text-size-adjust: 100%; } body { --reader-bg:#fbfaf7; --reader-ink:#1d1b19; --reader-link:#b3121d; --reader-size:19px; --reader-line:1.6; --reader-margin:18px; --reader-align:left; --reader-font:Georgia, serif; max-width:40rem; margin:auto; padding:26px var(--reader-margin) 64px; background:var(--reader-bg); color:var(--reader-ink); font-family:var(--reader-font); font-size:var(--reader-size); line-height:var(--reader-line); text-align:var(--reader-align); overflow-wrap:anywhere; } h1 { line-height:1.25; letter-spacing:-.025em; margin:.7em 0 .45em; } h2 { line-height:1.3; margin:1.5em 0 .6em; } blockquote { border-left:2px solid var(--reader-link); opacity:.8; margin:1.4em 0; padding-left:1em; } img, table { max-width:100%; height:auto; } a { color:var(--reader-link); text-decoration:underline; }'; document.head.appendChild(style);
    window.setReaderAppearance = (p) => { const b=document.body; const fonts={serif:'Georgia, serif',sans:'system-ui, sans-serif',book:'Palatino, serif',condensed:'\"Arial Narrow\", sans-serif',mono:'monospace',casual:'\"Comic Sans MS\", cursive'}; b.style.setProperty('--reader-bg',p.background||'#fbfaf7'); b.style.setProperty('--reader-ink',p.foreground||'#1d1b19'); b.style.setProperty('--reader-link',p.link||'#b3121d'); b.style.setProperty('--reader-size',(p.size||19)+'px'); b.style.setProperty('--reader-line',p.lineSpacing||1.6); b.style.setProperty('--reader-margin',(p.margin||18)+'px'); b.style.setProperty('--reader-align',p.alignment==='justified'?'justify':'left'); b.style.setProperty('--reader-font',fonts[p.font]||fonts.serif); };
    window.setReaderAppearance(__INITIAL_APPEARANCE__);
    const initialProgress = __INITIAL_PROGRESS__;
    const report = () => { const max = document.documentElement.scrollHeight - window.innerHeight; const progress = max > 0 ? Math.min(1, Math.max(0, window.scrollY / max)) : 0; window.webkit.messageHandlers.readerProgress.postMessage(progress); };
    let restored = false;
    const restore = () => { if (restored) return; const max = document.documentElement.scrollHeight - window.innerHeight; if (max > 0) { window.scrollTo(0, initialProgress * max); restored = true; report(); } };
    window.addEventListener('scroll', report, { passive: true }); window.addEventListener('load', () => setTimeout(restore, 120)); setTimeout(restore, 350); setTimeout(restore, 1000);
    const viewport = document.createElement('meta'); viewport.name = 'viewport'; viewport.content = 'width=device-width, initial-scale=1'; document.head.appendChild(viewport);
    """
}

private struct SearchGlass: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular.interactive(), in: Capsule())
        } else {
            content.background(.regularMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(DesignTokens.rule.opacity(0.5), lineWidth: 1))
        }
    }
}
