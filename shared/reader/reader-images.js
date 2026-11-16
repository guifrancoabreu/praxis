// Loads everything below the fold lazily and decodes asynchronously.
// The first two images are usually part of the work's masthead, so they load eagerly.
document.querySelectorAll('img').forEach((img, i) => { if (i >= 2) img.loading = 'lazy'; img.decoding = 'async'; });
