import http.server
import json

DIAGNOSTICS = {
    "report": "diagnostics",
    "scope": "basic",
    "nodejs": {"version": "v20.11.1", "arch": "x64", "platform": "linux"},
    "os": {"arch": "x64", "platform": "linux", "release": "6.8.0-generic", "type": "Linux"},
    "runtime": {"version": "4.0.5"},
}


class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path != "/diagnostics":
            self.send_error(404)
            return
        body = json.dumps(DIAGNOSTICS).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *args):
        pass


http.server.HTTPServer(("0.0.0.0", 1880), Handler).serve_forever()
