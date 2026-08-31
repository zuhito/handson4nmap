#!/bin/bash
set -e
cd "$(dirname "$0")/.."

timeout 1 bash -c ': > /dev/tcp/127.0.0.1/4851' 2>/dev/null || \
  setsid nohup python3 tests/opcua_servers.py < /dev/null > /tmp/opcua_servers.log 2>&1 &
timeout 60 bash -c 'until : > /dev/tcp/127.0.0.1/4859; do sleep 1; done' 2>/dev/null

sed 's/{4840, 4841, 48010, 53530}/{4840,4851,4852,4853,4854,4855,4856,4857,4858,4859}/' opcua.nse > /tmp/opcua-variants.nse

nmap -p 4851 --script /tmp/opcua-variants.nse 127.0.0.1 | tee /tmp/opcua-plain.txt
grep -q "opc.tcp://127.0.0.1:4851/Test" /tmp/opcua-plain.txt
grep -q "None (None), authentication: Anonymous, UserName" /tmp/opcua-plain.txt

nmap -p 4852 --script /tmp/opcua-variants.nse 127.0.0.1 | tee /tmp/opcua-many.txt
grep -q "opc.tcp://127.0.0.1:4852/Test" /tmp/opcua-many.txt
test "$(grep -c "Basic256Sha256" /tmp/opcua-many.txt)" -eq 9
test "$(grep -c "opc.tcp://127.0.0.1:4852/Test" /tmp/opcua-many.txt)" -eq 1

nmap -p 4853 --script /tmp/opcua-variants.nse 127.0.0.1 | tee /tmp/opcua-empty.txt
grep -q "Server time:" /tmp/opcua-empty.txt
! grep -q "Endpoint URLs" /tmp/opcua-empty.txt

nmap -p 4854 --script /tmp/opcua-variants.nse 127.0.0.1 | tee /tmp/opcua-fault.txt
! grep -q "opcua" /tmp/opcua-fault.txt

nmap -p 4855 --script /tmp/opcua-variants.nse 127.0.0.1 | tee /tmp/opcua-chunked.txt
grep -q "opc.tcp://127.0.0.1:4855/Test" /tmp/opcua-chunked.txt
grep -q "SignAndEncrypt (Basic256Sha256)" /tmp/opcua-chunked.txt

for port in 4856 4857 4858; do
  nmap -p "$port" --script /tmp/opcua-variants.nse 127.0.0.1 | tee "/tmp/opcua-$port.txt"
  ! grep -q "Server time:" "/tmp/opcua-$port.txt"
done

nmap -p 4859 --script /tmp/opcua-variants.nse 127.0.0.1 | tee /tmp/opcua-tokens.txt
grep -q "authentication: Certificate, IssuedToken, Unknown(9)" /tmp/opcua-tokens.txt
