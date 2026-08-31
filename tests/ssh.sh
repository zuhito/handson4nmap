#!/bin/bash
set -e
cd "$(dirname "$0")/.."

bash scripts/ssh-start.sh

nmap -p 22 127.0.0.1 | tee /tmp/ssh.txt
grep -q "22/tcp open  ssh" /tmp/ssh.txt

nmap -p 22 -sV 127.0.0.1 | tee /tmp/ssh-version.txt
grep -q "OpenSSH" /tmp/ssh-version.txt
