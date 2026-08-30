local http = require "http"
local json = require "json"
local nmap = require "nmap"
local shortport = require "shortport"
local stdnse = require "stdnse"
local string = require "string"

description = [[
Identifies a Grafana server and reports what it exposes without
authentication.

The health endpoint answers before a user logs in and carries the version, the
build commit and the state of the backend database. The script also checks
whether the frontend settings endpoint is readable, which tells whether
anonymous access is enabled on the instance.
]]

---
-- @usage
-- nmap -p 3000 --script grafana.nse <host>
--
-- @args grafana.root the sub path Grafana is served from. Default: /
--
-- @output
-- PORT     STATE SERVICE
-- 3000/tcp open  grafana
-- | grafana:
-- |   Version: 13.2.0
-- |   Build commit: f681b1359f6a
-- |   Database: ok
-- |_  Anonymous access: disabled

author = "kazuhitoyokoi"
license = "Same as Nmap--See https://nmap.org/book/man-legal.html"
categories = {"discovery", "safe", "version"}

portrule = shortport.port_or_service({3000, 8080}, {"grafana", "http-alt"}, "tcp")

local function join(root, endpoint)
  if not root:match("/$") then root = root .. "/" end
  if not root:match("^/") then root = "/" .. root end
  return root .. endpoint
end

action = function(host, port)
  local root = stdnse.get_script_args(SCRIPT_NAME .. ".root") or "/"

  local health = http.get(host, port, join(root, "api/health"))
  if not health or health.status ~= 200 or not health.body then
    return nil
  end

  local ok, doc = json.parse(health.body)
  if not ok or type(doc) ~= "table" or not doc.version then
    return nil
  end

  local out = stdnse.output_table()
  out["Version"] = doc.version
  if doc.commit then
    out["Build commit"] = string.sub(doc.commit, 1, 12)
  end
  out["Database"] = doc.database

  -- The frontend settings are only readable without a session when anonymous
  -- access is turned on.
  local settings = http.get(host, port, join(root, "api/frontend/settings"))
  if settings and settings.status == 200 then
    out["Anonymous access"] = "enabled"
  else
    out["Anonymous access"] = "disabled"
  end

  port.version.name = "grafana"
  port.version.product = "Grafana"
  port.version.version = doc.version
  nmap.set_port_version(host, port)
  return out
end
