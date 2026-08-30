local nmap = require "nmap"
local shortport = require "shortport"
local stdnse = require "stdnse"
local string = require "string"
local table = require "table"

description = [[
Reads the greeting packet a MySQL or MariaDB server sends before any
credentials are exchanged.

The packet carries the server version, the connection identifier and the
capability flags. From those flags the script reports whether the server
offers TLS and which authentication plugin it defaults to, both of which
describe how a client would have to connect.
]]

---
-- @usage
-- nmap -p 3306 --script ./mysql.nse <host>
--
-- @output
-- PORT     STATE SERVICE
-- 3306/tcp open  mysql
-- | mysql:
-- |   Version: 5.5.5-10.11.14-MariaDB-0ubuntu0.24.04.1
-- |   Protocol: 10
-- |   Connection id: 13
-- |   Authentication plugin: mysql_native_password
-- |   TLS: not offered
-- |_  Capabilities: LONG_PASSWORD, FOUND_ROWS, CONNECT_WITH_DB, COMPRESS

author = "kazuhitoyokoi"
license = "Same as Nmap--See https://nmap.org/book/man-legal.html"
categories = {"discovery", "safe", "version"}

portrule = shortport.port_or_service(3306, "mysql", "tcp")

local CAPABILITIES = {
  {0x00000001, "LONG_PASSWORD"},
  {0x00000002, "FOUND_ROWS"},
  {0x00000008, "CONNECT_WITH_DB"},
  {0x00000020, "COMPRESS"},
  {0x00000200, "PROTOCOL_41"},
  {0x00000800, "SSL"},
  {0x00002000, "TRANSACTIONS"},
  {0x00008000, "SECURE_CONNECTION"},
  {0x00010000, "MULTI_STATEMENTS"},
  {0x00020000, "MULTI_RESULTS"},
  {0x00080000, "PLUGIN_AUTH"},
  {0x00100000, "CONNECT_ATTRS"},
  {0x00800000, "SESSION_TRACK"},
}

action = function(host, port)
  local socket = nmap.new_socket()
  socket:set_timeout(5000)
  if not socket:connect(host, port) then return nil end

  local status, data = socket:receive()
  socket:close()
  if not status or #data < 5 then return nil end

  -- Packet header: three length bytes and a sequence number.
  local length = string.unpack("<I3", data)
  local payload = string.sub(data, 5, 4 + length)
  if #payload < 20 then return nil end

  local protocol = string.byte(payload)
  if protocol ~= 10 then return nil end

  local version, pos = string.unpack("z", payload, 2)
  local connection_id
  connection_id, pos = string.unpack("<I4", payload, pos)

  pos = pos + 8 + 1                       -- first part of the salt and a filler
  local low, charset, server_status, high
  low, charset, server_status, high = string.unpack("<I2 I1 I2 I2", payload, pos)
  local flags = low | (high << 16)

  local out = stdnse.output_table()
  out["Version"] = version
  out["Protocol"] = protocol
  out["Connection id"] = connection_id

  local names = {}
  for _, entry in ipairs(CAPABILITIES) do
    if flags & entry[1] ~= 0 then
      names[#names + 1] = entry[2]
    end
  end

  -- The plugin name is the last NUL terminated string of the packet.
  local plugin = string.match(payload, "([%w_]+)%z?$")
  if plugin and #plugin > 3 then
    out["Authentication plugin"] = plugin
  end

  out["TLS"] = (flags & 0x00000800) ~= 0 and "offered" or "not offered"
  out["Capabilities"] = table.concat(names, ", ")

  port.version.name = "mysql"
  port.version.product = string.match(version, "MariaDB") and "MariaDB" or "MySQL"
  port.version.version = version
  nmap.set_port_version(host, port)
  return out
end
