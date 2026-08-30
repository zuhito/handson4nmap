local nmap = require "nmap"
local shortport = require "shortport"
local stdnse = require "stdnse"
local string = require "string"
local table = require "table"

description = [[
Reads the RFB handshake of a VNC server.

The protocol version and the security types the server offers are always
reported. When the server accepts unauthenticated clients the handshake is
completed so that the desktop name, the framebuffer size and the pixel format
from ServerInit can be shown as well, which tells what an attacker would see
without any credentials.
]]

---
-- @usage
-- nmap -p 5900 --script ./vnc.nse <host>
--
-- @output
-- PORT     STATE SERVICE
-- 5900/tcp open  vnc
-- | vnc:
-- |   Protocol version: 3.8
-- |   Security types: None (1)
-- |   Authentication: not required
-- |   Desktop name: Aichi Line1 HMI
-- |   Framebuffer: 1024x768
-- |_  Pixel format: 32 bits per pixel, depth 24

author = "kazuhitoyokoi"
license = "Same as Nmap--See https://nmap.org/book/man-legal.html"
categories = {"discovery", "safe", "version"}

portrule = shortport.port_or_service({5900, 5901}, "vnc", "tcp")

local SECURITY_TYPES = {
  [0] = "Invalid",
  [1] = "None",
  [2] = "VNC Authentication",
  [5] = "RA2",
  [6] = "RA2ne",
  [16] = "Tight",
  [17] = "Ultra",
  [18] = "TLS",
  [19] = "VeNCrypt",
  [20] = "SASL",
  [21] = "MD5 hash authentication",
  [22] = "Colin Dean xvp",
  [30] = "Apple Remote Desktop",
}

local function make_reader(socket)
  local pending = ""
  return function(n)
    while #pending < n do
      local status, data = socket:receive_bytes(n - #pending)
      if not status then return nil end
      pending = pending .. data
    end
    local out = string.sub(pending, 1, n)
    pending = string.sub(pending, n + 1)
    return out
  end
end

action = function(host, port)
  local socket = nmap.new_socket()
  socket:set_timeout(5000)
  if not socket:connect(host, port) then return nil end
  local read = make_reader(socket)

  local banner = read(12)
  if not banner then
    socket:close()
    return nil
  end

  local major, minor = string.match(banner, "^RFB (%d+)%.(%d+)\n$")
  if not major then
    socket:close()
    return nil
  end

  local version = string.format("%d.%d", tonumber(major), tonumber(minor))
  socket:send("RFB 003.008\n")

  local count = read(1)
  if not count then
    socket:close()
    return nil
  end
  count = string.byte(count)

  local out = stdnse.output_table()
  out["Protocol version"] = version

  if count == 0 then
    -- The server refused the connection and sends the reason instead.
    socket:close()
    out["Security types"] = "none offered"
    return out
  end

  local raw = read(count)
  if not raw then
    socket:close()
    return nil
  end

  local names, open_access = {}, false
  for i = 1, #raw do
    local id = string.byte(raw, i)
    names[#names + 1] = string.format("%s (%d)", SECURITY_TYPES[id] or "unknown", id)
    if id == 1 then open_access = true end
  end
  out["Security types"] = table.concat(names, ", ")
  out["Authentication"] = open_access and "not required" or "required"

  if open_access then
    socket:send("\x01")
    local result = read(4)
    if result and string.unpack(">I4", result) == 0 then
      socket:send("\x01")  -- ClientInit, shared session
      local init = read(24)
      if init then
        local width, height, bpp, depth = string.unpack(">I2 I2 I1 I1", init)
        local name_length = string.unpack(">I4", init, 21)
        local name = name_length > 0 and read(name_length) or nil
        out["Desktop name"] = name
        out["Framebuffer"] = string.format("%dx%d", width, height)
        out["Pixel format"] = string.format("%d bits per pixel, depth %d", bpp, depth)
      end
    end
  end

  socket:close()
  port.version.name = "vnc"
  nmap.set_port_version(host, port)
  return out
end
