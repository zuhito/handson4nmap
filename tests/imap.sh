#!/bin/bash
set -e
cd "$(dirname "$0")/.."

timeout 1 bash -c ': > /dev/tcp/127.0.0.1/143' 2>/dev/null || setsid nohup python3 mock_servers/imap_server.py < /dev/null > /tmp/imap.log 2>&1 &
timeout 60 bash -c 'until : > /dev/tcp/127.0.0.1/143; do sleep 1; done' 2>/dev/null

nmap -p 143 --script imap.nse 127.0.0.1 | tee /tmp/imap.txt
grep -q "143/tcp open  imap" /tmp/imap.txt
grep -q "Greeting: Aichi Mail IMAP4rev1 ready" /tmp/imap.txt
grep -q "Authentication: PLAIN, LOGIN" /tmp/imap.txt
grep -q "STARTTLS: supported" /tmp/imap.txt
grep -q "Plaintext login: disabled" /tmp/imap.txt
grep -q "Server ID: name Aichi Mail, version 2.1.4" /tmp/imap.txt
