import os
import socket
import threading
import time

from scapy.packet import Raw
from scapy.supersocket import StreamSocket

PORT = 110

CHALLENGE = "<%d.%d@aichi.example>" % (os.getpid(), int(time.time()))
GREETING = f"+OK Aichi Mail POP3 server ready {CHALLENGE}\r\n".encode()

CAPABILITIES = [
    "TOP",
    "USER",
    "UIDL",
    "PIPELINING",
    "RESP-CODES",
    "STLS",
    "SASL PLAIN LOGIN",
    "IMPLEMENTATION Aichi-Mail-POP3 2.1.4",
]


def answer(line):
    words = line.decode("ascii", "replace").split()
    if not words:
        return b"", False
    verb = words[0].upper()

    if verb == "CAPA":
        body = "".join(f"{capability}\r\n" for capability in CAPABILITIES)
        return b"+OK Capability list follows\r\n" + body.encode() + b".\r\n", False
    if verb == "QUIT":
        return b"+OK Aichi Mail POP3 server signing off\r\n", True
    if verb in ("USER", "APOP"):
        return b"-ERR Authentication is disabled on this server\r\n", False
    return b"-ERR Unknown command\r\n", False


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
