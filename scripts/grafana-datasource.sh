#!/bin/bash
set -e

# Registering the InfluxDB instance gives grafana.nse something to report when
# it is called with credentials. Creating it twice returns a conflict, which is
# fine because the data source is already there.
timeout 120 bash -c 'until : > /dev/tcp/127.0.0.1/3000; do sleep 1; done' 2>/dev/null

curl -sS -u admin:admin -H "Content-Type: application/json" \
  -X POST http://127.0.0.1:3000/api/datasources \
  -d '{"name":"plant-influx","type":"influxdb","url":"http://127.0.0.1:8086","access":"proxy","database":"plant"}' \
  > /tmp/grafana-datasource.log 2>&1 || true
