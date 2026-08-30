import socketserver
import struct

MODULE = b"6ES7 315-2AG10-0AB0"
BASIC_HARDWARE = b"6ES7 315-2AG10-0AB0"
VERSION = (2, 6, 9)
SYSTEM_NAME = b"SIMATIC 300(Aichi)"
MODULE_TYPE = b"CPU 315-2 DP"
PLANT_ID = b"Aichi Company Plant 1"
COPYRIGHT = b"Original Siemens Equipment"
SERIAL_NUMBER = b"S C-AIC421302009"

# Offsets are 1 based, matching the string.unpack calls in s7-info.nse.
SZL_0011_FIELDS = {44: MODULE, 72: BASIC_HARDWARE}
SZL_001C_FIELDS = {
    40: SYSTEM_NAME,
    74: MODULE_TYPE,
    108: PLANT_ID,
    142: COPYRIGHT,
    176: SERIAL_NUMBER,
}


def tpkt(payload):
    return b"\x03\x00" + struct.pack(">H", len(payload) + 4) + payload


def place(buf, offset, value):
    buf[offset - 1:offset - 1 + len(value)] = value


def szl_response(szl_id):
    size = 133 if szl_id == 0x11 else 221
    buf = bytearray(size)
    buf[0:2] = b"\x03\x00"
    struct.pack_into(">H", buf, 2, size)
    buf[4:8] = b"\x02\xf0\x80"[0:3] + b"\x32"
    buf[8 - 1] = 0x32
    buf[31 - 1] = szl_id

    fields = SZL_0011_FIELDS if szl_id == 0x11 else SZL_001C_FIELDS
    for offset, value in fields.items():
        place(buf, offset, value)

    if szl_id == 0x11:
        buf[123 - 1], buf[124 - 1], buf[125 - 1] = VERSION

    return bytes(buf)


CONNECT_CONFIRM = tpkt(
    b"\x11\xd0\x00\x01\x00\x14\x00\xc1\x02\x01\x00\xc2\x02\x01\x02\xc0\x01\x0a"
)
SETUP_ACK = tpkt(
    b"\x02\xf0\x802\x03\x00\x00\x00\x01\x00\x08\x00\x00\x00\xf0\x00\x00\x01\x00\x01\x01\xe0"
)


class Handler(socketserver.BaseRequestHandler):
    def handle(self):
        while True:
            header = self.recv_exact(4)
            if not header:
                return
            length = struct.unpack(">H", header[2:4])[0]
            body = self.recv_exact(length - 4)
            if body is None:
                return
            self.request.sendall(self.reply(header + body))

    def recv_exact(self, n):
        buf = b""
        while len(buf) < n:
            chunk = self.request.recv(n - len(buf))
            if not chunk:
                return None
            buf += chunk
        return buf

    def reply(self, packet):
        if packet[5] == 0xE0:
            return CONNECT_CONFIRM
        if packet[7] == 0x32 and packet[8] == 0x01:
            return SETUP_ACK
        return szl_response(packet[-3])


class Server(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True


Server(("0.0.0.0", 102), Handler).serve_forever()
