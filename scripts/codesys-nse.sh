#!/bin/bash
set -e
cd "$(dirname "$0")/.."

curl -sfL -o codesys-v2-discover.nse \
  https://raw.githubusercontent.com/digitalbond/Redpoint/master/codesys-v2-discover.nse

# The script still uses the bin library, which was removed in nmap 7.90.
python3 - << 'PY'
path = "codesys-v2-discover.nse"
s = open(path).read()

s = s.replace('local strbuf = require "strbuf"', 'local string = require "string"')
s = s.replace('bin.pack("H", "bbbb0100000001")', 'stdnse.fromhex("bbbb0100000001")')
s = s.replace('bin.pack("H", "bbbb0100000101")', 'stdnse.fromhex("bbbb0100000101")')
s = s.replace('local pos, codesys_check = bin.unpack("C", response, 1)',
              'local codesys_check = string.byte(response, 1)')
s = s.replace('local pos, os_name = bin.unpack("z", response, 65)',
              'local os_name = string.unpack("z", response, 65)')
s = s.replace('local pos , os_type = bin.unpack("z", response, 97)',
              'local os_type = string.unpack("z", response, 97)')
s = s.replace('local pos, product_type = bin.unpack("z", response, 129)',
              'local product_type = string.unpack("z", response, 129)')

open(path, "w").write(s)
PY

