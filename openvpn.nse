local math = require "math"
local nmap = require "nmap"
local shortport = require "shortport"
local stdnse = require "stdnse"
local string = require "string"
local table = require "table"

description = [[
Detects OpenVPN servers by sending a P_CONTROL_HARD_RESET_CLIENT_V2 control
packet and parsing the reset packet the server sends back.

The response carries the session id the server generated for the connection
and an acknowledgement of the session id sent by the script, which confirms
that the peer really speaks the OpenVPN protocol rather than merely having
the port open. Servers protected with tls-auth or tls-crypt silently drop the
probe because it carries no HMAC, so they are not reported.
]]

---
-- @usage
-- nmap -p 1194 --script ./openvpn.nse <host>
-- nmap -sU -p 1194 --script ./openvpn.nse <host>
--
-- @output
-- PORT     STATE SERVICE
-- 1194/udp open  openvpn
-- | openvpn:
-- |   Packet: P_CONTROL_HARD_RESET_SERVER_V2 (opcode 8)
-- |   Server session ID: dd89b9a8f577da83
-- |   Key ID: 0
-- |_  Client session acknowledged: yes

author = "kazuhitoyokoi"
license = "Same as Nmap--See https://nmap.org/book/man-legal.html"
categories = {"discovery", "safe", "version"}

portrule = shortport.port_or_service(1194, "openvpn", {"tcp", "udp"})

local OPCODES = {
  [1] = "P_CONTROL_HARD_RESET_CLIENT_V1",
  [2] = "P_CONTROL_HARD_RESET_SERVER_V1",
  [3] = "P_CONTROL_SOFT_RESET_V1",
  [4] = "P_CONTROL_V1",
  [5] = "P_ACK_V1",
  [6] = "P_DATA_V1",
  [7] = "P_CONTROL_HARD_RESET_CLIENT_V2",
  [8] = "P_CONTROL_HARD_RESET_SERVER_V2",
  [9] = "P_DATA_V2",
  [10] = "P_CONTROL_HARD_RESET_CLIENT_V3",
  [11] = "P_CONTROL_WKC_V1",
}

local SERVER_RESET = { [2] = true, [8] = true }

local function client_session_id()
  local id = {}
  for i = 1, 8 do
    id[i] = string.char(math.random(0, 255))
  end
  return table.concat(id)
end

local function hard_reset(session)
  -- opcode 7 in the upper 5 bits, key id 0 in the lower 3 bits
  return string.pack(">B", 7 << 3) .. session .. "\x00" .. string.pack(">I4", 0)
end

local function read_tcp(socket)
  local pending = ""
  local function read(n)
    while #pending < n do
      local status, data = socket:receive_bytes(n - #pending)
      if not status then return nil end
      pending = pending .. data
    end
    local out = string.sub(pending, 1, n)
    pending = string.sub(pending, n + 1)
    return out
  end

  local header = read(2)
  if not header then return nil end
  return read(string.unpack(">I2", header))
end

action = function(host, port)
  local session = client_session_id()
  local probe = hard_reset(session)

  local socket = nmap.new_socket()
  socket:set_timeout(5000)
  if not socket:connect(host, port) then return nil end

  local payload
  if port.protocol == "tcp" then
    socket:send(string.pack(">I2", #probe) .. probe)
    payload = read_tcp(socket)
  else
    socket:send(probe)
    local status, data = socket:receive()
    payload = status and data or nil
  end
  socket:close()

  if not payload or #payload < 9 then return nil end

  local first = string.unpack(">B", payload)
  local opcode = first >> 3
  local key_id = first & 0x07
  if not SERVER_RESET[opcode] then return nil end

  local server_session = string.sub(payload, 2, 9)
  local acknowledged = "no"

  if #payload >= 10 then
    local ack_count = string.unpack(">B", payload, 10)
    local pos = 11 + ack_count * 4
    if ack_count > 0 and #payload >= pos + 7 then
      if string.sub(payload, pos, pos + 7) == session then
        acknowledged = "yes"
      end
    end
  end

  local out = stdnse.output_table()
  out["Packet"] = string.format("%s (opcode %d)", OPCODES[opcode] or "unknown", opcode)
  out["Server session ID"] = stdnse.tohex(server_session)
  out["Key ID"] = key_id
  out["Client session acknowledged"] = acknowledged

  port.version.name = "openvpn"
  nmap.set_port_version(host, port)
  return out
end
