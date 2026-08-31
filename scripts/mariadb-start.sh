#!/bin/bash
set -e

# The container image ships no initialised data directory, so create one the
# first time the database is needed.
if [ ! -d /var/lib/mysql/mysql ]; then
  mkdir -p /var/lib/mysql /run/mysqld
  chown -R mysql:mysql /var/lib/mysql /run/mysqld
  mariadb-install-db --user=mysql --datadir=/var/lib/mysql > /tmp/mariadb-install.log 2>&1
fi

mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld
pgrep -x mariadbd > /dev/null || setsid nohup mariadbd-safe --user=mysql < /dev/null > /tmp/mariadb.log 2>&1 &

if ! timeout 120 bash -c 'until mysqladmin ping --silent; do sleep 2; done'; then
  echo "mariadb did not start"
  tail -40 /tmp/mariadb.log || true
  exit 1
fi
