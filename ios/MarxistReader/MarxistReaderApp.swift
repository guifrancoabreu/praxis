import SwiftUI
import WebKit
import CryptoKit

@main
struct MarxistReaderApp: App {
    var body: some Scene { WindowGroup { LibraryView() } }
}

struct LibraryView: View {
    @AppStorage("language") private var languageCode = Language.pt.rawValue
    @State private var query = ""
    @State private var catalog: Catalog?
    @State private var error = false
    private var language: Language { Language(rawValue: languageCode) ?? .pt }
    private var matchingAuthors: [Author] {
        guard let catalog else { return [] }
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return q.isEmpty ? catalog.authors : catalog.authors.filter { ($0.name + " " + $0.full).localizedStandardContains(q) }
    }
    private var matchingWorks: [(Author, Work)] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty, let catalog else { return [] }
        return Array(catalog.authors.lazy.flatMap { author in author.works.lazy.filter { $0.title.localizedStandardContains(q) }.map { (author, $0) } }.prefix(100))
    }
    var body: some View {
        NavigationStack {
            Group {
                if let catalog {
                    List {
                        Section {
                            Picker(language.text(.language), selection: $languageCode) {
                                ForEach(Language.allCases) { Text($0.label).tag($0.rawValue) }
                            }
                        }
                        if !matchingAuthors.isEmpty {
                            Section(language.text(.writers)) {
                                ForEach(matchingAuthors) { author in
                                    NavigationLink { AuthorView(author: author, language: language) } label: {
                                        ListRow(title: author.name, subtitle: "\(author.dates)  ·  \(language.workCount(author.works.count))")
                                    }
                                }
                            }
                        }
                        if !matchingWorks.isEmpty {
                            Section(language.text(.works)) {
                                ForEach(matchingWorks, id: \.1.id) { author, work in
                                    NavigationLink { ReaderView(work: work, language: language) } label: {
                                        ListRow(title: work.title, subtitle: author.name)
                                    }
                                }
                            }
                        }
                        if matchingAuthors.isEmpty && matchingWorks.isEmpty {
                            Text(language.text(.noResults)).foregroundStyle(.secondary)
                        }
                        Section { Text(language.text(.catalogUpdated) + " " + catalog.generated + ". Marxists Internet Archive.").font(.footnote).foregroundStyle(.secondary) }
                    }
                    .searchable(text: $query, prompt: language.text(.search))
                } else if error {
                    ContentUnavailableView(language.text(.catalogUnavailable), systemImage: "books.vertical", description: Text(language.text(.catalogError)))
                } else { ProgressView() }
            }
            .navigationTitle(language.text(.appName))
            .tint(DesignTokens.accent)
            .task(id: languageCode) {
                query = ""
                do { catalog = try Catalog.load(language); error = false } catch { catalog = nil; self.error = true }
            }
        }
    }
}

struct AuthorView: View {
    let author: Author
    let language: Language
    var body: some View {
        List {
            Section {
                Text(author.full).font(.title2.bold())
                if !author.dates.isEmpty { Text(author.dates).foregroundStyle(.secondary) }
                if !author.bio.isEmpty { Text(author.bio).font(.body) }
            }
            ForEach(Array(author.sections.enumerated()), id: \.offset) { index, section in
                let works = author.works.filter { $0.section == index }
                if !works.isEmpty {
                    Section(section.isEmpty ? language.text(.works) : section) {
                        ForEach(works) { work in
                            NavigationLink { ReaderView(work: work, language: language) } label: {
                                ListRow(title: work.title, subtitle: work.date)
                            }
                        }
                    }
                }
            }
        }.navigationTitle(author.name).navigationBarTitleDisplayMode(.inline)
    }
}

struct ReaderView: View {
    let work: Work
    let language: Language
    @State private var html: String?
    @State private var failed = false
    private var sourceURL: URL? { URL(string: work.path, relativeTo: URL(string: language.base))?.absoluteURL }
    var body: some View {
        Group {
            if let sourceURL, work.path.lowercased().split(separator: "#").first?.hasSuffix(".pdf") == true {
                VStack(spacing: DesignTokens.Spacing.standard) { Text(language.text(.pdfDescription)); Link(language.text(.openPDF), destination: sourceURL) }
            } else if let html, let sourceURL {
                ReaderWebView(html: html, sourceURL: sourceURL)
            } else if failed {
                ContentUnavailableView {
                    Label(language.text(.loadError), systemImage: "wifi.slash")
                } description: {
                    Text(language.text(.connectionError))
                } actions: { Button(language.text(.retry)) { Task { await load() } } }
            } else { ProgressView(language.text(.loading)) }
        }
        .navigationTitle(work.title).navigationBarTitleDisplayMode(.inline)
        .toolbar { if let sourceURL { ToolbarItem(placement: .primaryAction) { Link(destination: sourceURL) { Image(systemName: "safari") }.accessibilityLabel(language.text(.openSource)) } } }
        .task(id: work.path + language.rawValue) { await load() }
    }
    private func load() async {
        guard let sourceURL, sourceURL.host == "www.marxists.org" else { failed = true; return }
        failed = false
        do { html = try await PageStore.load(sourceURL) } catch { failed = true }
    }
}

enum PageStore {
    static func load(_ url: URL) async throws -> String {
        let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("ArchivePages", isDirectory: true)
        let key = SHA256.hash(data: Data(url.absoluteString.utf8)).map { String(format: "%02x", $0) }.joined()
        let file = directory.appendingPathComponent(key)
        if let data = try? Data(contentsOf: file), let text = String(data: data, encoding: .utf8) { return text }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode), http.url?.host == "www.marxists.org" else { throw URLError(.badServerResponse) }
        guard let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .windowsCP1252) else { throw URLError(.cannotDecodeContentData) }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? text.data(using: .utf8)?.write(to: file, options: .atomic)
        return text
    }
}

struct ReaderWebView: UIViewRepresentable {
    let html: String
    let sourceURL: URL
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = false
        configuration.userContentController.addUserScript(WKUserScript(source: Self.cleanup, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.isOpaque = false
        view.backgroundColor = .systemBackground
        view.scrollView.backgroundColor = .systemBackground
        view.loadHTMLString(html, baseURL: sourceURL)
        return view
    }
    func updateUIView(_ view: WKWebView, context: Context) {}
    static let cleanup = """
    document.querySelectorAll('script,style,link,meta,iframe,form,input,button,select,noscript,object,embed,map,.toplink,.toplink-centro,img.logo,img.logodic,nav,p.title').forEach(e => e.remove());
    document.querySelectorAll('*').forEach(e => { for (const a of [...e.attributes]) { if (a.name.toLowerCase().startsWith('on') || ['style','align','bgcolor','color','face','size','background','border','cellpadding','cellspacing','valign','width','height'].includes(a.name.toLowerCase())) e.removeAttribute(a.name); } });
    const style = document.createElement('style'); style.textContent = `\(DesignTokens.Reader.stylesheet)`; document.head.appendChild(style);
    const viewport = document.createElement('meta'); viewport.name = 'viewport'; viewport.content = 'width=device-width, initial-scale=1'; document.head.appendChild(viewport);
    """
}
