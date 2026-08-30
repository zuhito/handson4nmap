local http = require "http"
local json = require "json"
local nmap = require "nmap"
local shortport = require "shortport"
local stdnse = require "stdnse"
local string = require "string"
local table = require "table"

description = [[
Identifies a Grafana server and reports what it exposes without
authentication.

The health endpoint answers before a user logs in and carries the version, the
build commit and the state of the backend database. The script also checks
whether the frontend settings endpoint is readable, which tells whether
anonymous access is enabled on the instance.

When the grafana.username and grafana.password arguments are given the script
authenticates against the API and additionally reports the organisation, the
user accounts, the configured data sources and the instance statistics.
]]

---
-- @usage
-- nmap -p 3000 --script grafana.nse <host>
--
-- @args grafana.root the sub path Grafana is served from. Default: /
-- @args grafana.username user name for the Grafana API
-- @args grafana.password password for the Grafana API
--
-- With credentials the script additionally reports the organisation, the
-- accounts, the configured data sources and the instance statistics.
--
-- @output
-- PORT     STATE SERVICE
-- 3000/tcp open  grafana
-- | grafana:
-- |   Version: 13.2.0
-- |   Build commit: f681b1359f6a
-- |   Database: ok
-- |   Anonymous access: disabled
-- |   Organisation: Main Org.
-- |   Users: admin (Admin, admin@localhost)
-- |   Data sources: none configured
-- |_  Statistics: 1 users, 0 dashboards, 0 datasources

author = "kazuhitoyokoi"
license = "Same as Nmap--See https://nmap.org/book/man-legal.html"
categories = {"discovery", "safe", "version"}

portrule = shortport.port_or_service({3000, 8080}, {"grafana", "http-alt"}, "tcp")

local function join(root, endpoint)
  if not root:match("/$") then root = root .. "/" end
  if not root:match("^/") then root = "/" .. root end
  return root .. endpoint
end

-- Requests an API endpoint with HTTP basic authentication and returns the
-- decoded document.
local function api(host, port, root, endpoint, username, password)
  local options = {auth = {username = username, password = password}}
  local response = http.get(host, port, join(root, endpoint), options)
  if not response or response.status ~= 200 or not response.body then
    return nil, response and response.status or nil
  end
  local ok, doc = json.parse(response.body)
  if not ok then return nil, response.status end
  return doc, response.status
end

local function authenticated(host, port, root, username, password, out)
  local org, status = api(host, port, root, "api/org", username, password)
  if not org then
    out["Credentials"] = status == 401 and "rejected" or "no answer"
    return
  end
  out["Credentials"] = "accepted"
  out["Organisation"] = org.name

  -- api/users leaves the role empty, the organisation view carries it.
  local users = api(host, port, root, "api/org/users", username, password)
  if type(users) == "table" then
    local names = {}
    for _, user in ipairs(users) do
      names[#names + 1] = string.format("%s (%s, %s)",
        user.login or "unknown", user.role or "unknown", user.email or "unknown")
    end
    if #names > 0 then
      out["Users"] = table.concat(names, ", ")
    end
  end

  local sources = api(host, port, root, "api/datasources", username, password)
  if type(sources) == "table" then
    local names = {}
    for _, source in ipairs(sources) do
      names[#names + 1] = string.format("%s (%s, %s)",
        source.name or "unknown", source.type or "unknown", source.url or "no url")
    end
    out["Data sources"] = #names > 0 and table.concat(names, ", ") or "none configured"
  end

  local stats = api(host, port, root, "api/admin/stats", username, password)
  if type(stats) == "table" and stats.users then
    out["Statistics"] = string.format("%d users, %d dashboards, %d datasources",
      stats.users, stats.dashboards or 0, stats.datasources or 0)
  end
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

  local username = stdnse.get_script_args(SCRIPT_NAME .. ".username")
  local password = stdnse.get_script_args(SCRIPT_NAME .. ".password")
  if username and password then
    authenticated(host, port, root, username, password, out)
  end

  port.version.name = "grafana"
  port.version.product = "Grafana"
  port.version.version = doc.version
  nmap.set_port_version(host, port)
  return out
end
