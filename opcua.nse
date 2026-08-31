local datetime = require "datetime"
local nmap = require "nmap"
local shortport = require "shortport"
local stdnse = require "stdnse"
local string = require "string"
local table = require "table"

description = [[
Connects to an OPC UA server over the binary protocol (opc.tcp) and calls
GetEndpoints without opening a session.

Reports the endpoint URL that clients must use, the security mode and policy
of each endpoint, the user identity tokens the server accepts and the
server time taken from the response header. The server time is compared with
the scanning host clock and the difference is reported as the clock skew.
]]

---
-- @usage
-- nmap -p 4840 --script ./opcua.nse <host>
--
-- @output
-- PORT     STATE SERVICE
-- 4840/tcp open  opcua
-- | opcua:
-- |   Server time: 2026-08-29 15:42:43Z
-- |   Clock skew: +0s
-- |   Application URI: urn:freeopcua:python:server
-- |   Endpoint URL: opc.tcp://127.0.0.1:4840/freeopcua/server/
-- |   Security: None (http://opcfoundation.org/UA/SecurityPolicy#None)
-- |_  Authentication: Anonymous, UserName, Certificate

author = "kazuhitoyokoi"
license = "Same as Nmap--See https://nmap.org/book/man-legal.html"
categories = {"discovery", "safe"}

portrule = shortport.port_or_service({4840, 4841, 48010, 53530}, "opcua", "tcp")

local SECURITY_MODE = { [1] = "None", [2] = "Sign", [3] = "SignAndEncrypt" }
local TOKEN_TYPE = { [0] = "Anonymous", [1] = "UserName", [2] = "Certificate", [3] = "IssuedToken" }

local function enc_str(s)
  if not s then return string.pack("<i4", -1) end
  return string.pack("<i4", #s) .. s
end

local function dec_str(buf, pos)
  local len, p = string.unpack("<i4", buf, pos)
  if len < 0 then return nil, p end
  return string.sub(buf, p, p + len - 1), p + len
end

local function to_ticks(epoch)
  return (epoch + 11644473600) * 10000000
end

local function request_header()
  return "\x00\x00" .. string.pack("<i8", to_ticks(os.time())) .. string.pack("<I4", 1)
    .. string.pack("<I4", 0) .. enc_str(nil) .. string.pack("<I4", 10000)
    .. "\x00\x00\x00"
end

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

local function recv_message(read)
  local header = read(8)
  if not header then return nil end
  local size = string.unpack("<I4", header, 5)
  return string.sub(header, 1, 4), read(size - 8)
end

local function to_epoch(ticks)
  return ticks // 10000000 - 11644473600
end

local function format_skew(seconds)
  local sign = "+"
  if seconds < 0 then
    sign = "-"
    seconds = -seconds
  end
  if seconds < 60 then
    return string.format("%s%ds", sign, seconds)
  end
  if seconds < 3600 then
    return string.format("%s%dm%ds", sign, seconds // 60, seconds % 60)
  end
  if seconds < 86400 then
    return string.format("%s%dh%dm", sign, seconds // 3600, (seconds % 3600) // 60)
  end
  return string.format("%s%dd%dh", sign, seconds // 86400, (seconds % 86400) // 3600)
end

local function skip_response_header(buf, pos)
  local ticks
  ticks, pos = string.unpack("<i8", buf, pos)
  pos = pos + 4 + 4 + 1
  local n
  n, pos = string.unpack("<i4", buf, pos)
  for _ = 1, math.max(n, 0) do
    _, pos = dec_str(buf, pos)
  end
  return ticks, pos + 3
end

action = function(host, port)
  local url = string.format("opc.tcp://%s:%d/", host.ip, port.number)
  local socket = nmap.new_socket()
  socket:set_timeout(5000)

  if not socket:connect(host, port) then return nil end
  local read = make_reader(socket)

  local hello = string.pack("<I4I4I4I4I4", 0, 65536, 65536, 0, 0) .. enc_str(url)
  socket:send("HELF" .. string.pack("<I4", 8 + #hello) .. hello)
  local kind = recv_message(read)
  if kind ~= "ACKF" then
    socket:close()
    return nil
  end

  local sec = enc_str("http://opcfoundation.org/UA/SecurityPolicy#None") .. enc_str(nil) .. enc_str(nil)
  local opn = "\x01\x00" .. string.pack("<I2", 446) .. request_header()
    .. string.pack("<I4I4I4", 0, 0, 1) .. enc_str(nil) .. string.pack("<I4", 3600000)
  socket:send("OPNF" .. string.pack("<I4I4", 12 + #sec + 8 + #opn, 0) .. sec
    .. string.pack("<I4I4", 1, 1) .. opn)

  local body
  kind, body = recv_message(read)
  if kind ~= "OPNF" then
    socket:close()
    return nil
  end

  local pos = 5
  _, pos = dec_str(body, pos)
  _, pos = dec_str(body, pos)
  _, pos = dec_str(body, pos)
  pos = pos + 8 + 4
  local _, p2 = skip_response_header(body, pos)
  local channel, token = string.unpack("<I4I4", body, p2 + 4)

  local req = "\x01\x00" .. string.pack("<I2", 428) .. request_header()
    .. enc_str(url) .. string.pack("<i4", -1) .. string.pack("<i4", -1)
  socket:send("MSGF" .. string.pack("<I4I4I4I4I4", 24 + #req, channel, token, 2, 2) .. req)

  kind, body = recv_message(read)
  socket:close()
  if kind ~= "MSGF" then return nil end

  pos = 21
  local ticks
  ticks, pos = skip_response_header(body, pos)

  local server_epoch = to_epoch(ticks)
  local skew = server_epoch - os.time()

  datetime.record_skew(host, server_epoch, os.time())

  local out = stdnse.output_table()
  out["Server time"] = os.date("!%Y-%m-%d %H:%M:%SZ", server_epoch)
  out["Clock skew"] = format_skew(skew)

  local urls, seen, security = {}, {}, {}
  local count
  count, pos = string.unpack("<i4", body, pos)
  for _ = 1, math.max(count, 0) do
    local endpoint_url, app_uri, mask, policy, mode, n
    endpoint_url, pos = dec_str(body, pos)
    app_uri, pos = dec_str(body, pos)
    _, pos = dec_str(body, pos)
    mask, pos = string.unpack("<I1", body, pos)
    if mask & 1 == 1 then _, pos = dec_str(body, pos) end
    if mask & 2 == 2 then _, pos = dec_str(body, pos) end
    pos = pos + 4
    _, pos = dec_str(body, pos)
    _, pos = dec_str(body, pos)
    n, pos = string.unpack("<i4", body, pos)
    for _ = 1, math.max(n, 0) do _, pos = dec_str(body, pos) end
    _, pos = dec_str(body, pos)
    mode, pos = string.unpack("<I4", body, pos)
    policy, pos = dec_str(body, pos)

    local tokens = {}
    n, pos = string.unpack("<i4", body, pos)
    for _ = 1, math.max(n, 0) do
      local ttype
      _, pos = dec_str(body, pos)
      ttype, pos = string.unpack("<I4", body, pos)
      _, pos = dec_str(body, pos)
      _, pos = dec_str(body, pos)
      _, pos = dec_str(body, pos)
      tokens[#tokens + 1] = TOKEN_TYPE[ttype] or ("Unknown(" .. ttype .. ")")
    end
    _, pos = dec_str(body, pos)
    pos = pos + 1

    out["Application URI"] = out["Application URI"] or app_uri

    -- The URLs are listed on their own so that they can be copied straight
    -- into a client such as UA Expert. A server usually repeats the same URL
    -- for every security setting, so duplicates are dropped.
    if endpoint_url and not seen[endpoint_url] then
      seen[endpoint_url] = true
      urls[#urls + 1] = endpoint_url
    end

    security[#security + 1] = string.format("%s (%s), authentication: %s",
      SECURITY_MODE[mode] or mode,
      string.gsub(policy or "unknown", "^.*#", ""),
      #tokens > 0 and table.concat(tokens, ", ") or "none")
  end

  if #out > 0 then
    out["Endpoint URLs"] = urls
    out["Security"] = security

  port.version.name = "opcua"
    nmap.set_port_version(host, port)
    return out
  end
end
