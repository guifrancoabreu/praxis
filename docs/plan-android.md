# Praxis no Android — plano de implementação

Como levar o Praxis (hoje SwiftUI, `ios/`) para o Android com o **mesmo visual**, **no mesmo
repositório**, e publicar na Play Store.

## 1. Objetivo

- App Android nativo em Kotlin + Jetpack Compose, em `android/`, ao lado de `ios/`.
- Paridade visual e funcional completa na primeira versão — o iOS é a especificação.
- **Uma fonte de verdade por artefato visual**: catálogo, tokens, CSS/JS do leitor, chaves de
  armazenamento e temas não são duplicados à mão; são compartilhados ou verificados por teste.
- O app iOS não é reescrito nem quebrado.

Escopo herdado que simplifica muito: o app é **portrait-only**, tem **uma pilha de navegação**
(sem abas), **não tem login, onboarding, tela de ajustes, compartilhamento nem compras**.

## 2. Decisões fechadas

| Decisão | Escolha | Consequência |
|---|---|---|
| Plataforma | Kotlin + Compose em `android/` | Duas UIs; nenhuma reescrita no iOS; paridade ancorada em tokens + leitor compartilhado |
| Escopo v1 | Paridade completa (todas as telas, leitor com 6 temas + custom, PDF) | v1 é release |
| Distribuição | Play Store desde o início | Assinatura, AAB, Data safety, ficha PT-BR, teste interno |
| Descartados | Compose Multiplatform, Flutter, React Native | Reescreveriam a UI iOS existente e perderiam SwiftUI/WebKit nativos |
| minSdk / target | 26 / 36 | WebView moderno; Play exige target recente; `PdfRenderer` e ML Kit ok |
| Leitor | `android.webkit.WebView` + CSS/JS compartilhados | Mesma tipografia, cores e temas do iOS |
| Módulos Gradle | Módulo único `app`, pacotes por camada | Menos cerimônia; extrair `core:*` só quando doer |
| `applicationId` | `br.praxis.android` (espelha o bundle `br.praxis.ios`) | Confirmar antes do primeiro upload — não muda depois |
| Analytics | TelemetryDeck Kotlin SDK 7.3.1, mesmo App ID do iOS, plano gratuito | Um dashboard para as duas plataformas, mesmos nomes de evento, sem custo |
| Tipografia | Noto Serif (serifa do sistema no Android) | Sem fonte empacotada; `design/fonts/` fica vazio |
| Idiomas | Release PT-only, estrutura i18n pronta | `values/` em português e só `catalog-pt.json` no APK; `values-en/`, `values-es/` e os outros catálogos entram quando o release abrir |
| Dispositivos | Só telefone, retrato | Sem capturas nem testes de tablet; excluir tablet no catálogo da Play |
| App anterior | Nenhuma relação com o "Leitor Marxista" | Ficha, ícone e package novos; sem migração de dados |

## 3. Estrutura do repositório (depois)

```text
shared/
  catalog/     catalog-pt.json  catalog-en.json  catalog-es.json    ← vindos de ios/Praxis/Resources
  reader/      reader.css  reader.js  reader-themes.json            ← CSS/JS injetados no WebView
  specs/       storage-keys.md  reader-bridge.md  app-identity.md
design/
  tokens.json  fonte de verdade: cores, spacing, radius, opacidade, sombra, tipografia
  fonts/       vazio por enquanto (Noto Serif do sistema); só entra fonte se a paridade exigir
android/
  settings.gradle.kts  build.gradle.kts  gradle/libs.versions.toml  gradlew
  app/src/main/kotlin/br/praxis/android/
    data/      catalog, history, storage, pagecache, portraitcache, network
    design/    Tokens.kt (gerado), PraxisTheme, componentes
    ui/        library, author, collection, reader, appearance, support, privacy
    platform/  webview bridge, pdf, face detection, links
  app/src/main/res/     strings (pt agora; en/es quando o release abrir), drawable, ícone adaptativo
  app/src/test/         paridade de catálogo, histórico, cache, links, temas
  app/src/androidTest/  fluxos de navegação
ios/                    inalterado, exceto caminhos dos recursos
tools/                  inalterado; build_catalog*.py passam a escrever em shared/catalog
.github/workflows/      android.yml  ios.yml  shared-checks.yml
```

Sem cópia no build: Gradle usa `assets.srcDirs += "../../shared/catalog"` e o Xcode referencia
`../shared/catalog/*.json`.

## 4. Fases

### Fase 0 — Estrutura e conteúdo compartilhado (1–2 dias)

1. `android/` com Gradle wrapper, version catalog, Compose BOM, `minSdk 26`, `targetSdk 36`,
   Gradle 9.5 / AGP 9.2.1 / Kotlin 2.3.21 (exigidos pelo SDK do TelemetryDeck), tema base e um app
   que roda no emulador (JDK 21; o `Pixel_10` já existe na máquina).
2. Mover `ios/Praxis/Resources/catalog-*.json` → `shared/catalog/`, ajustar as 3 entradas do
   `project.pbxproj` e `tools/build_catalog*.py`. **PR isolado**, verificado com build iOS.
3. Extrair o leitor para `shared/reader/` — todo o JS hoje embutido em Swift:
   - sanitização do HTML do arquivo (preservar âncoras de `<nav>` via marcadores; remover
     `script/style/link/meta/iframe/form/...`, `.toplink`, `.logo`, `nav`, `p.title`; limpar atributos
     de estilo e `on*`; lazy-load a partir da 3ª imagem);
   - `setReaderAppearance` + mapa de fontes (`serif/sans/book/condensed/mono/casual`);
   - `<base href>` para links relativos (hoje `ReaderHTML.withBaseURL`);
   - progresso de scroll (timer 500 ms + flush em `scrollend`/`pagehide`);
   - interceptação de links (`readerLink`) e rolagem para âncora (`#` → topo).
   O CSS ativo é o bloco injetado com variáveis (`--reader-bg/ink/link/size/line/margin/align/font`,
   `max-width:40rem`, `padding:26px var(--reader-margin) 64px`).
   ⚠️ `ReaderTokens.stylesheet` em `DesignSystem.swift:11-24` é **legado não usado** — não portar.
4. `design/tokens.json` a partir de `RefTokens`/`SystemTokens` + `tools/gen_tokens.py` que emite
   `Tokens.kt` e falha com `--check` se divergir.
5. `shared/specs/`: chaves de armazenamento e formatos JSON, contrato da bridge do leitor,
   identidade do app (applicationId, URLs de suporte e privacidade).
6. **Copy em recursos desde o primeiro dia**: `res/values/strings.xml` com todas as chaves em
   português e um equivalente ao `ReleasePolicy.isPortugueseOnly` do iOS, que esconde a troca de
   idioma e força o catálogo PT. Nada de texto inline em Composable — quando EN/ES entrarem, é só
   adicionar `values-en/` e `values-es/` e virar a flag. Isso melhora o que o iOS tem hoje (PT e EN
   inline no código, ES num dicionário): no Android a copy nasce única e testável.

Aceite: `swift test --package-path ios` verde, app iOS builda, `./gradlew assembleDebug` builda,
`tools/gen_tokens.py --check` verde.

### Fase 1 — Núcleo de dados (3–4 dias)

Portar `Catalog.swift` com os testes do iOS como especificação.

- **Parsing tolerante**: o iOS lê JSON à mão (`[String: Any]`) e ignora campo ausente/linha inválida.
  Em Kotlin, `JsonElement` manual — decodificação estrita quebra com o catálogo real.
- Conteúdo: PT 510 autores / 7.483 obras / 21 temas / 4.125 figuras; EN 645 / 69 temas / 32 coleções
  de história / 2.504 figuras; ES 12 autores. `history` só existe no EN; ES não tem `themes/figures`.
- Normalização do PT: `separateMarxAndEngels` (Marx e Engels vêm agrupados) + atalhos de retrato
  `marx`/`engels` no EN.
- Busca e ordenação: `LibraryFilter` (10 valores), `CatalogSort` (popularidade/A-Z/Z-A/data),
  ranking editorial curado por idioma, primeiro ano por regex `\d{3,4}`.
  ⚠️ `localizedStandardContains`/`localizedStandardCompare` são insensíveis a caixa, acento e
  largura e numéricos → `java.text.Collator` (PRIMARY) + comparação numérica. `contains` ingênuo
  muda os resultados em português.
- `ReadingHistory` — o trecho de maior risco: `canonicalKey` (remove fragmento, normaliza host),
  `isSameWork`, diretórios genéricos excluídos (`ano/mes/month/works/archive/texts/images/cw/...`
  e nomes numéricos), agrupamento por obra (`grouped`), migração de entradas antigas (`migrated`),
  resolução de crédito (`Catalog.credit` + `AuthorCreditName.display`). Portar
  `ReadingHistoryTests.swift` linha a linha: divergência aqui corrompe "continuar lendo".
- Cache: `PageCache` (`filesDir/OfflinePages`, nome = SHA-256 hex da URL, `.pdf` no PDF, limite
  **100 MB** removendo os mais antigos por mtime) e `PortraitCache` (`cacheDir/Portraits`, TTL 30 dias).
- Rede: OkHttp com validação 2xx + host `www.marxists.org`; HTML decodifica UTF-8 e cai para
  **windows-1252/ISO-8859-1** (páginas antigas do arquivo).
- Armazenamento: DataStore Preferences com as mesmas chaves e os mesmos JSONs (ver §6).

Aceite: testes JVM cobrindo os casos de `ios/Tests`; abrir o catálogo PT real e comparar contagens,
ordenações e resultados de busca com o app iOS.

### Fase 2 — Design system Compose (3–4 dias)

- `Tokens.kt` → `PraxisTheme` claro/escuro com os hex de §6, spacing 4 pt→dp, radii, opacidade, sombra.
- Tipografia: escalas equivalentes aos text styles em uso (largeTitle, title2, headline, subheadline,
  caption) em `sp` (respeita a fonte do sistema), **Noto Serif** para títulos e capas, sans do sistema
  (Roboto) para chrome. Sem fonte empacotada: a diferença de desenho em relação ao New York do iOS é
  aceita e registrada como divergência de plataforma.
- Componentes: `BookCover` (tom determinístico pelo hash do título entre 4 cores, régua branca a 72%
  de opacidade, imprint "MIA", raio 8, sombra 4/2), `ListRow`, cabeçalho de seção em caixa alta com
  "Ver todos", `ContinueReadingCard` (236 de largura, capa 64×86, 2 linhas, barra de progresso,
  legenda "% nesta seção"), `WorkListRow` (capa 50×68 + ano + chevron), `AuthorArtwork` (92×112 ou
  48×54, recorte focal pelo rosto, monograma serif de fallback), chips de filtro com memória de
  scroll (`FilterBarSelection`), superfície translúcida tipo vidro, divisor com inset, `EmptyState`.
- `AuthorArtwork`: ML Kit Face Detection no lugar de Vision; mesmo recorte com ponto focal preso às
  bordas, `engels` forçado no topo, mesma prioridade `photo` → `avatar` → caso especial `archive/marx`.
- Ícones: SF Symbols usados são poucos (`chevron.right`, `magnifyingglass`, `globe`, `bookmark`,
  `bookmark.fill`, `safari`, `textformat.size`, `heart`, `heart.text.square`, `books.vertical`,
  `arrow.up.right`, `wifi.slash`, `xmark.circle.fill`, `cup.and.saucer.fill`) → Material Symbols
  ou vetores próprios.

Aceite: tela de componentes ao lado do app iOS; divergência só onde o SO difere.

### Fase 3 — Biblioteca (4–5 dias)

`LibraryView` completa, na mesma ordem: título serif grande + subtítulo do arquivo + botão de idioma
(oculto no release PT), barra de filtros, "Continue lendo" (ou cartão "Bom lugar para começar",
rotativo por dia), "Autores populares", "Salvos", "Biblioteca", rodapé de atribuição
(data de geração + MIA), cartão de apoio e link da política; campo de busca flutuante ancorado no
rodapé; estados de carregando e de erro.

- **Chips que existem de fato**: Tudo, Salvos, Histórico, Autores, Textos e Temas (e História, quando
  o catálogo tem `history` — no PT não tem). `figures`, `countries` e `popular` têm código no iOS mas
  **nenhum chip**: não construir UI nova para eles; a busca cobre "Figuras históricas" e "Países".
- Busca local no catálogo: autores por nome/nome completo/país/movimentos; textos no título (limite
  **100**); temas/história por título ou grupo; figuras (limite **80**, com "Somente pessoas");
  países distintos. Com filtro "Tudo", resultados em seções + "Nada encontrado".
- Ordenação com menu (marcar atual; escolher A-Z/Z-A/data desliga o agrupamento por movimento),
  agrupamento por movimento com "Outros", toggle "A–Z"/"Movimentos".
- Salvos: JSON de caminhos, inserção no topo, remoção por caminho exato.
- Consentimento de analytics: alerta no primeiro carregamento do catálogo (mesmo texto, mesmas
  opções, "Não compartilhar" como ação neutra), e o SDK **só é inicializado depois do consentimento**
  — antes disso nada sai do aparelho. Toggle correspondente na tela de privacidade.

Aceite: cada chip navega e filtra igual; busca devolve os mesmos resultados e limites; progresso e
"continuar lendo" batem com o iOS com o mesmo histórico importado.

### Fase 4 — Leitor (5–6 dias)

- `WebView`: conteúdo carregado do cache com `loadDataWithBaseURL`, CSS/JS de `shared/reader/`.
- **Bridge**: dois canais, mesmo contrato — `readerProgress` (Double 0…1) e `readerLink`
  (`{url, title}`). No Android, `addJavascriptInterface`/`WebMessageListener` no lugar de
  `window.webkit.messageHandlers`.
- **Gotchas obrigatórios** (o iOS usa `allowsContentJavaScript = false` com user script injetado;
  no Android, `javaScriptEnabled = false` também bloqueia o script injetado):
  - habilitar JS e injetar o script próprio no `onPageFinished`, com flag de idempotência; ou
    usar `WebViewCompat.addDocumentStartJavaScript` (androidx.webkit) para rodar antes da página;
  - `loadDataWithBaseURL` muda a origem do documento: revalidar links relativos, imagens, âncoras
    `#` e o `<base href>` separadamente;
  - `scrollend` existe em Chrome/WebView recentes, mas manter o fallback por timer;
  - `-webkit-text-size-adjust`, `system-ui`, Georgia/Palatino/Comic Sans não são as mesmas fontes.
- Restauração de posição: fragmento quando existir, senão fração de scroll; tentar em ~120 ms,
  350 ms e 1 s após o load (como no iOS).
- Progresso: fração `scrollY/(scrollHeight-innerHeight)`, debounce de **5 s** com flush ao sair,
  ao ir para segundo plano e ao dar `pagehide`.
- Sanitização visual do HTML do arquivo (mesma passada do iOS) — é o que faz a página parecer app.
- Tela de aparência: fonte (serif/sans/book/condensed/mono/casual), tamanho 13–34, entrelinha
  1.2–2.4, margem 8–48, alinhamento esquerda/justificado, 6 temas + cores livres com razão de
  contraste WCAG exibida (AA/AAA) e "Restaurar padrão".
- PDF: `PdfRenderer` + visualizador Compose paginado com zoom; recriar o renderer na mudança de
  configuração; progresso por página; aparência oculta; marcador e link da fonte mantidos.

Aceite: abrir "Teses sobre Feuerbach" e um PDF; percorrer os 6 temas e as cores custom contra o iOS;
sair e voltar retomando a posição; ler offline um texto já aberto.

### Fase 5 — Telas secundárias (2–3 dias)

`AuthorView` (cartão com retrato, nome, datas, país, chips de movimento, bio de 5 linhas + "Ler mais",
"Biografia completa", seções de obras), `CountryWritersView`, `CollectionDetailView` (grupos; fallback
"Abrir no arquivo"), `SupportView` (Ko-fi e doação ao MIA), `PrivacyPolicyView` (textos pt/en/es já
existem), `ReaderAppearanceView`.

### Fase 6 — Paridade e polimento (3 dias)

- Capturas lado a lado (iPhone + emulador) de todas as telas em claro e escuro; checklist por tela.
- Acessibilidade: TalkBack, `fontScale` 1.3 e 2.0, alvos ≥48 dp, contraste, ordem de foco,
  rótulos em todo controle só de ícone.
- Edge-to-edge obrigatório com target 35+: insets equivalentes às safe areas do iOS (busca flutuante,
  barra do leitor, PDF).
- Rotação travada em retrato (como o iOS), baseline profile + R8.
- Testes visuais (Paparazzi ou Roborazzi) para travar regressões de layout.

### Fase 7 — Play Store (2–3 dias)

- Play App Signing; keystore de upload fora do repo; AAB com R8 + baseline profile; `versionCode`/
  `versionName` alinhados ao iOS.
- Ficha PT-BR adaptada de `docs/app-store-listing-pt-BR.md`; ícone 512×512 de `Praxis-logo.png`;
  feature graphic 1024×500; capturas só de telefone.
- Categoria Livros e referência; classificação IARC; público-alvo; anúncios: nenhum.
- Telefone apenas: excluir tablets no catálogo de dispositivos da Play em vez de publicar telas
  não verificadas.
- **Data safety**: com TelemetryDeck entra "atividade no app / interações" (opcional, cifrado em
  trânsito, processado na UE). Ajustar os *providers* de ambiente do SDK ao allowlist do iOS —
  desligar região, configurações de acessibilidade e identificadores — para a declaração ficar
  enxuta e verdadeira. Eventos continuam sem título, autor, busca ou posição de leitura.
- Política de privacidade e página de suporte atualizadas para Android no mesmo domínio (a política
  já descreve o TelemetryDeck e o consentimento; so precisa deixar de citar só iPhone/iOS).
- Teste interno com o build de produção e depois produção.

### CI/CD (a partir da Fase 0)

Hoje não existe workflow no repo; os três passam a existir junto com `android/`:

- `android.yml` (ubuntu): JDK 21, cache do Gradle, `assembleDebug`, `testDebugUnitTest`, `lint`,
  ktlint/detekt, artefato APK; em tag, gera AAB assinado e publica na faixa de teste interno.
- `ios.yml` (macos): `swift test --package-path ios` + `xcodebuild build` sem assinatura — existe
  para pegar quebras causadas pelo move dos catálogos para `shared/`.
- `shared-checks.yml`: `tools/gen_tokens.py --check`, validação do esquema do catálogo, hash do
  CSS/JS do leitor e checagem de chaves de string.

## 5. Inventário de paridade (o que construir)

| Tela | Conteúdo | Notas de paridade |
|---|---|---|
| Biblioteca | título+subtítulo+idioma, chips, continue lendo/começar, autores populares, salvos, biblioteca, rodapé de atribuição, apoio, política, busca flutuante | ordem das seções e espaçamentos iguais; alerta de analytics no 1º load |
| Autor | cartão com retrato/bio 5 linhas/Ler mais, biografia completa, seções de obras | título inline, bio expandível |
| País | lista de autores do país | 48×54 + nome + datas ou contagem |
| Coleção | grupos de obras, fallback "Abrir no arquivo" | subcabeçalhos serif |
| Leitor | conteúdo sanitizado, barra com voltar/Aa/marcador/fonte, aparência, PDF | 6 temas + custom, progresso por página |
| Aparência | fonte, tamanho, entrelinha, margem, alinhamento, temas, cores, contraste, restaurar | sheet medium/large no iOS → bottom sheet |
| Apoio | Ko-fi, doação ao MIA | ícones circulares + "abrir externo" |
| Privacidade | seções legais + toggle de consentimento | textos já traduzidos |

## 6. Contratos compartilhados

**Chaves de armazenamento** (mesmos nomes e formatos): `language`, `savedWorkPaths` (JSON de caminhos,
mais novo primeiro), `recentReadings` (JSON de `ReadingProgress`), `catalogSortOrder`,
`groupWritersByMovement`, `glossaryPeopleOnly`, `readerAppearance` (JSON), `analyticsConsent`,
`analyticsPromptAnswered`.

**`ReadingProgress`**: `{path, title, author, progress: 0…1, workID?}` — `title/author/progress`
tolerantes na leitura, `workID` agrupa páginas de uma obra.

**`ReaderAppearance`**: `{font, size, lineSpacing, margin, alignment, theme, background, foreground, link}`.

**Temas do leitor** (fundo / texto / link): light `#fbfaf7/#1d1b19/#b3121d`,
sepia `#f4ecd8/#3b2f22/#9c2a12`, gray `#d9d9d6/#202020/#8e0d16`,
dark `#1c1c1e/#dedede/#ff8a80`, black `#000000/#c9c9c9/#ff6e6e`,
red `#4a0808/#fbe9d0/#ffcc00`.

**Tokens semânticos** (claro → escuro): accent `#940008` → `#FF7A7A`; background `#FBFAF7` → `#1A1816`;
surface `#FFFEFC` → `#262320`; secondarySurface `#E8E3D9` → `#33302B`; textPrimary = rótulo do sistema
nos dois; textSecondary `#524D47` → secundário do sistema; separator = separator do sistema a 45%;
capas `#8A5C26`, `#85382E`, `#4D593D`, `#365768`, pedra `#E8DECC` → `#302B26`.

## 7. Mapa iOS → Android

| iOS | Android |
|---|---|
| `NavigationStack` / sheet | Navigation Compose / `ModalBottomSheet` |
| `@AppStorage` / `UserDefaults` | DataStore Preferences |
| `WKWebView` + `WKScriptMessageHandler` | `WebView` + `WebMessageListener`/`JavascriptInterface` |
| `PDFKit.PDFView` | `PdfRenderer` + visualizador Compose |
| Vision face detection | ML Kit Face Detection |
| `CryptoKit.SHA256` | `MessageDigest("SHA-256")` |
| `URLSession` / `AsyncImage` | OkHttp / Coil |
| SF Symbols | Material Symbols / vetores próprios |
| Dynamic Type / VoiceOver | `sp` + `fontScale` / TalkBack |
| `glassEffect` com fallback `Material` | superfície tonal translúcida (`RenderEffect` 31+) |
| TelemetryDeck (iOS) | TelemetryDeck Kotlin SDK, mesmo App ID |
| `ContentUnavailableView`, `List`+`Section`, `Picker` segmented | Compose vazio/erro, `LazyColumn`, `SingleChoiceSegmentedButtonRow` |

## 8. Analytics e privacidade

**Escolha**: TelemetryDeck Kotlin SDK 7.3.1, com o **mesmo App ID** (`27BA9D21-…`) já usado no iOS e
o plano gratuito. Um dashboard para as duas plataformas, sem custo inicial e sem Firebase/Google
Play Services no pacote.

- Nomes de evento idênticos ao allowlist do iOS: `Library.Filter.Selected`, `Library.Search.Used`,
  `Library.AuthorProfile.Opened`, `Reader.Work.Opened`, `Reader.Bookmark.Changed`,
  `Reader.Appearance.Opened`, `Reader.ArchiveSource.Opened`, `Support.Page.Opened`,
  `Support.Destination.Opened`. E os mesmos parâmetros — nunca título, autor, busca ou posição.
- **Consentimento primeiro**: o SDK só é inicializado depois de "Compartilhar dados de uso" e para
  quando o toggle da tela de privacidade é desligado. Antes disso, nada sai do aparelho.
- **Providers de ambiente**: o SDK manda por padrão modelo do aparelho, build, densidade e resolução
  de tela, região (ISO), fuso, locale e preferências de acessibilidade. O iOS não manda nada disso.
  Configurar os providers para ficar equivalente ao iOS — é o que mantém a declaração da Play enxuta
  e verdadeira.
- Requisitos do SDK: API 23+, Kotlin 2.3.21, Gradle 9.5, AGP 9.2.1. O scaffold da Fase 0 nasce nessa
  linha, com JDK 21 no CI; conferir na primeira build se o AGP 9 exige algo além disso.
- Play **Data safety**: "atividade no app / interações no app", opcional, cifrado em trânsito,
  processado na UE. Com os providers de região desligados, não há localização aproximada a declarar;
  sem ID de publicidade, sem identificadores do aparelho.
- ML Kit Face Detection roda on-device e não envia nada — entra no texto da política, não no formulário.
- O tráfego para `www.marxists.org` é pedido do usuário, não coleta do desenvolvedor — mas continua
  descrito na política.
- Mesma atribuição de conteúdo do iOS (MIA e tradutores) e a mesma nota para a revisão.
- Publicação: ver Fase 7.

## 9. Riscos

| Risco | Mitigação |
|---|---|
| Duas UIs divergirem | tokens gerados com `--check`, CSS/JS compartilhados, teste de paridade no CI |
| `ReadingHistory` portado errado | portar `ReadingHistoryTests.swift` 1:1 antes de qualquer UI |
| Bridge do WebView se comportar diferente | validar links, âncoras, imagens e progresso em página real de cada seção do arquivo |
| Serifa (New York × Noto Serif) | aceitar Noto Serif na v1; se incomodar, empacotar uma família em `design/fonts/` |
| Vidro/blur sem equivalente | superfície tonal + borda; conferir em API 26–30 |
| HTML sujo do MIA e encoding latin-1 | mesmo pipeline de sanitização e decode; fixtures reais nos testes |
| ~6 MB de catálogo no pacote | assets comprimidos no AAB; R8; sem imagens empacotadas |
| Manutenção dupla | Fases 0–1 entregam a base compartilhada; mudança de catálogo/token passa a ser uma edição |
| SDK do TelemetryDeck exigir toolchain muito nova (Gradle 9.5 / AGP 9.2.1 / Kotlin 2.3.21) | Fase 0 fixa essas versões desde o primeiro commit; se travar, usar o SDK 6.3.x (mesma API de eventos) e atualizar depois |

## 10. Esforço

**~24–31 dias de trabalho focado** até o AAB na faixa de teste interno. Críticos: Fase 1 (histórico e
créditos) e Fase 4 (leitor).

## 11. Não portar

Código morto do iOS que não deve virar trabalho no Android: chips `figures`/`countries`/`popular`
(sem entrada na UI), `SupportDestination.volunteer` (sem tela), `ReaderTokens.stylesheet` (legado),
catálogo ES com `works: []`, e a troca de idioma enquanto `ReleasePolicy.isPortugueseOnly` for true.

## 12. Pendências

1. **`applicationId`**: confirmei como `br.praxis.android` (espelho de `br.praxis.ios`). Se a intenção
   era usar literalmente `br.praxis.ios` no Android, é a última chance de dizer — depois do primeiro
   upload na Play não muda.
2. Verificar no dashboard da TelemetryDeck que sinais Android e iOS do mesmo App ID aparecem
   separados por plataforma antes de publicar.
3. Revisar o texto da política de privacidade para não falar só de iPhone/iOS.
