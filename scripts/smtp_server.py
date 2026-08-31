import socket
import threading

from scapy.packet import Raw
from scapy.supersocket import StreamSocket

PORT = 25
HOSTNAME = "mail.aichi.example"

GREETING = f"220 {HOSTNAME} ESMTP Aichi-Mail 2.1.4 ready\r\n".encode()
EXTENSIONS = [
    "PIPELINING",
    "SIZE 10485760",
    "8BITMIME",
    "ENHANCEDSTATUSCODES",
    "STARTTLS",
    "AUTH PLAIN LOGIN",
    "HELP",
]


def ehlo_reply():
    lines = [f"250-{HOSTNAME}\r\n"]
    lines += [f"250-{extension}\r\n" for extension in EXTENSIONS[:-1]]
    lines.append(f"250 {EXTENSIONS[-1]}\r\n")
    return "".join(lines).encode()


def answer(line):
    words = line.decode("ascii", "replace").split()
    if not words:
        return b"", False
    verb = words[0].upper()

    if verb == "EHLO":
        return ehlo_reply(), False
    if verb == "HELO":
        return f"250 {HOSTNAME}\r\n".encode(), False
    if verb == "NOOP":
        return b"250 2.0.0 OK\r\n", False
    if verb == "VRFY":
        # Address verification is disabled, as recommended by RFC 5321.
        return b"252 2.5.2 Cannot verify user\r\n", False
    if verb == "QUIT":
        return f"221 2.0.0 {HOSTNAME} closing connection\r\n".encode(), True
    if verb in ("MAIL", "RCPT", "DATA"):
        return b"530 5.7.0 Authentication required\r\n", False
    return b"500 5.5.2 Command not recognized\r\n", False


def serve(connection):
    stream = StreamSocket(connection, Raw)
    stream.send(Raw(GREETING))
    pending = b""
    while True:
        received = stream.recv()
        if received is None:
            break
        pending += bytes(received)
        while b"\n" in pending:
            line, pending = pending.split(b"\n", 1)
            reply, done = answer(line)
            if reply:
                stream.send(Raw(reply))
            if done:
                stream.close()
                return
    stream.close()


listener = socket.socket()
listener.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
listener.bind(("0.0.0.0", PORT))
listener.listen(5)

while True:
    connection, _ = listener.accept()
    threading.Thread(target=serve, args=(connection,), daemon=True).start()
