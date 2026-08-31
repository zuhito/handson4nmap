import socket
import struct
import sys
import threading

def s_str(value):
    if value is None:
        return struct.pack("<i", -1)
    return struct.pack("<i", len(value)) + value

def localized_text(text):
    return bytes([2]) + s_str(text)

def response_header(ticks):
    return (struct.pack("<q", ticks) + struct.pack("<I", 1) + struct.pack("<I", 0)
            + b"\x00" + struct.pack("<i", 0) + b"\x00\x00\x00")

def endpoint(url, mode, policy, tokens, cert=b""):
    body = s_str(url)
    body += s_str(b"urn:aichi:test") + s_str(b"urn:aichi:product")
    body += localized_text(b"Test Server")
    body += struct.pack("<I", 0) + s_str(None) + s_str(None) + struct.pack("<i", 0)
    body += s_str(cert if cert else None)
    body += struct.pack("<I", mode) + s_str(policy)
    body += struct.pack("<i", len(tokens))
    for policy_id, token_type in tokens:
        body += s_str(policy_id) + struct.pack("<I", token_type)
        body += s_str(None) + s_str(None) + s_str(None)
    body += s_str(b"http://opcfoundation.org/UA-Profile/Transport/uatcp-uasc-uabinary")
    body += bytes([0])
    return body

TICKS = 134324917425305170

def build_endpoints(kind, port):
    url = ("opc.tcp://127.0.0.1:%d/Test" % port).encode()
    tokens = [(b"anonymous", 0), (b"username", 1)]
    if kind == "empty":
        items = []
    elif kind == "many":
        items = [endpoint(url, mode, b"http://opcfoundation.org/UA/SecurityPolicy#Basic256Sha256",
                          tokens, cert=b"C" * 1400) for mode in (1, 2, 3)] * 3
    elif kind == "chunked":
        items = [endpoint(url, 3, b"http://opcfoundation.org/UA/SecurityPolicy#Basic256Sha256",
                          tokens, cert=b"C" * 4000)]
    else:
        items = [endpoint(url, 1, b"http://opcfoundation.org/UA/SecurityPolicy#None", tokens)]
    body = b"\x01\x00" + struct.pack("<H", 431) + response_header(TICKS)
    body += struct.pack("<i", len(items) if items else 0) + b"".join(items)
    return body

def fault():
    # ServiceFault carries a different type id and no endpoints.
    return b"\x01\x00" + struct.pack("<H", 397) + response_header(TICKS)

def serve(connection, kind, port):
    def read(n):
        data = b""
        while len(data) < n:
            chunk = connection.recv(n - len(data))
            if not chunk:
                return None
            data += chunk
        return data

    while True:
        header = read(8)
        if header is None:
            return
        kind_bytes, size = header[:4], struct.unpack("<I", header[4:8])[0]
        payload = read(size - 8)
        if payload is None:
            return

        if kind_bytes == b"HELF":
            ack = struct.pack("<IIIII", 0, 65535, 65535, 0, 0)
            connection.sendall(b"ACKF" + struct.pack("<I", 8 + len(ack)) + ack)
        elif kind_bytes == b"OPNF":
            sec = s_str(b"http://opcfoundation.org/UA/SecurityPolicy#None") + s_str(None) + s_str(None)
            body = (b"\x01\x00" + struct.pack("<H", 449) + response_header(TICKS)
                    + struct.pack("<I", 0) + struct.pack("<II", 7, 13)
                    + struct.pack("<q", TICKS) + struct.pack("<I", 3600000) + s_str(None))
            frame = struct.pack("<I", 0) + sec + struct.pack("<II", 1, 1) + body
            connection.sendall(b"OPNF" + struct.pack("<I", 8 + len(frame)) + frame)
        elif kind_bytes == b"MSGF":
            body = fault() if kind == "fault" else build_endpoints(kind, port)
            frame = struct.pack("<IIII", 7, 13, 2, 2) + body
            if kind == "chunked":
                half = len(frame) // 2
                first, second = frame[:half], struct.pack("<IIII", 7, 13, 3, 2) + frame[half:]
                connection.sendall(b"MSGC" + struct.pack("<I", 8 + len(first)) + first)
                connection.sendall(b"MSGF" + struct.pack("<I", 8 + len(second)) + second)
            else:
                connection.sendall(b"MSGF" + struct.pack("<I", 8 + len(frame)) + frame)
        else:
            return

def listen(port, kind):
    listener = socket.socket()
    listener.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    listener.bind(("127.0.0.1", port))
    listener.listen(5)
    while True:
        connection, _ = listener.accept()
        threading.Thread(target=lambda c=connection: (serve(c, kind, port), c.close()),
                         daemon=True).start()

LAYOUT = {4851: "plain", 4852: "many", 4853: "empty", 4854: "fault", 4855: "chunked"}

for port, kind in LAYOUT.items():
    threading.Thread(target=listen, args=(port, kind), daemon=True).start()

threading.Event().wait()
