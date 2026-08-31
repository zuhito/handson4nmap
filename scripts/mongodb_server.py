import socketserver
import struct

PORT = 27017
OP_QUERY = 2004
OP_REPLY = 1

VERSION = "4.4.29"


def bson(document):
    """Encodes a flat document. Only the types used below are supported."""
    body = b""
    for key, value in document.items():
        name = key.encode() + b"\x00"
        if isinstance(value, bool):
            body += b"\x08" + name + (b"\x01" if value else b"\x00")
        elif isinstance(value, int):
            body += b"\x10" + name + struct.pack("<i", value)
        elif isinstance(value, float):
            body += b"\x01" + name + struct.pack("<d", value)
        elif isinstance(value, str):
            encoded = value.encode() + b"\x00"
            body += b"\x02" + name + struct.pack("<i", len(encoded)) + encoded
        elif isinstance(value, list):
            items = {str(i): item for i, item in enumerate(value)}
            body += b"\x04" + name + bson(items)
        elif isinstance(value, dict):
            body += b"\x03" + name + bson(value)
    return struct.pack("<i", len(body) + 5) + body + b"\x00"


RESPONSES = {
    "buildInfo": {
        "version": VERSION,
        "gitVersion": "unknown",
        "sysInfo": "deprecated",
        "versionArray": [4, 4, 29, 0],
        "bits": 64,
        "debug": False,
        "maxBsonObjectSize": 16777216,
        "ok": 1.0,
    },
    "serverStatus": {
        "host": "aichi-mongo",
        "version": VERSION,
        "process": "mongod",
        "pid": 1,
        "uptime": 3600.0,
        "connections": {"current": 1, "available": 51199, "totalCreated": 4},
        "network": {"bytesIn": 1024, "bytesOut": 2048, "numRequests": 8},
        "ok": 1.0,
    },
    "isMaster": {
        "ismaster": True,
        "maxBsonObjectSize": 16777216,
        "maxMessageSizeBytes": 48000000,
        "maxWireVersion": 9,
        "minWireVersion": 0,
        "readOnly": False,
        "ok": 1.0,
    },
    "listDatabases": {
        "databases": [
            {"name": "admin", "sizeOnDisk": 32768.0, "empty": False},
            {"name": "plant", "sizeOnDisk": 98304.0, "empty": False},
        ],
        "totalSize": 131072.0,
        "ok": 1.0,
    },
}
UNKNOWN = {"ok": 0.0, "errmsg": "no such command"}


def command_name(payload):
    # OP_QUERY: flags, collection name, skip, return, then the query document.
    end = payload.index(b"\x00", 4)
    document = payload[end + 9:]
    if len(document) < 5:
        return None
    # The first element name of the document is the command.
    start = 5
    stop = document.index(b"\x00", start)
    return document[start:stop].decode("ascii", "replace")


class Handler(socketserver.BaseRequestHandler):
    def handle(self):
        while True:
            header = self.request.recv(16)
            if len(header) < 16:
                return
            length, request_id, _, opcode = struct.unpack("<iiii", header)
            payload = b""
            while len(payload) < length - 16:
                chunk = self.request.recv(length - 16 - len(payload))
                if not chunk:
                    return
                payload += chunk
            if opcode != OP_QUERY:
                return

            document = bson(RESPONSES.get(command_name(payload), UNKNOWN))
            body = struct.pack("<iqii", 0, 0, 0, 1) + document
            self.request.sendall(
                struct.pack("<iiii", 16 + len(body), 1, request_id, OP_REPLY) + body
            )


class Server(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True


Server(("0.0.0.0", PORT), Handler).serve_forever()
