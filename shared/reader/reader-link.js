// Turns archive links into reader navigation.
//
// Same-document fragments scroll inside the page; everything else is handed to the host through
// __praxisHost.link(url, title), which decides between the archive, an external browser and an
// unsupported destination. The host shim is the only platform-specific part.
const scrollToReaderAnchor = (fragment) => {
    let id; try { id = decodeURIComponent(fragment); } catch (_) { id = fragment; }
    if (!id || id.toLowerCase() === 'top') { window.scrollTo(0, 0); return true; }
    const target = document.getElementById(id) || document.getElementsByName(id)[0];
    if (!target) return false;
    target.scrollIntoView(); return true;
};
document.addEventListener('click', event => {
    const link = event.target.closest && event.target.closest('a[href]');
    if (!link) return;
    const href = link.getAttribute('href');
    if (href === '#') { event.preventDefault(); window.scrollTo(0, 0); return; }
    let destination, source;
    try { destination = new URL(href, sourceURL); source = new URL(sourceURL); } catch (_) { return; }
    if (destination.hash && destination.origin === source.origin && destination.pathname === source.pathname && destination.search === source.search) {
        event.preventDefault(); scrollToReaderAnchor(destination.hash.slice(1)); return;
    }
    event.preventDefault();
    window.__praxisHost.link(destination.href, (link.textContent || '').trim());
});
