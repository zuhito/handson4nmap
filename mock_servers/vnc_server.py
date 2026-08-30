import os
import socketserver
import struct
import threading

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


class OpenHandler(socketserver.BaseRequestHandler):
    def handle(self):
        self.request.sendall(RFB_VERSION)
        if len(self.request.recv(12)) != 12:
            return

        self.request.sendall(bytes([1, SECURITY_NONE]))
        if self.request.recv(1) != bytes([SECURITY_NONE]):
            return

        self.request.sendall(struct.pack(">I", 0))  # SecurityResult: OK
        self.request.recv(1)  # ClientInit
        self.request.sendall(
            server_init(1024, 768, 32, 24, b"Aichi Line1 HMI")
        )


class AuthHandler(socketserver.BaseRequestHandler):
    def handle(self):
        self.request.sendall(RFB_VERSION)
        if len(self.request.recv(12)) != 12:
            return

        self.request.sendall(bytes([1, SECURITY_VNC_AUTH]))
        if self.request.recv(1) != bytes([SECURITY_VNC_AUTH]):
            return

        self.request.sendall(os.urandom(16))  # challenge
        self.request.recv(16)  # response, never valid here
        self.request.sendall(struct.pack(">I", 1))  # SecurityResult: failed


class Server(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True


open_server = Server(("0.0.0.0", OPEN_PORT), OpenHandler)
auth_server = Server(("0.0.0.0", AUTH_PORT), AuthHandler)

threading.Thread(target=open_server.serve_forever, daemon=True).start()
auth_server.serve_forever()
