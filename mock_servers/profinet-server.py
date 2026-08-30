import fcntl
import os
import socket
import struct

IFACE = os.environ.get("PROFINET_IFACE", "eth0")
ETH_P_ALL = 0x0003
ETH_P_PROFINET = 0x8892
DCP_MULTICAST = b"\x01\x0e\xcf\x00\x00\x00"

VENDOR_VALUE = b"Aichi Company AIC-PLC-01"
NAME_OF_STATION = b"aic-plc-01"
VENDOR_ID = 0x002A
DEVICE_ID = 0x0105
DEVICE_ROLE = 0x02


def ioctl_addr(sock, code):
    packed = fcntl.ioctl(sock.fileno(), code, struct.pack("256s", IFACE.encode()[:15]))
    return packed[20:24]


def block(option, suboption, payload):
    data = struct.pack(">BBH", option, suboption, len(payload)) + payload
    return data + b"\x00" * (len(payload) % 2)


def build_blocks(ip, mask, gateway):
    blocks = block(0x01, 0x02, struct.pack(">H", 1) + ip + mask + gateway)
    blocks += block(0x02, 0x01, struct.pack(">H", 0) + VENDOR_VALUE)
    blocks += block(0x02, 0x02, struct.pack(">H", 0) + NAME_OF_STATION)
    blocks += block(0x02, 0x03, struct.pack(">HHH", 0, VENDOR_ID, DEVICE_ID))
    blocks += block(0x02, 0x04, struct.pack(">HBB", 0, DEVICE_ROLE, 0))
    blocks += block(0x02, 0x07, struct.pack(">HBB", 0, 0, 100))
    return blocks


def main():
    sock = socket.socket(socket.AF_PACKET, socket.SOCK_RAW, socket.htons(ETH_P_ALL))
    sock.bind((IFACE, 0))

    mac = sock.getsockname()[4]
    ip = ioctl_addr(sock, 0x8915)
    mask = ioctl_addr(sock, 0x891B)
    gateway = ip[:3] + b"\x01"
    blocks = build_blocks(ip, mask, gateway)

    print("PROFINET DCP responder on %s (%s)" % (IFACE, socket.inet_ntoa(ip)), flush=True)

    while True:
        frame = sock.recv(1514)
        if len(frame) < 26:
            continue
        if frame[0:6] != DCP_MULTICAST:
            continue
        if struct.unpack(">H", frame[12:14])[0] != ETH_P_PROFINET:
            continue
        frame_id, service_id, service_type, xid = struct.unpack(">HBBI", frame[14:22])
        if frame_id != 0xFEFE or service_id != 5 or service_type != 0:
            continue

        dcp = struct.pack(">HBBIHH", 0xFEFF, 5, 1, xid, 0, len(blocks)) + blocks
        reply = frame[6:12] + mac + struct.pack(">H", ETH_P_PROFINET) + dcp
        reply += b"\x00" * max(0, 60 - len(reply))
        sock.send(reply)


main()
