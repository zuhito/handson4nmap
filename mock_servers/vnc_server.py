import os
import socket
import struct
import threading

from scapy.packet import Raw
from scapy.supersocket import StreamSocket

# Two RFB endpoints: one that accepts unauthenticated clients and one that
# offers the classic VNC challenge response.
OPEN_PORT = 5900
AUTH_PORT = 5901

RFB_VERSION = b"RFB 003.008\n"
SECURITY_NONE = 1
SECURITY_VNC_AUTH = 2


def server_init(width, height, bpp, depth, name):
    # width, height, then the 16 byte pixel format, then the desktop name.
    pixel_format = struct.pack(
        ">BBBBHHHBBB3x", bpp, depth, 0, 1, 255, 255, 255, 16, 8, 0
    )
    return (
        struct.pack(">HH", width, height)
        + pixel_format
        + struct.pack(">I", len(name))
        + name
    )


def read(stream, length):
    data = b""
    while len(data) < length:
        received = stream.recv()
        if received is None:
            return None
        data += bytes(received)
    return data


def serve_open(stream):
    stream.send(Raw(RFB_VERSION))
    if read(stream, 12) is None:
        return

    stream.send(Raw(bytes([1, SECURITY_NONE])))
    if read(stream, 1) != bytes([SECURITY_NONE]):
        return

    stream.send(Raw(struct.pack(">I", 0)))  # SecurityResult: OK
    read(stream, 1)  # ClientInit
    stream.send(Raw(server_init(1024, 768, 32, 24, b"Aichi Line1 HMI")))


def serve_auth(stream):
    stream.send(Raw(RFB_VERSION))
    if read(stream, 12) is None:
        return

    stream.send(Raw(bytes([1, SECURITY_VNC_AUTH])))
    if read(stream, 1) != bytes([SECURITY_VNC_AUTH]):
        return

    stream.send(Raw(os.urandom(16)))  # challenge
    read(stream, 16)  # response, never valid here
    stream.send(Raw(struct.pack(">I", 1)))  # SecurityResult: failed


def listen(port, handler):
    listener = socket.socket()
    listener.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    listener.bind(("0.0.0.0", port))
    listener.listen(5)
    while True:
        connection, _ = listener.accept()
        stream = StreamSocket(connection, Raw)
        threading.Thread(target=lambda: (handler(stream), stream.close()),
                         daemon=True).start()


threading.Thread(target=listen, args=(OPEN_PORT, serve_open), daemon=True).start()
listen(AUTH_PORT, serve_auth)
