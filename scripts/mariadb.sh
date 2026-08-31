#!/bin/bash
set -e

if command -v mariadbd-safe > /dev/null; then
  server="mariadbd-safe"
else
  server="mysqld_safe"
fi
if command -v mariadb-install-db > /dev/null; then
  installer="mariadb-install-db"
else
  installer="mysql_install_db"
fi

mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld

if [ ! -d /var/lib/mysql/mysql ]; then
  mkdir -p /var/lib/mysql
  chown -R mysql:mysql /var/lib/mysql
  "$installer" --user=mysql --datadir=/var/lib/mysql > /tmp/mariadb-install.log 2>&1
fi

pgrep -x mariadbd > /dev/null || pgrep -x mysqld > /dev/null || \
  setsid nohup "$server" --user=mysql < /dev/null > /tmp/mariadb.log 2>&1 &

if ! timeout 120 bash -c 'until mysqladmin ping --silent > /dev/null 2>&1; do sleep 2; done'; then
  echo "mariadb did not start with $server"
  tail -40 /tmp/mariadb.log || true
  tail -20 /tmp/mariadb-install.log 2>/dev/null || true
  exit 1
fi
