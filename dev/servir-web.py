# Serve o export web (../web-export/vagrant) na porta 8095 para o túnel da Cloudflare.
# Diferente do python -m http.server: manda o pacote .pck comprimido em gzip (31 -> 14 MB; a Cloudflare não comprime
# esse tipo) e põe ETag, então o celular revalida com 304 na segunda abertura em vez de baixar tudo de novo.
# Uso: python dev/servir-web.py [pasta] [porta]
import email.utils
import gzip
import hashlib
import http.server
import os
import sys

PASTA = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), "..", "..", "web-export", "vagrant"))
PORTA = int(sys.argv[2]) if len(sys.argv) > 2 else 8095
COMPRIME = (".pck", ".html", ".js")  # o .wasm a Cloudflare já entrega em brotli
_gz = {}  # caminho -> (mtime, tamanho, bytes gzip)


def comprimido(caminho):
    st = os.stat(caminho)
    c = _gz.get(caminho)
    if not c or c[0] != st.st_mtime or c[1] != st.st_size:
        with open(caminho, "rb") as f:
            c = (st.st_mtime, st.st_size, gzip.compress(f.read(), 6))
        _gz[caminho] = c
    return c[2]


class Servidor(http.server.SimpleHTTPRequestHandler):
    extensions_map = {**http.server.SimpleHTTPRequestHandler.extensions_map, ".wasm": "application/wasm", ".pck": "application/octet-stream"}

    def __init__(self, *a, **k):
        super().__init__(*a, directory=PASTA, **k)

    def do_GET(self):
        caminho = self.translate_path(self.path)
        if os.path.isdir(caminho):
            caminho = os.path.join(caminho, "index.html")
        if not os.path.isfile(caminho):
            return super().do_GET()
        st = os.stat(caminho)
        etag = '"%s"' % hashlib.md5(f"{st.st_mtime_ns}-{st.st_size}".encode()).hexdigest()
        pedidos = [e.strip().removeprefix("W/") for e in self.headers.get("If-None-Match", "").split(",")]
        if etag in pedidos:  # a Cloudflare troca o ETag por um fraco (W/) quando recomprime
            self.send_response(304)
            self.send_header("ETag", etag)
            self.send_header("Cache-Control", "no-cache")
            self.end_headers()
            return
        gz = caminho.endswith(COMPRIME) and "gzip" in self.headers.get("Accept-Encoding", "")
        if gz:
            corpo = comprimido(caminho)
        else:
            with open(caminho, "rb") as f:
                corpo = f.read()
        self.send_response(200)
        self.send_header("Content-Type", self.guess_type(caminho))
        self.send_header("Content-Length", str(len(corpo)))
        if gz:
            self.send_header("Content-Encoding", "gzip")
        self.send_header("ETag", etag)
        self.send_header("Last-Modified", email.utils.formatdate(st.st_mtime, usegmt=True))
        self.send_header("Cache-Control", "no-cache")  # guarda, mas pergunta antes de usar: depois de reexportar o celular pega o novo
        self.send_header("Vary", "Accept-Encoding")
        self.end_headers()
        if self.command != "HEAD":
            self.wfile.write(corpo)

    def do_HEAD(self):
        self.do_GET()


if __name__ == "__main__":
    print(f"servindo {PASTA} em http://0.0.0.0:{PORTA}", flush=True)
    http.server.ThreadingHTTPServer(("0.0.0.0", PORTA), Servidor).serve_forever()
