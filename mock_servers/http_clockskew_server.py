import http.server
import time

class Handler(http.server.BaseHTTPRequestHandler):
    server_version = "AichiHTTP/1.0"
    sys_version = ""

    def date_time_string(self, timestamp=None):
        return super().date_time_string(time.time() + 4 * 60 + 51)

    def do_GET(self):
        body = b"clock skew test server\n"
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_HEAD(self):
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", "0")
        self.end_headers()

    def log_message(self, *args):
        pass


http.server.HTTPServer(("0.0.0.0", 8000), Handler).serve_forever()
