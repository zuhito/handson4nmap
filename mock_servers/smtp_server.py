import socketserver

PORT = 25
HOSTNAME = "mail.aichi.example"

GREETING = f"220 {HOSTNAME} ESMTP Aichi-Mail 2.1.4 ready\r\n".encode()
EXTENSIONS = [
    "PIPELINING",
    "SIZE 10485760",
    "8BITMIME",
    "ENHANCEDSTATUSCODES",
    "STARTTLS",
    "AUTH PLAIN LOGIN",
    "HELP",
]


class Handler(socketserver.StreamRequestHandler):
    def handle(self):
        self.wfile.write(GREETING)

        while True:
            line = self.rfile.readline()
            if not line:
                return

            words = line.decode("ascii", "replace").split()
            if not words:
                continue
            verb = words[0].upper()

            if verb in ("EHLO", "HELO"):
                if verb == "HELO":
                    self.wfile.write(f"250 {HOSTNAME}\r\n".encode())
                    continue
                self.wfile.write(f"250-{HOSTNAME}\r\n".encode())
                for extension in EXTENSIONS[:-1]:
                    self.wfile.write(f"250-{extension}\r\n".encode())
                self.wfile.write(f"250 {EXTENSIONS[-1]}\r\n".encode())
            elif verb == "NOOP":
                self.wfile.write(b"250 2.0.0 OK\r\n")
            elif verb == "VRFY":
                # Address verification is disabled, as recommended by RFC 5321.
                self.wfile.write(b"252 2.5.2 Cannot verify user\r\n")
            elif verb == "QUIT":
                self.wfile.write(f"221 2.0.0 {HOSTNAME} closing connection\r\n".encode())
                return
            elif verb in ("MAIL", "RCPT", "DATA"):
                self.wfile.write(b"530 5.7.0 Authentication required\r\n")
            else:
                self.wfile.write(b"500 5.5.2 Command not recognized\r\n")


class Server(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True


Server(("0.0.0.0", PORT), Handler).serve_forever()
