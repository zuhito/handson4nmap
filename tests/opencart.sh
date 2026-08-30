#!/bin/bash
set -e
cd "$(dirname "$0")/.."

timeout 120 bash -c 'until : > /dev/tcp/127.0.0.1/8081; do sleep 1; done' 2>/dev/null

nmap -p 8081 --script ./opencart.nse 127.0.0.1 | tee /tmp/opencart.txt
grep -q "8081/tcp open  opencart" /tmp/opencart.txt
grep -q "Storefront: /index.php" /tmp/opencart.txt
grep -q "Admin panel: /admin/ (reachable)" /tmp/opencart.txt
grep -q "Install directory: " /tmp/opencart.txt
