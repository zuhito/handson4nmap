import os
import socketserver
import time

PORT = 110

# The angle bracketed token in the greeting is the APOP challenge.
CHALLENGE = "<%d.%d@aichi.example>" % (os.getpid(), int(time.time()))
GREETING = f"+OK Aichi Mail POP3 server ready {CHALLENGE}\r\n".encode()

CAPABILITIES = [
    "TOP",
    "USER",
    "UIDL",
    "PIPELINING",
    "RESP-CODES",
    "STLS",
    "SASL PLAIN LOGIN",
    "IMPLEMENTATION Aichi-Mail-POP3 2.1.4",
]


class Handler(socketserver.StreamRequestHandler):
    def handle(self):
        self.wfile.write(GREETING)

        while True:
            line = self.rfile.readline()
            if not line:
                return

            command = line.decode("ascii", "replace").split()
            if not command:
                continue
            verb = command[0].upper()

            if verb == "CAPA":
                self.wfile.write(b"+OK Capability list follows\r\n")
                for capability in CAPABILITIES:
                    self.wfile.write(f"{capability}\r\n".encode())
                self.wfile.write(b".\r\n")
            elif verb == "QUIT":
                self.wfile.write(b"+OK Aichi Mail POP3 server signing off\r\n")
                return
            elif verb in ("USER", "APOP"):
                self.wfile.write(b"-ERR Authentication is disabled on this server\r\n")
            else:
                self.wfile.write(b"-ERR Unknown command\r\n")


class Server(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True


Server(("0.0.0.0", PORT), Handler).serve_forever()
