// Document script for the archive reader, shared by the iOS and Android apps.
//
// The host injects this file into every archive page after the document is ready, preceded by a
// host shim that defines __praxisHost.progress(value) and __praxisHost.link(url, title), and with
// the placeholders documented in README.md filled in: the stylesheet, the three sub-scripts, the
// initial appearance, the initial progress, the initial fragment and the source URL.
//
// Keep this file platform-neutral: anything that differs between iOS and Android belongs in the
// host shim or in the app, never here.

// The archive uses <nav> for its own table of contents. Anchor markers are preserved so in-page
// links and fragments keep resolving after the navigation is removed.
document.querySelectorAll('nav').forEach(nav => { nav.querySelectorAll('[id],a[name]').forEach(anchor => { const marker = document.createElement('span'); if (anchor.id) marker.id = anchor.id; if (anchor.getAttribute('name')) marker.setAttribute('name', anchor.getAttribute('name')); nav.before(marker); }); });
document.querySelectorAll('script,style,link,meta,iframe,form,input,button,select,noscript,object,embed,map,.toplink,.toplink-centro,img.logo,img.logodic,nav,p.title').forEach(e => e.remove());

// Archive markup carries presentational attributes that fight the reading surface.
const removedAttributes = new Set(['style','align','bgcolor','color','face','size','background','border','cellpadding','cellspacing','valign','width','height']);
document.querySelectorAll('*').forEach(e => { for (let i = e.attributes.length - 1; i >= 0; i--) { const name = e.attributes[i].name.toLowerCase(); if ((name === 'width' || name === 'height') && e.tagName === 'IMG') continue; if (name.startsWith('on') || removedAttributes.has(name)) e.removeAttribute(name); } });

__READER_IMAGES__

const style = document.createElement('style'); style.textContent = __READER_CSS__; document.head.appendChild(style);

window.setReaderAppearance = (p) => { const b=document.body; const fonts={serif:'Georgia, serif',sans:'system-ui, sans-serif',book:'Palatino, serif',condensed:'\"Arial Narrow\", sans-serif',mono:'monospace',casual:'\"Comic Sans MS\", cursive'}; b.style.setProperty('--reader-bg',p.background||'#fbfaf7'); b.style.setProperty('--reader-ink',p.foreground||'#1d1b19'); b.style.setProperty('--reader-link',p.link||'#b3121d'); b.style.setProperty('--reader-size',(p.size||19)+'px'); b.style.setProperty('--reader-line',p.lineSpacing||1.6); b.style.setProperty('--reader-margin',(p.margin||18)+'px'); b.style.setProperty('--reader-align',p.alignment==='justified'?'justify':'left'); b.style.setProperty('--reader-font',fonts[p.font]||fonts.serif); };
window.setReaderAppearance(__INITIAL_APPEARANCE__);

const initialProgress = __INITIAL_PROGRESS__;
const initialFragment = __INITIAL_FRAGMENT__;
const sourceURL = __SOURCE_URL__;

__READER_LINK__

// Progress is the share of the scroll range the reader has covered, not a share of the work.
const report = () => { const max = document.documentElement.scrollHeight - window.innerHeight; const progress = max > 0 ? Math.min(1, Math.max(0, window.scrollY / max)) : 0; window.__praxisHost.progress(progress); };
let restored = false;
const restore = () => { if (restored) return; const max = document.documentElement.scrollHeight - window.innerHeight; if (max > 0) { if (initialFragment !== null) scrollToReaderAnchor(initialFragment); else window.scrollTo(0, initialProgress * max); restored = true; report(); } };

__READER_PROGRESS__

// Images and fonts can settle late; retry the restore a few times before giving up.
window.addEventListener('load', () => setTimeout(restore, 120)); setTimeout(restore, 350); setTimeout(restore, 1000);

const viewport = document.createElement('meta'); viewport.name = 'viewport'; viewport.content = 'width=device-width, initial-scale=1'; document.head.appendChild(viewport);
