// Idioma do app. Nos APKs este arquivo é reescrito por tools/preparar.py.
// No computador dá para testar o inglês com http://localhost:8765/?lang=en
window.APP_CONFIG = { lang: new URLSearchParams(location.search).get('lang') || 'pt' };
