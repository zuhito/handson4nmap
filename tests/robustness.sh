#!/bin/bash
set -e
cd "$(dirname "$0")/.."

bash scripts/start.sh > /dev/null 2>&1
sleep 5

python3 - << 'PY'
import socket

ports = [25, 102, 110, 143, 502, 1194, 4840, 5900]
for port in ports:
    for payload in (b"", b"\x00" * 4, b"GARBAGE\r\n"):
        try:
            s = socket.create_connection(("127.0.0.1", port), 5)
            if payload:
                s.sendall(payload)
            s.close()
        except OSError:
            pass
print("sent")
PY

for port in 25 102 110 143 502 4840 5900; do
  timeout 10 bash -c ": > /dev/tcp/127.0.0.1/$port" || { echo "server on $port died"; exit 1; }
done

: > /tmp/robustness.txt
for log in /tmp/imap.log /tmp/pop3.log /tmp/smtp.log /tmp/vnc.log /tmp/s7.log /tmp/modbus.log; do
  cat "$log" >> /tmp/robustness.txt 2>/dev/null || true
done
! grep -qE "Traceback|Unhandled" /tmp/robustness.txt
