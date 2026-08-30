import socketserver

PORT = 2455

# The discover script reads NUL terminated strings at these one based offsets.
FIELDS = {
    65: b"Linux",
    97: b"3.16.0",
    129: b"AIC-PLC-01",
}
RESPONSE_SIZE = 160


def build_response():
    frame = bytearray(RESPONSE_SIZE)
    frame[0] = 0xBB
    frame[1] = 0xBB
    frame[2] = 0x01
    for offset, value in FIELDS.items():
        frame[offset - 1:offset - 1 + len(value)] = value
    return bytes(frame)


RESPONSE = build_response()


class Handler(socketserver.BaseRequestHandler):
    def handle(self):
        while True:
            query = self.request.recv(64)
            if not query:
                return
            if query[:2] == b"\xbb\xbb":
                self.request.sendall(RESPONSE)


class Server(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True


Server(("0.0.0.0", PORT), Handler).serve_forever()
