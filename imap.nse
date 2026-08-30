local nmap = require "nmap"
local shortport = require "shortport"
local stdnse = require "stdnse"
local string = require "string"
local table = require "table"

description = [[
Collects what an IMAP server discloses before a client logs in.

The greeting, the CAPABILITY list and the RFC 2971 ID response are requested
in turn. From the capabilities the script reports the supported SASL
mechanisms, whether STARTTLS is offered and whether plaintext logins are
refused, which shows how the server is configured without authenticating.
]]

---
-- @usage
-- nmap -p 143 --script ./imap.nse <host>
--
-- @output
-- PORT    STATE SERVICE
-- 143/tcp open  imap
-- | imap:
-- |   Greeting: Aichi Mail IMAP4rev1 ready
-- |   Capabilities: IMAP4rev1, STARTTLS, LOGINDISABLED, IDLE, NAMESPACE, UIDPLUS, ID
-- |   Authentication: PLAIN, LOGIN
-- |   STARTTLS: supported
-- |   Plaintext login: disabled
-- |_  Server ID: name Aichi Mail, version 2.1.4, os Linux

author = "kazuhitoyokoi"
license = "Same as Nmap--See https://nmap.org/book/man-legal.html"
categories = {"discovery", "safe", "version"}

portrule = shortport.port_or_service({143, 993}, {"imap", "imaps"}, "tcp")

local function reader(socket)
  local pending = ""
  return function()
    while true do
      local line, rest = string.match(pending, "^([^\r\n]*)\r?\n(.*)$")
      if line then
        pending = rest
        return line
      end
      local status, data = socket:receive()
      if not status then return nil end
      pending = pending .. data
    end
  end
end

-- Reads untagged lines until the response for the given tag arrives.
local function collect(read, tag)
  local untagged = {}
  while true do
    local line = read()
    if not line then return untagged, nil end
    if string.sub(line, 1, #tag + 1) == tag .. " " then
      return untagged, line
    end
    untagged[#untagged + 1] = line
  end
end

local function split_words(text)
  local words = {}
  for word in string.gmatch(text, "%S+") do
    words[#words + 1] = word
  end
  return words
end

action = function(host, port)
  local socket = nmap.new_socket()
  socket:set_timeout(5000)
  if not socket:connect(host, port) then return nil end
  local read = reader(socket)

  local greeting = read()
  if not greeting or string.sub(greeting, 1, 4) ~= "* OK" then
    socket:close()
    return nil
  end

  local out = stdnse.output_table()
  -- Strip the leading "* OK" and any capability list in square brackets.
  local banner = string.gsub(greeting, "^%* OK ", "")
  banner = string.gsub(banner, "^%[[^%]]*%]%s*", "")
  out["Greeting"] = banner

  socket:send("a1 CAPABILITY\r\n")
  local untagged = collect(read, "a1")

  local capabilities, mechanisms = {}, {}
  for _, line in ipairs(untagged) do
    if string.sub(line, 1, 13) == "* CAPABILITY " then
      for _, word in ipairs(split_words(string.sub(line, 14))) do
        local mechanism = string.match(word, "^AUTH=(.+)$")
        if mechanism then
          mechanisms[#mechanisms + 1] = mechanism
        else
          capabilities[#capabilities + 1] = word
        end
      end
    end
  end

  if #capabilities == 0 and #mechanisms == 0 then
    socket:close()
    return out
  end

  out["Capabilities"] = table.concat(capabilities, ", ")
  if #mechanisms > 0 then
    out["Authentication"] = table.concat(mechanisms, ", ")
  end

  local starttls, logindisabled = false, false
  for _, capability in ipairs(capabilities) do
    if capability == "STARTTLS" then starttls = true end
    if capability == "LOGINDISABLED" then logindisabled = true end
  end
  out["STARTTLS"] = starttls and "supported" or "not offered"
  out["Plaintext login"] = logindisabled and "disabled" or "allowed"

  socket:send('a2 ID ("name" "nmap")\r\n')
  untagged = collect(read, "a2")
  for _, line in ipairs(untagged) do
    local fields = string.match(line, "^%* ID %((.*)%)$")
    if fields then
      local pairs_out = {}
      for key, value in string.gmatch(fields, '"([^"]+)"%s+"([^"]+)"') do
        pairs_out[#pairs_out + 1] = key .. " " .. value
      end
      if #pairs_out > 0 then
        out["Server ID"] = table.concat(pairs_out, ", ")
      end
    end
  end

  socket:send("a3 LOGOUT\r\n")
  socket:close()

  port.version.name = "imap"
  nmap.set_port_version(host, port)
  return out
end
