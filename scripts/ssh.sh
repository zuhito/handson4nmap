#!/bin/bash
set -e
cd "$(dirname "$0")/.."

mkdir -p /tmp/ssh /run/sshd work
[ -f /tmp/ssh/ssh_host_ed25519_key ] || ssh-keygen -q -t ed25519 -N "" -f /tmp/ssh/ssh_host_ed25519_key
[ -f /tmp/ssh/ssh_host_rsa_key ] || ssh-keygen -q -t rsa -b 3072 -N "" -f /tmp/ssh/ssh_host_rsa_key
chmod 600 /tmp/ssh/ssh_host_ed25519_key /tmp/ssh/ssh_host_rsa_key

cat > work/sshd_config << 'CONF'
Port 22
ListenAddress 127.0.0.1
HostKey /tmp/ssh/ssh_host_ed25519_key
HostKey /tmp/ssh/ssh_host_rsa_key
PidFile /tmp/ssh/sshd.pid
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
UsePAM no
Subsystem sftp /usr/lib/openssh/sftp-server
CONF

timeout 1 bash -c ': > /dev/tcp/127.0.0.1/22' 2>/dev/null || \
  /usr/sbin/sshd -f "$PWD/work/sshd_config"
timeout 30 bash -c 'until : > /dev/tcp/127.0.0.1/22; do sleep 1; done' 2>/dev/null
