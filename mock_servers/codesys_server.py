import socket
import threading

from scapy.packet import Raw
from scapy.supersocket import StreamSocket

PORT = 2455
IDENTIFY_REQUEST = b"\xbb\xbb"

# codesys-v2-discover reads NUL terminated strings at these one based offsets.
FIELDS = {
    65: b"Linux",
    97: b"3.16.0",
    129: b"AIC-PLC-01",
}
RESPONSE_SIZE = 160


def build_response():
    frame = bytearray(RESPONSE_SIZE)
    frame[0:3] = b"\xbb\xbb\x01"
    for offset, value in FIELDS.items():
        frame[offset - 1:offset - 1 + len(value)] = value
    return Raw(bytes(frame))


RESPONSE = build_response()


def serve(connection):
    stream = StreamSocket(connection, Raw)
    while True:
        query = stream.recv()
        if query is None:
            break
        if bytes(query)[:2] == IDENTIFY_REQUEST:
            stream.send(RESPONSE)
    stream.close()


listener = socket.socket()
listener.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
listener.bind(("0.0.0.0", PORT))
listener.listen(5)

while True:
    connection, _ = listener.accept()
    threading.Thread(target=serve, args=(connection,), daemon=True).start()
