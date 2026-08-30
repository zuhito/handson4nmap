#!/bin/bash
set -e
cd "$(dirname "$0")/.."

timeout 60 bash -c 'until : > /dev/tcp/127.0.0.1/8086; do sleep 1; done' 2>/dev/null

curl -sS -XPOST "http://127.0.0.1:8086/query" --data-urlencode "q=CREATE DATABASE plant" > /dev/null
curl -sS -XPOST "http://127.0.0.1:8086/write?db=plant" \
  --data-binary 'pressure,line=line1 value=101.3
current,line=line1 value=12.7
status,line=line2 value=0' > /dev/null
