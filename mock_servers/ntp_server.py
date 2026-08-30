import socket

from scapy.layers.ntp import NTPHeader

PORT = 123

# 2028-11-15 00:00:00 UTC. NTP counts seconds from 1900-01-01, which is
# 2208988800 seconds before the Unix epoch.
FIXED_TIME = 1857859200 + 2208988800

sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
sock.bind(("0.0.0.0", PORT))

while True:
    data, peer = sock.recvfrom(1024)
    if len(data) < 48:
        continue

    # Parsing as NTPHeader keeps mode 6 and mode 7 packets from being decoded
    # as control or private messages, which do not carry these fields.
    request = NTPHeader(data)

    response = NTPHeader(
        leap=0,
        version=request.version,
        mode=4,  # server
        stratum=2,
        poll=request.poll,
        precision=-20,
        delay=0,
        dispersion=0,
        id="127.0.0.1",
        ref=FIXED_TIME,
        orig=request.sent,
        recv=FIXED_TIME,
        sent=FIXED_TIME,
    )
    sock.sendto(bytes(response), peer)
