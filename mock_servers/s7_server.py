import socketserver

from scapy.fields import ByteField, ShortField, StrFixedLenField, XByteField, XShortField
from scapy.packet import Packet, bind_layers
from scapy.compat import raw

PORT = 102

MODULE = b"AIC-CPU-3150"
BASIC_HARDWARE = b"AIC-CPU-3150"
VERSION = bytes((2, 6, 9))
SYSTEM_NAME = b"Aichi Line1 Controller"
MODULE_TYPE = b"AIC CPU 3150"
PLANT_ID = b"Aichi Company Plant 1"
COPYRIGHT = b"Original Aichi Company Equipment"
SERIAL_NUMBER = b"AIC-0001-0042"


class TPKT(Packet):
    name = "TPKT"
    fields_desc = [
        ByteField("version", 3),
        ByteField("reserved", 0),
        ShortField("length", None),
    ]

    def post_build(self, pkt, pay):
        if self.length is None:
            total = len(pkt) + len(pay)
            pkt = pkt[:2] + total.to_bytes(2, "big")
        return pkt + pay


class COTPConnect(Packet):
    name = "COTP Connection Confirm"
    fields_desc = [
        ByteField("length", 17),
        XByteField("pdu_type", 0xD0),
        XShortField("dst_ref", 0x0001),
        XShortField("src_ref", 0x0014),
        ByteField("class_option", 0),
        StrFixedLenField("parameters", b"\xc1\x02\x01\x00\xc2\x02\x01\x02\xc0\x01\x0a", 11),
    ]


class COTPData(Packet):
    name = "COTP Data"
    fields_desc = [
        ByteField("length", 2),
        XByteField("pdu_type", 0xF0),
        XByteField("tpdu_number", 0x80),
    ]


class S7SetupAck(Packet):
    name = "S7 Setup Communication Ack"
    fields_desc = [
        XByteField("protocol_id", 0x32),
        ByteField("rosctr", 3),
        XShortField("reserved", 0),
        XShortField("pdu_reference", 1),
        XShortField("parameter_length", 8),
        XShortField("data_length", 0),
        XShortField("error_class", 0),
        StrFixedLenField("parameters", b"\xf0\x00\x00\x01\x00\x01\x01\xe0", 8),
    ]


bind_layers(TPKT, COTPConnect)
bind_layers(COTPData, S7SetupAck)

# Offsets are 1 based and count from the start of the TPKT frame.
SZL_0011_FIELDS = {44: MODULE, 72: BASIC_HARDWARE, 123: VERSION}
SZL_001C_FIELDS = {
    40: SYSTEM_NAME,
    74: MODULE_TYPE,
    108: PLANT_ID,
    142: COPYRIGHT,
    176: SERIAL_NUMBER,
}


def szl_block(szl_id):
    size = 133 if szl_id == 0x11 else 221
    prefix = raw(TPKT() / COTPData() / S7SetupAck())[:8]

    block = bytearray(size)
    block[0:len(prefix)] = prefix
    block[2:4] = size.to_bytes(2, "big")
    block[31 - 1] = szl_id

    fields = SZL_0011_FIELDS if szl_id == 0x11 else SZL_001C_FIELDS
    for offset, value in fields.items():
        block[offset - 1:offset - 1 + len(value)] = value

    return bytes(block)


CONNECT_CONFIRM = raw(TPKT() / COTPConnect())
SETUP_ACK = raw(TPKT() / COTPData() / S7SetupAck())


class Handler(socketserver.BaseRequestHandler):
    def handle(self):
        while True:
            header = self.recv_exact(4)
            if not header:
                return
            length = TPKT(header).length
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
        return szl_block(packet[-3])


class Server(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True


Server(("0.0.0.0", PORT), Handler).serve_forever()
