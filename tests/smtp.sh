#!/bin/bash
set -e
cd "$(dirname "$0")/.."

timeout 1 bash -c ': > /dev/tcp/127.0.0.1/25' 2>/dev/null || setsid nohup python3 mock_servers/smtp_server.py < /dev/null > /tmp/smtp.log 2>&1 &
timeout 60 bash -c 'until : > /dev/tcp/127.0.0.1/25; do sleep 1; done' 2>/dev/null

nmap -p 25 --script smtp.nse 127.0.0.1 | tee /tmp/smtp.txt
grep -q "25/tcp open  smtp" /tmp/smtp.txt
grep -q "Banner: mail.aichi.example ESMTP Aichi-Mail 2.1.4 ready" /tmp/smtp.txt
grep -q "Authentication: PLAIN, LOGIN" /tmp/smtp.txt
grep -q "STARTTLS: supported" /tmp/smtp.txt
grep -q "Maximum message size: 10485760 bytes" /tmp/smtp.txt
grep -q "VRFY: refused (252)" /tmp/smtp.txt
