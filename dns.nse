local nmap = require "nmap"
local shortport = require "shortport"
local stdnse = require "stdnse"
local string = require "string"
local table = require "table"

description = [[
Asks a DNS server what it is willing to tell an unauthenticated client.

The server software is read from the CHAOS class TXT record version.bind,
which most implementations answer by default. A second query for a name the
server is not authoritative for shows whether recursion is offered, since an
open resolver can be abused for amplification attacks.
]]

---
-- @usage
-- nmap -sU -p 53 --script ./dns.nse <host>
--
-- @output
-- PORT   STATE SERVICE
-- 53/udp open  domain
-- | dns:
-- |   Version: dnsmasq-2.90
-- |   Recursion: not offered
-- |_  Response code: NOERROR

author = "kazuhitoyokoi"
license = "Same as Nmap--See https://nmap.org/book/man-legal.html"
categories = {"discovery", "safe", "version"}

portrule = shortport.port_or_service(53, "domain", {"tcp", "udp"})

local RCODES = {
  [0] = "NOERROR",
  [1] = "FORMERR",
  [2] = "SERVFAIL",
  [3] = "NXDOMAIN",
  [4] = "NOTIMP",
  [5] = "REFUSED",
}

local function encode_name(name)
  local parts = {}
  for label in string.gmatch(name, "[^.]+") do
    parts[#parts + 1] = string.pack(">s1", label)
  end
  return table.concat(parts) .. "\0"
end

local function build_query(id, name, qtype, qclass, recursion)
  local flags = recursion and 0x0100 or 0x0000
  return string.pack(">I2 I2 I2 I2 I2 I2", id, flags, 1, 0, 0, 0)
    .. encode_name(name) .. string.pack(">I2 I2", qtype, qclass)
end

local function ask(host, port, query)
  local socket = nmap.new_socket()
  socket:set_timeout(5000)
  if not socket:connect(host, port) then return nil end
  socket:send(query)
  local status, response = socket:receive()
  socket:close()
  if not status then return nil end
  return response
end

-- Skips a name at the given position, following the length prefixes.
local function skip_name(data, pos)
  while true do
    local length = string.byte(data, pos)
    if not length then return nil end
    if length == 0 then return pos + 1 end
    if length >= 0xC0 then return pos + 2 end
    pos = pos + 1 + length
  end
end

local function first_txt(data)
  local answers = string.unpack(">I2", data, 7)
  if answers == 0 then return nil end

  local pos = skip_name(data, 13)
  if not pos then return nil end
  pos = pos + 4  -- question type and class

  pos = skip_name(data, pos)
  if not pos then return nil end
  local length = string.unpack(">I2", data, pos + 8)
  pos = pos + 10
  if length < 1 then return nil end

  -- The record data of a TXT record starts with a length byte.
  local text_length = string.byte(data, pos)
  return string.sub(data, pos + 1, pos + text_length)
end

action = function(host, port)
  local version_query = build_query(0x2a01, "version.bind", 16, 3, false)
  local response = ask(host, port, version_query)
  if not response or #response < 12 then return nil end

  local id, flags = string.unpack(">I2 I2", response)
  if id ~= 0x2a01 or (flags & 0x8000) == 0 then return nil end

  local out = stdnse.output_table()
  out["Version"] = first_txt(response)
  out["Response code"] = RCODES[flags & 0x0F] or (flags & 0x0F)

  -- A name the server cannot be authoritative for tells whether it recurses.
  local probe = ask(host, port, build_query(0x2a02, "example.com", 1, 1, true))
  if probe and #probe >= 12 then
    local probe_flags = string.unpack(">I2", probe, 3)
    -- Bit 7 of the second flags byte is "recursion available".
    out["Recursion"] = (probe_flags & 0x0080) ~= 0 and "offered" or "not offered"
  end

  port.version.name = "domain"
  if out["Version"] then
    port.version.product = out["Version"]
  end
  nmap.set_port_version(host, port)
  return out
end
