import socket
import threading

from scapy.packet import Raw
from scapy.supersocket import StreamSocket

PORT = 143

GREETING = (
    b"* OK [CAPABILITY IMAP4rev1 STARTTLS LOGINDISABLED AUTH=PLAIN AUTH=LOGIN] "
    b"Aichi Mail IMAP4rev1 ready\r\n"
)
CAPABILITIES = (
    b"* CAPABILITY IMAP4rev1 STARTTLS LOGINDISABLED AUTH=PLAIN AUTH=LOGIN "
    b"IDLE NAMESPACE UIDPLUS ID\r\n"
)
# RFC 2971 ID response.
IDENTITY = (
    b'* ID ("name" "Aichi Mail" "version" "2.1.4" "os" "Linux" '
    b'"support-url" "https://aichi.example/support")\r\n'
)


def answer(line):
    parts = line.decode("ascii", "replace").split()
    if not parts:
        return b"", False
    tag = parts[0]
    command = parts[1].upper() if len(parts) > 1 else ""

    if command == "CAPABILITY":
        return CAPABILITIES + f"{tag} OK CAPABILITY completed\r\n".encode(), False
    if command == "ID":
        return IDENTITY + f"{tag} OK ID completed\r\n".encode(), False
    if command == "NOOP":
        return f"{tag} OK NOOP completed\r\n".encode(), False
    if command == "LOGOUT":
        return b"* BYE Aichi Mail logging out\r\n" + f"{tag} OK LOGOUT completed\r\n".encode(), True
    if command == "LOGIN":
        return f"{tag} NO [PRIVACYREQUIRED] Plaintext login is disabled\r\n".encode(), False
    return f"{tag} BAD Unknown command\r\n".encode(), False


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
