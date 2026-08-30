local nmap = require "nmap"
local shortport = require "shortport"
local stdnse = require "stdnse"
local string = require "string"
local table = require "table"

description = [[
Collects what an SMTP server announces to a client that has not authenticated.

The banner and the ESMTP extensions returned for EHLO are reported. The SASL
mechanisms, STARTTLS support and the accepted message size are pulled out of
the extension list, and VRFY is tried once: a server that verifies addresses
lets an attacker enumerate valid recipients.
]]

---
-- @usage
-- nmap -p 25 --script ./smtp.nse <host>
--
-- @output
-- PORT   STATE SERVICE
-- 25/tcp open  smtp
-- | smtp:
-- |   Banner: mail.aichi.example ESMTP Aichi-Mail 2.1.4 ready
-- |   Extensions: PIPELINING, 8BITMIME, ENHANCEDSTATUSCODES, HELP
-- |   Authentication: PLAIN, LOGIN
-- |   STARTTLS: supported
-- |   Maximum message size: 10485760 bytes
-- |_  VRFY: refused (252)

author = "kazuhitoyokoi"
license = "Same as Nmap--See https://nmap.org/book/man-legal.html"
categories = {"discovery", "safe", "version"}

portrule = shortport.port_or_service({25, 465, 587}, {"smtp", "smtps", "submission"}, "tcp")

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

-- SMTP continues a reply while the code is followed by a hyphen.
local function read_reply(read)
  local lines = {}
  while true do
    local line = read()
    if not line then return lines end
    lines[#lines + 1] = line
    if string.match(line, "^%d%d%d ") then return lines end
  end
end

action = function(host, port)
  local socket = nmap.new_socket()
  socket:set_timeout(5000)
  if not socket:connect(host, port) then return nil end
  local read = reader(socket)

  local greeting = read()
  if not greeting or string.sub(greeting, 1, 3) ~= "220" then
    socket:close()
    return nil
  end

  local out = stdnse.output_table()
  out["Banner"] = string.gsub(greeting, "^220[%s-]*", "")

  socket:send("EHLO nmap.scanme.org\r\n")
  local reply = read_reply(read)
  if #reply == 0 or not string.match(reply[1], "^250") then
    socket:close()
    return out
  end

  local extensions, mechanisms, starttls, size = {}, {}, false, nil
  for index, line in ipairs(reply) do
    local text = string.gsub(line, "^250[%s-]", "")
    if index > 1 then
      local keyword, rest = string.match(text, "^(%S+)%s*(.*)$")
      if keyword == "AUTH" then
        for mechanism in string.gmatch(rest, "%S+") do
          mechanisms[#mechanisms + 1] = mechanism
        end
      elseif keyword == "STARTTLS" then
        starttls = true
      elseif keyword == "SIZE" then
        size = rest
      elseif keyword then
        extensions[#extensions + 1] = keyword
      end
    end
  end

  if #extensions > 0 then
    out["Extensions"] = table.concat(extensions, ", ")
  end
  if #mechanisms > 0 then
    out["Authentication"] = table.concat(mechanisms, ", ")
  end
  out["STARTTLS"] = starttls and "supported" or "not offered"
  if size and size ~= "" then
    out["Maximum message size"] = size .. " bytes"
  end

  socket:send("VRFY root\r\n")
  local vrfy = read_reply(read)
  if #vrfy > 0 then
    local code = string.match(vrfy[#vrfy], "^(%d%d%d)")
    if code == "250" then
      out["VRFY"] = "accepted (" .. code .. "), recipients can be enumerated"
    else
      out["VRFY"] = "refused (" .. tostring(code) .. ")"
    end
  end

  socket:send("QUIT\r\n")
  socket:close()

  port.version.name = "smtp"
  nmap.set_port_version(host, port)
  return out
end
