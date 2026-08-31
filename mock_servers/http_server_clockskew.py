import http.server
import time

PORT = 80
SKEW_SECONDS = 4 * 60 + 51

PAGE = b"""<!DOCTYPE html>
<html lang="ja">
<head>
<meta charset="utf-8">
<title>Aichi Line1 HMI</title>
</head>
<body>
<h1>Aichi Line1 HMI</h1>
<p>Status: running</p>
</body>
</html>
"""


class Handler(http.server.BaseHTTPRequestHandler):
    server_version = "AichiHTTP/1.0"
    sys_version = ""

    def date_time_string(self, timestamp=None):
        # The Date header is deliberately ahead of the real time so that
        # http-date and clock-skew have something to report.
        return super().date_time_string(time.time() + SKEW_SECONDS)

    def send_common_headers(self, length):
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(length))
        self.send_header("X-Powered-By", "Aichi-HMI/2.1.4")
        self.send_header("X-Frame-Options", "SAMEORIGIN")
        self.send_header("Cache-Control", "no-store")

    def do_GET(self):
        self.send_response(200)
        self.send_common_headers(len(PAGE))
        self.end_headers()
        self.wfile.write(PAGE)

    def do_HEAD(self):
        self.send_response(200)
        self.send_common_headers(len(PAGE))
        self.end_headers()

    def log_message(self, *args):
        pass


http.server.HTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
