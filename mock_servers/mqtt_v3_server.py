import socketserver
import struct

PORT = 1884
USERNAME = b"aichi"
PASSWORD = b"aichi-secret"

# CONNACK for MQTT 5.0 telling the client that only 3.1.1 is supported.
UNSUPPORTED_VERSION = bytes([0x20, 0x03, 0x00, 0x84, 0x00])
# CONNACK return codes of MQTT 3.1.1.
ACCEPTED = bytes([0x20, 0x02, 0x00, 0x00])
NOT_AUTHORIZED = bytes([0x20, 0x02, 0x00, 0x05])


def read_remaining_length(sock):
    value, multiplier = 0, 1
    while True:
        chunk = sock.recv(1)
        if not chunk:
            return None
        byte = chunk[0]
        value += (byte & 0x7F) * multiplier
        if not byte & 0x80:
            return value
        multiplier *= 128


def read_string(body, pos):
    length = struct.unpack_from(">H", body, pos)[0]
    pos += 2
    return body[pos:pos + length], pos + length


def credentials_match(body, pos, flags):
    if not flags & 0x80:
        return False
    _client_id, pos = read_string(body, pos)
    if flags & 0x04:  # will message
        _topic, pos = read_string(body, pos)
        _payload, pos = read_string(body, pos)
    username, pos = read_string(body, pos)
    if not flags & 0x40:
        return False
    password, pos = read_string(body, pos)
    return username == USERNAME and password == PASSWORD


class Handler(socketserver.BaseRequestHandler):
    def handle(self):
        header = self.request.recv(1)
        if not header or header[0] >> 4 != 1:
            return
        length = read_remaining_length(self.request)
        if not length:
            return
        body = b""
        while len(body) < length:
            body += self.request.recv(length - len(body))

        _name, pos = read_string(body, 0)
        level = body[pos]
        flags = body[pos + 1]

        if level != 4:
            self.request.sendall(UNSUPPORTED_VERSION)
            return
        if credentials_match(body, pos + 4, flags):
            self.request.sendall(ACCEPTED)
        else:
            self.request.sendall(NOT_AUTHORIZED)


class Server(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True


Server(("0.0.0.0", PORT), Handler).serve_forever()
