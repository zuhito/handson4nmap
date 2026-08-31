#!/bin/bash
set -e
cd "$(dirname "$0")/.."

mkdir -p /tmp/ssh /run/sshd
[ -f /tmp/ssh/ssh_host_ed25519_key ] || ssh-keygen -q -t ed25519 -N "" -f /tmp/ssh/ssh_host_ed25519_key
[ -f /tmp/ssh/ssh_host_rsa_key ] || ssh-keygen -q -t rsa -b 3072 -N "" -f /tmp/ssh/ssh_host_rsa_key

timeout 1 bash -c ': > /dev/tcp/127.0.0.1/22' 2>/dev/null || \
  /usr/sbin/sshd -f "$PWD/scripts/sshd_config"
timeout 30 bash -c 'until : > /dev/tcp/127.0.0.1/22; do sleep 1; done' 2>/dev/null
