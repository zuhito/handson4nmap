local nmap = require "nmap"
local shortport = require "shortport"
local stdnse = require "stdnse"
local string = require "string"
local table = require "table"

description = [[
Connects to an MQTT broker and reports what the broker announces in its
CONNACK packet.

The script first offers MQTT 5.0. Brokers that only speak 3.1.1 answer with
an unsupported protocol version, in which case the probe is repeated with
3.1.1 so that the protocol level is reported accurately. The connect reason
code shows whether the broker accepts anonymous clients, and the CONNACK
properties expose broker limits such as the maximum packet size, the maximum
QoS and whether retained messages are available.
]]

---
-- @usage
-- nmap -p 1883 --script ./mqtt.nse <host>
--
-- @output
-- PORT     STATE SERVICE
-- 1883/tcp open  mqtt
-- | mqtt:
-- |   Protocol: MQTT 5.0
-- |   Connection: Success
-- |   Anonymous access: allowed
-- |   Session present: no
-- |   Receive maximum: 20
-- |   Maximum packet size: 65535
-- |_  Topic alias maximum: 10

author = "kazuhitoyokoi"
license = "Same as Nmap--See https://nmap.org/book/man-legal.html"
categories = {"discovery", "safe", "version"}

portrule = shortport.port_or_service({1883, 8883}, {"mqtt", "secure-mqtt"}, "tcp")

local V5_REASONS = {
  [0x00] = "Success",
  [0x80] = "Unspecified error",
  [0x81] = "Malformed packet",
  [0x82] = "Protocol error",
  [0x83] = "Implementation specific error",
  [0x84] = "Unsupported protocol version",
  [0x85] = "Client identifier not valid",
  [0x86] = "Bad user name or password",
  [0x87] = "Not authorized",
  [0x88] = "Server unavailable",
  [0x89] = "Server busy",
  [0x8A] = "Banned",
  [0x8C] = "Bad authentication method",
  [0x90] = "Topic name invalid",
  [0x95] = "Packet too large",
  [0x97] = "Quota exceeded",
  [0x99] = "Payload format invalid",
  [0x9A] = "Retain not supported",
  [0x9B] = "QoS not supported",
  [0x9C] = "Use another server",
  [0x9D] = "Server moved",
  [0x9F] = "Connection rate exceeded",
}

local V3_REASONS = {
  [0] = "Success",
  [1] = "Unacceptable protocol version",
  [2] = "Client identifier rejected",
  [3] = "Server unavailable",
  [4] = "Bad user name or password",
  [5] = "Not authorized",
}

-- CONNACK property identifiers and how they are encoded
local BYTE_PROPS = {
  [0x24] = "Maximum QoS",
  [0x25] = "Retain available",
  [0x28] = "Wildcard subscription available",
  [0x29] = "Subscription identifiers available",
  [0x2A] = "Shared subscription available",
}

local SHORT_PROPS = {
  [0x13] = "Server keep alive",
  [0x21] = "Receive maximum",
  [0x22] = "Topic alias maximum",
}

local INT_PROPS = {
  [0x11] = "Session expiry interval",
  [0x27] = "Maximum packet size",
}

local STRING_PROPS = {
  [0x12] = "Assigned client identifier",
  [0x1A] = "Response information",
  [0x1C] = "Server reference",
  [0x1F] = "Reason string",
}

local function encode_length(n)
  local out = {}
  repeat
    local byte = n % 128
    n = n // 128
    if n > 0 then byte = byte | 0x80 end
    out[#out + 1] = string.char(byte)
  until n == 0
  return table.concat(out)
end

local function decode_length(buf, pos)
  local value, multiplier = 0, 1
  repeat
    local byte
    byte, pos = string.unpack("<B", buf, pos)
    value = value + (byte & 0x7F) * multiplier
    multiplier = multiplier * 128
  until byte & 0x80 == 0
  return value, pos
end

local function mqtt_string(s)
  return string.pack(">s2", s)
end

local function connect_packet(version)
  local payload = mqtt_string("nmap")
  local variable = mqtt_string("MQTT") .. string.pack(">B B I2", version, 0x02, 15)
  if version == 5 then
    variable = variable .. "\x00"
  end
  local body = variable .. payload
  return "\x10" .. encode_length(#body) .. body
end

local function read_packet(socket)
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

  local first = read(1)
  if not first then return nil end

  local length, multiplier, byte = 0, 1, nil
  repeat
    local raw = read(1)
    if not raw then return nil end
    byte = string.byte(raw)
    length = length + (byte & 0x7F) * multiplier
    multiplier = multiplier * 128
  until byte & 0x80 == 0

  return string.byte(first), read(length) or ""
end

local function parse_properties(buf, pos, out)
  local length
  length, pos = decode_length(buf, pos)
  local stop = pos + length

  while pos < stop do
    local id
    id, pos = string.unpack("<B", buf, pos)

    if BYTE_PROPS[id] then
      local value
      value, pos = string.unpack("<B", buf, pos)
      out[BYTE_PROPS[id]] = value
    elseif SHORT_PROPS[id] then
      local value
      value, pos = string.unpack(">I2", buf, pos)
      out[SHORT_PROPS[id]] = value
    elseif INT_PROPS[id] then
      local value
      value, pos = string.unpack(">I4", buf, pos)
      out[INT_PROPS[id]] = value
    elseif STRING_PROPS[id] then
      local value
      value, pos = string.unpack(">s2", buf, pos)
      out[STRING_PROPS[id]] = value
    elseif id == 0x26 then
      local key, value
      key, pos = string.unpack(">s2", buf, pos)
      value, pos = string.unpack(">s2", buf, pos)
      out["User property " .. key] = value
    else
      return
    end
  end
end

local function probe(host, port, version)
  local socket = nmap.new_socket()
  socket:set_timeout(5000)
  if not socket:connect(host, port) then return nil end
  socket:send(connect_packet(version))
  local kind, body = read_packet(socket)
  socket:close()
  if kind ~= 0x20 or #body < 2 then return nil end
  return body
end

action = function(host, port)
  local version = 5
  local body = probe(host, port, version)
  if not body then return nil end

  local session, code = string.unpack("<B B", body)

  if version == 5 and code == 0x84 then
    version = 4
    body = probe(host, port, version)
    if not body then return nil end
    session, code = string.unpack("<B B", body)
  end

  local out = stdnse.output_table()
  out["Protocol"] = version == 5 and "MQTT 5.0" or "MQTT 3.1.1"

  local reason = version == 5 and V5_REASONS[code] or V3_REASONS[code]
  out["Connection"] = string.format("%s (0x%02x)", reason or "unknown", code)
  out["Anonymous access"] = code == 0 and "allowed" or "denied"
  out["Session present"] = (session & 0x01) == 1 and "yes" or "no"

  if version == 5 and #body > 2 then
    parse_properties(body, 3, out)
  end

  port.version.name = "mqtt"
  nmap.set_port_version(host, port)
  return out
end
