import os
import socket
import struct
import threading

from scapy.packet import Raw
from scapy.supersocket import StreamSocket

PORT = 5900

RFB_VERSION = b"RFB 003.008\n"
SECURITY_VNC_AUTH = 2


def read(stream, length):
    data = b""
    while len(data) < length:
        received = stream.recv()
        if received is None:
            return None
        data += bytes(received)
    return data


def serve(stream):
    stream.send(Raw(RFB_VERSION))
    if read(stream, 12) is None:
        return

    stream.send(Raw(bytes([1, SECURITY_VNC_AUTH])))
    if read(stream, 1) != bytes([SECURITY_VNC_AUTH]):
        return

    stream.send(Raw(os.urandom(16)))  # challenge
    read(stream, 16)  # response, never valid here
    stream.send(Raw(struct.pack(">I", 1)))  # SecurityResult: failed


listener = socket.socket()
listener.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
listener.bind(("0.0.0.0", PORT))
listener.listen(5)

while True:
    connection, _ = listener.accept()
    stream = StreamSocket(connection, Raw)
    threading.Thread(target=lambda s=stream: (serve(s), s.close()), daemon=True).start()
