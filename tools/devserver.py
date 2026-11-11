"""Servidor de teste no computador: serve a pasta www/ e repassa /mia/... ao marxists.org.

No celular (APK) o app busca os textos direto no site; no navegador do computador
isso é bloqueado (CORS), por isso este servidor faz o papel de intermediário.

Uso:  python tools/devserver.py [porta]   ->  http://localhost:8765
"""
import hashlib
import http.server
import os
import sys
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WWW = os.path.join(ROOT, "www")
CACHE = os.path.join(ROOT, "tools", ".cache-proxy")
PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8765


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *a, **kw):
        super().__init__(*a, directory=WWW, **kw)

    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def do_GET(self):
        if not self.path.startswith("/mia/"):
            return super().do_GET()
        path = self.path[len("/mia/"):].split("#")[0]
        if ".." in path:
            return self.send_error(400)
        fn = os.path.join(CACHE, hashlib.md5(path.encode()).hexdigest())
        try:
            if os.path.exists(fn):
                with open(fn, "rb") as f:
                    body = f.read()
            else:
                req = urllib.request.Request(
                    "https://www.marxists.org/" + path,
                    headers={"User-Agent": "LeitorMarxista-dev/1.0"},
                )
                body = urllib.request.urlopen(req, timeout=40).read()
                os.makedirs(CACHE, exist_ok=True)
                with open(fn, "wb") as f:
                    f.write(body)
        except Exception as e:
            return self.send_error(502, str(e))
        ctype = "application/octet-stream"
        low = path.lower()
        for ext, ct in ((".htm", "text/html"), (".jpg", "image/jpeg"), (".jpeg", "image/jpeg"),
                        (".png", "image/png"), (".gif", "image/gif"), (".webp", "image/webp"),
                        (".pdf", "application/pdf")):
            if low.endswith(ext) or ext + "#" in low:
                ctype = ct
        self.send_response(200)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


if __name__ == "__main__":
    print(f"Leitor Marxista: http://localhost:{PORT}")
    http.server.ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
