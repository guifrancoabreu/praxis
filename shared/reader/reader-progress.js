// Keeps scroll reports cheap: one message per 500 ms while scrolling, plus a forced flush when
// scrolling ends or the page goes away. Calls report(), which the document script defines.
let progressTimer = null;
const scheduleReport = () => { if (progressTimer === null) progressTimer = setTimeout(() => { progressTimer = null; report(); }, 500); };
const flushReport = () => { if (progressTimer !== null) { clearTimeout(progressTimer); progressTimer = null; report(); } };
window.addEventListener('scroll', scheduleReport, { passive: true });
window.addEventListener('scrollend', flushReport);
window.addEventListener('pagehide', flushReport);
