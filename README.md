# Leitor Marxista · Marxist Reader

Aplicativos Android para ler o **Arquivo Marxista na Internet** ([marxists.org](https://www.marxists.org)).
Android apps for reading the **Marxists Internet Archive**.

| App | Idioma | Organização |
|---|---|---|
| **Leitor Marxista** | Português ([marxists.org/portugues](https://www.marxists.org/portugues/)) | Autores · Países · Temas · Figuras históricas |
| **Marxist Reader** | English ([marxists.org](https://www.marxists.org/archive/index.htm)) | Writers (by movement) · History · Subjects · Glossary of People |

**Baixe os APKs na aba [Releases](../../releases).** · **Download the APKs from [Releases](../../releases).**

## Recursos / Features

- Texto limpo, sem os menus do site — clean text, without site navigation
- Fonte, tamanho da letra, cores (6 temas + cores livres), espaçamento, margens e alinhamento
  — font, size, colours (6 themes + custom), line spacing, margins, alignment
- Busca, favoritos, histórico, "continuar lendo" e leitura offline dos textos já abertos
  — search, favourites, history, resume reading and offline reading of opened texts
- Aba **Apoie / Support** com QR Code Pix

## Instalar no Android

1. Baixe o `.apk` em Releases no celular.
2. Toque no arquivo e permita "instalar apps de fontes desconhecidas".
3. Toque em **Instalar**.

## Estrutura

```
www/                  app (HTML/CSS/JS), comum aos dois idiomas
  js/i18n.js          textos da interface (pt / en)
  data/catalog-*.json catálogos gerados a partir do site
apps/pt, apps/en      projetos Capacitor/Android de cada app
assets/               ícones (foice e martelo) para o Android
tools/
  build_catalog.py    catálogo em português
  build_catalog_en.py catálogo em inglês (segue a organização do site em inglês)
  preparar.py         copia www/ para apps/<idioma>/www com o idioma fixo
  devserver.py        servidor de teste no computador
  gerar_icones.py     gera os PNGs do ícone
```

## Testar no computador

```
python tools/devserver.py
```

Português: http://localhost:8765 · English: http://localhost:8765/?lang=en

## Gerar os APKs

Requisitos: Node.js 20+, Java 21, Android SDK 35, Python 3.

```
npm install
python tools/preparar.py pt en
cd apps/pt && npx cap sync android && cd android && gradlew.bat assembleDebug
cd ../../en && npx cap sync android && cd android && gradlew.bat assembleDebug
```

O APK sai em `apps/<idioma>/android/app/build/outputs/apk/debug/app-debug.apk`.
No Windows, se a pasta tiver caminho muito longo, use `subst L: "C:\caminho\do\projeto"` e trabalhe a partir de `L:\`.

## Atualizar os catálogos

```
python tools/build_catalog.py      # português
python tools/build_catalog_en.py   # English
```

## Sobre o conteúdo / About the content

Todos os textos pertencem ao Arquivo Marxista na Internet e a seus tradutores; o app apenas
os exibe, sempre com a fonte. A maior parte do acervo é distribuída sob licença Creative Commons
(Atribuição-CompartilhaIgual). Apoie o MIA: [marxists.org](https://www.marxists.org/admin/volunteers/index.htm).

All texts belong to the Marxists Internet Archive and its translators; this app only displays
them, always linking to the source.
