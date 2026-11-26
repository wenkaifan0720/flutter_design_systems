"""Serve the local release build with the same missing-page behavior as a static host."""
import argparse
from functools import partial
from http import HTTPStatus
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


class SiteHandler(SimpleHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def send_error(self, code, message=None, explain=None):
        page = Path(self.directory, "404.html")
        if code != HTTPStatus.NOT_FOUND or not page.is_file():
            return super().send_error(code, message, explain)
        content = page.read_bytes()
        self.send_response(code)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(content)))
        self.end_headers()
        if self.command != "HEAD":
            self.wfile.write(content)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", type=int, default=8000)
    parser.add_argument("--directory", type=Path, default=Path(__file__).resolve().parents[2] / "build/site")
    args = parser.parse_args()
    with ThreadingHTTPServer(("127.0.0.1", args.port), partial(SiteHandler, directory=args.directory)) as server:
        print(f"http://127.0.0.1:{server.server_port}/docs/", flush=True)
        server.serve_forever()
