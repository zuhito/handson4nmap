#!/bin/bash
set -e
cd "$(dirname "$0")"

mkdir -p external
curl -sfL -o external/multicast-profinet-discovery.nse \
  https://raw.githubusercontent.com/nmap/nmap/master/scripts/multicast-profinet-discovery.nse

# nmap 7.80/7.94 lack packet.ETHER_TYPE_PROFINET and stdnse.get_script_interfaces.
# Define both inside the downloaded script so the upstream protocol logic runs unchanged.
python3 - << 'PY'
path = "external/multicast-profinet-discovery.nse"
s = open(path).read()

# Newer nmap keeps ether types as numbers and packs them in build_ether_frame,
# while 7.80/7.94 keep them as two byte strings and concatenate them.
s = s.replace("eth_packet.ether_type = packet.ETHER_TYPE_PROFINET",
              'eth_packet.ether_type = string.pack(">I2", ETHER_TYPE_PROFINET)')
s = s.replace("packet.ETHER_TYPE_PROFINET", "ETHER_TYPE_PROFINET")
s = s.replace('local ipOps  = require "ipOps"',
              'local ipOps  = require "ipOps"\n\nlocal ETHER_TYPE_PROFINET = 0x8892')

s = s.replace("stdnse.get_script_interfaces(filter_interfaces)", "get_script_interfaces(filter_interfaces)")
s = s.replace("action = function()", '''local function get_script_interfaces (filterfunc)
  local interfaces = {}
  local selected = nmap.get_interface()
  local candidates = {}
  if selected then
    candidates[1] = nmap.get_interface_info(selected)
  else
    candidates = nmap.list_interfaces() or {}
  end
  for _, info in ipairs(candidates) do
    local kept = filterfunc(info)
    if kept then
      interfaces[#interfaces + 1] = kept
    end
  end
  return interfaces
end

action = function()''')

open(path, "w").write(s)
PY
