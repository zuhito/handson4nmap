#!/bin/bash
set -e

fail() {
  echo "FAIL: $1" >&2
  echo "--- /tmp/modbus.log ---" >&2
  cat /tmp/modbus.log >&2 || true
  echo "--- /tmp/nodered.log ---" >&2
  cat /tmp/nodered.log >&2 || true
  exit 1
}

wait_port() {
  for _ in $(seq 1 60); do
    timeout 1 bash -c ": >/dev/tcp/127.0.0.1/$1" 2>/dev/null && return 0
    sleep 1
  done
  fail "port $1 did not open within 60s"
}

assert_contains() {
  echo "$1" | grep -q "$2" || fail "expected '$2' in nmap output"
}

echo "== whoami: $(whoami) =="
bash start.sh
wait_port 502
wait_port 1880

modbus=$(nmap -p 502 --script modbus-discover 127.0.0.1)
echo "$modbus"
assert_contains "$modbus" "502/tcp open  modbus"
assert_contains "$modbus" "Device identification: Aichi Company AIC-PLC-01"

nodered=$(nmap -p 1880 --script ./node-red.nse 127.0.0.1)
echo "$nodered"
assert_contains "$nodered" "1880/tcp open  node-red"
assert_contains "$nodered" "Node-RED:"
assert_contains "$nodered" "Node.js:"
assert_contains "$nodered" "OS:"

echo "== PASS =="
