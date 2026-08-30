local http = require "http"
local json = require "json"
local nmap = require "nmap"
local shortport = require "shortport"
local stdnse = require "stdnse"
local string = require "string"
local table = require "table"

description = [[
Identifies an InfluxDB server through its HTTP API.

The version and the build flavour are taken from the headers of /ping, which
every InfluxDB instance answers without authentication. The script then asks
for the database list with SHOW DATABASES. A server that answers it is
readable without credentials, which is reported together with the names of
the databases it exposes.
]]

---
-- @usage
-- nmap -p 8086 --script ./influxdb.nse <host>
--
-- @output
-- PORT     STATE SERVICE
-- 8086/tcp open  influxdb
-- | influxdb:
-- |   Version: 1.6.7
-- |   Build: OSS
-- |   Authentication: not required
-- |_  Databases: _internal, plant

author = "kazuhitoyokoi"
license = "Same as Nmap--See https://nmap.org/book/man-legal.html"
categories = {"discovery", "safe", "version"}

portrule = shortport.port_or_service(8086, "influxdb", "tcp")

local function databases(host, port)
  local response = http.get(host, port, "/query?q=SHOW+DATABASES")
  if not response then
    return nil, "unknown"
  end
  -- 401 is returned when credentials are missing, 403 when the server has
  -- authentication enabled but no user has been created yet.
  if response.status == 401 or response.status == 403 then
    return nil, "required"
  end
  if response.status ~= 200 or not response.body then
    return nil, "unknown"
  end

  local ok, doc = json.parse(response.body)
  if not ok or type(doc) ~= "table" or type(doc.results) ~= "table" then
    return nil, "unknown"
  end

  local names = {}
  for _, result in ipairs(doc.results) do
    for _, series in ipairs(result.series or {}) do
      for _, row in ipairs(series.values or {}) do
        names[#names + 1] = row[1]
      end
    end
  end
  return names, "not required"
end

action = function(host, port)
  local ping = http.get(host, port, "/ping")
  if not ping or not ping.header then return nil end

  local version = ping.header["x-influxdb-version"]
  if not version then return nil end

  local out = stdnse.output_table()
  out["Version"] = version
  out["Build"] = ping.header["x-influxdb-build"]

  local names, auth = databases(host, port)
  out["Authentication"] = auth
  if names and #names > 0 then
    out["Databases"] = table.concat(names, ", ")
  end

  port.version.name = "influxdb"
  port.version.product = "InfluxDB"
  port.version.version = version
  nmap.set_port_version(host, port)
  return out
end
