# Shared reader assets

The archive reader is a web view on both platforms: the app fetches a page from
`www.marxists.org`, strips the archive's own chrome, and paints it with these files. Keeping them
here is what makes the reading surface identical on iOS and Android.

| File | Role |
|---|---|
| `reader.css` | Reading surface, driven by the custom properties `setReaderAppearance()` writes |
| `reader.js` | Document script: sanitizing, stylesheet injection, appearance, scroll restore |
| `reader-link.js` | Turns archive links into host calls, keeps in-page anchors scrolling |
| `reader-progress.js` | Throttles scroll reports and flushes them on `scrollend`/`pagehide` |
| `reader-images.js` | Lazy-loads images past the second one |

## Host contract

Before `reader.js` runs, the host defines:

```js
window.__praxisHost = {
  progress: (value) => { /* 0...1 */ },
  link: (url, title) => { /* navigation decision */ }
};
```

Everything else arrives through placeholder substitution in `reader.js` (`__READER_CSS__`,
`__INITIAL_APPEARANCE__`, `__SOURCE_URL__`, and so on); the header of that file lists them all.

- **iOS** builds `__praxisHost` over `window.webkit.messageHandlers.readerProgress/readerLink` and
  composes the script in `ReaderAssets.documentScript(...)`.
- **Android** will build it over `@JavascriptInterface` (or `WebMessageListener`) with the same two
  channel names.

The appearance object is the serialized form of `ReaderAppearance` (`font`, `size`, `lineSpacing`,
`margin`, `alignment`, `theme`, `background`, `foreground`, `link`). See
`shared/specs/reader-bridge.md` once the Android app lands.
