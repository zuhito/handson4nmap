#!/bin/bash
set -e
cd "$(dirname "$0")/.."

bash scripts/start.sh > /dev/null 2>&1
sleep 5

for log in /tmp/imap.log /tmp/pop3.log /tmp/smtp.log /tmp/vnc.log /tmp/s7.log /tmp/modbus.log; do
  : > "$log"
done

python3 - << 'PY'
import socket

for port in (25, 102, 110, 143, 502, 5900):
    for payload in (b"", b"\x00" * 4, b"GARBAGE\r\n", b"\xff" * 64):
        try:
            connection = socket.create_connection(("127.0.0.1", port), 5)
            if payload:
                connection.sendall(payload)
            connection.close()
        except OSError:
            pass
PY

for port in 25 102 110 143 502 5900; do
  timeout 10 bash -c ": > /dev/tcp/127.0.0.1/$port" || { echo "server on $port stopped"; exit 1; }
done

nmap -p 25,102,110,143,502,5900 127.0.0.1 | tee /tmp/robustness.txt
test "$(grep -c "open" /tmp/robustness.txt)" -ge 6

for log in /tmp/imap.log /tmp/pop3.log /tmp/smtp.log /tmp/vnc.log /tmp/s7.log /tmp/modbus.log; do
  ! grep -q "Traceback" "$log"
done
