local nmap = require "nmap"
local shortport = require "shortport"
local stdnse = require "stdnse"
local string = require "string"
local table = require "table"

description = [[
Collects what a POP3 server discloses before a client authenticates.

The greeting is reported together with the CAPA list. A greeting that carries
a token in angle brackets means the server offers APOP, so the script points
that out: APOP hashes the password with a challenge instead of sending it in
the clear. The SASL mechanisms and the availability of STLS are reported
separately from the remaining capabilities.
]]

---
-- @usage
-- nmap -p 110 --script ./pop3.nse <host>
--
-- @output
-- PORT    STATE SERVICE
-- 110/tcp open  pop3
-- | pop3:
-- |   Greeting: Aichi Mail POP3 server ready
-- |   Capabilities: TOP, USER, UIDL, PIPELINING, RESP-CODES
-- |   Authentication: PLAIN, LOGIN
-- |   APOP: supported
-- |   STLS: supported
-- |_  Implementation: Aichi-Mail-POP3 2.1.4

author = "kazuhitoyokoi"
license = "Same as Nmap--See https://nmap.org/book/man-legal.html"
categories = {"discovery", "safe", "version"}

portrule = shortport.port_or_service({110, 995}, {"pop3", "pop3s"}, "tcp")

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

action = function(host, port)
  local socket = nmap.new_socket()
  socket:set_timeout(5000)
  if not socket:connect(host, port) then return nil end
  local read = reader(socket)

  local greeting = read()
  if not greeting or string.sub(greeting, 1, 3) ~= "+OK" then
    socket:close()
    return nil
  end

  local out = stdnse.output_table()
  local challenge = string.match(greeting, "(<[^>]+>)%s*$")
  local banner = string.gsub(greeting, "^%+OK%s*", "")
  if challenge then
    banner = string.gsub(banner, "%s*" .. string.gsub(challenge, "[%p]", "%%%0") .. "$", "")
  end
  out["Greeting"] = banner

  socket:send("CAPA\r\n")
  local first = read()
  if not first or string.sub(first, 1, 3) ~= "+OK" then
    socket:close()
    out["APOP"] = challenge and "supported" or "not offered"
    return out
  end

  local capabilities, mechanisms, stls, implementation = {}, {}, false, nil
  while true do
    local line = read()
    if not line or line == "." then break end
    local keyword, rest = string.match(line, "^(%S+)%s*(.*)$")
    if keyword == "SASL" then
      for mechanism in string.gmatch(rest, "%S+") do
        mechanisms[#mechanisms + 1] = mechanism
      end
    elseif keyword == "STLS" then
      stls = true
    elseif keyword == "IMPLEMENTATION" then
      implementation = rest
    elseif keyword then
      capabilities[#capabilities + 1] = keyword
    end
  end

  socket:send("QUIT\r\n")
  socket:close()

  if #capabilities > 0 then
    out["Capabilities"] = table.concat(capabilities, ", ")
  end
  if #mechanisms > 0 then
    out["Authentication"] = table.concat(mechanisms, ", ")
  end
  out["APOP"] = challenge and "supported" or "not offered"
  out["STLS"] = stls and "supported" or "not offered"
  out["Implementation"] = implementation

  port.version.name = "pop3"
  nmap.set_port_version(host, port)
  return out
end
