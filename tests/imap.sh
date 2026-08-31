#!/bin/bash
set -e
cd "$(dirname "$0")/.."

timeout 1 bash -c ': > /dev/tcp/127.0.0.1/143' 2>/dev/null || setsid nohup python3 mock_servers/imap_server.py < /dev/null > /tmp/imap.log 2>&1 &
timeout 60 bash -c 'until : > /dev/tcp/127.0.0.1/143; do sleep 1; done' 2>/dev/null

nmap -p 143 --script imap-capabilities 127.0.0.1 | tee /tmp/imap.txt
grep -q "143/tcp open  imap" /tmp/imap.txt
grep -q "IMAP4rev1" /tmp/imap.txt
grep -q "STARTTLS" /tmp/imap.txt
grep -q "LOGINDISABLED" /tmp/imap.txt
grep -q "AUTH=PLAIN" /tmp/imap.txt
