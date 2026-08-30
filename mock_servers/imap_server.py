import socketserver

PORT = 143

GREETING = (
    b"* OK [CAPABILITY IMAP4rev1 STARTTLS LOGINDISABLED AUTH=PLAIN AUTH=LOGIN] "
    b"Aichi Mail IMAP4rev1 ready\r\n"
)
CAPABILITIES = (
    b"* CAPABILITY IMAP4rev1 STARTTLS LOGINDISABLED AUTH=PLAIN AUTH=LOGIN "
    b"IDLE NAMESPACE UIDPLUS ID\r\n"
)
# RFC 2971 ID response.
IDENTITY = (
    b'* ID ("name" "Aichi Mail" "version" "2.1.4" "os" "Linux" '
    b'"support-url" "https://aichi.example/support")\r\n'
)


class Handler(socketserver.StreamRequestHandler):
    def handle(self):
        self.wfile.write(GREETING)

        while True:
            line = self.rfile.readline()
            if not line:
                return

            parts = line.decode("ascii", "replace").split()
            if not parts:
                continue
            tag, command = parts[0], (parts[1].upper() if len(parts) > 1 else "")

            if command == "CAPABILITY":
                self.wfile.write(CAPABILITIES)
                self.reply(tag, "OK CAPABILITY completed")
            elif command == "ID":
                self.wfile.write(IDENTITY)
                self.reply(tag, "OK ID completed")
            elif command == "NOOP":
                self.reply(tag, "OK NOOP completed")
            elif command == "LOGOUT":
                self.wfile.write(b"* BYE Aichi Mail logging out\r\n")
                self.reply(tag, "OK LOGOUT completed")
                return
            elif command == "LOGIN":
                self.reply(tag, "NO [PRIVACYREQUIRED] Plaintext login is disabled")
            else:
                self.reply(tag, "BAD Unknown command")

    def reply(self, tag, text):
        self.wfile.write(f"{tag} {text}\r\n".encode())


class Server(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True


Server(("0.0.0.0", PORT), Handler).serve_forever()
