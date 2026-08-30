import socket
import struct
import time

HOST = "127.0.0.1"
PORT = 1883
TOPICS = {
    "aichi/plc01/temperature": b"25.4",
    "aichi/plc01/pressure": b"101.3",
    "aichi/plc01/status": b"running",
}


def encode_length(n):
    out = b""
    while True:
        byte = n % 128
        n //= 128
        out += bytes([byte | (0x80 if n else 0)])
        if not n:
            return out


def connect_packet():
    payload = struct.pack(">H", 9) + b"publisher"
    variable = struct.pack(">H", 4) + b"MQTT" + bytes([4, 0x02]) + struct.pack(">H", 60)
    body = variable + payload
    return b"\x10" + encode_length(len(body)) + body


def publish_packet(topic, value):
    body = struct.pack(">H", len(topic)) + topic.encode() + value
    return b"\x31" + encode_length(len(body)) + body


while True:
    try:
        sock = socket.create_connection((HOST, PORT), 5)
        sock.sendall(connect_packet())
        sock.recv(64)
        while True:
            for topic, value in TOPICS.items():
                sock.sendall(publish_packet(topic, value))
            time.sleep(2)
    except OSError:
        time.sleep(2)
