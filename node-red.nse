local http = require "http"
local json = require "json"
local shortport = require "shortport"
local stdnse = require "stdnse"
local string = require "string"
local table = require "table"

description = [[
Retrieves runtime information from the Node-RED admin API diagnostics
endpoint (GET /diagnostics).

The endpoint is served only when "diagnostics.enabled" is true in
settings.js. When the admin API is not protected by adminAuth, it is
readable without authentication and discloses the Node-RED version, the
Node.js version and details about the host operating system.
]]

---
-- @usage
-- nmap -p 1880 --script ./node-red.nse <host>
--
-- @args node-red.root the httpAdminRoot value of the target.
--       Default: /
--
-- @output
-- PORT     STATE SERVICE
-- 1880/tcp open  vsat-control
-- | node-red:
-- |   Node-RED: 3.0.2
-- |   Node.js: v16.16.0 (linux/x64)
-- |_  OS: Linux 5.15.85-1-MANJARO (x64)

author = "Claude"
license = "Same as Nmap--See https://nmap.org/book/man-legal.html"
categories = {"discovery", "safe"}

portrule = shortport.port_or_service({1880, 1881}, {"http", "http-alt"}, "tcp")

local function join_path(root, endpoint)
  if not root:match("/$") then
    root = root .. "/"
  end
  if not root:match("^/") then
    root = "/" .. root
  end
  return root .. endpoint
end

action = function(host, port)
  local root = stdnse.get_script_args(SCRIPT_NAME .. ".root") or "/"
  local path = join_path(root, "diagnostics")

  local response = http.get(host, port, path, {
    header = { ["Accept"] = "application/json" }
  })

  if not response or not response.status then
    return nil
  end

  if response.status == 401 or response.status == 403 then
    return string.format("%s requires authentication (HTTP %d)", path, response.status)
  end

  if response.status ~= 200 or not response.body then
    return nil
  end

  local ok, doc = json.parse(response.body)
  if not ok or type(doc) ~= "table" or doc.report ~= "diagnostics" then
    return nil
  end

  local out = stdnse.output_table()

  if type(doc.runtime) == "table" then
    out["Node-RED"] = doc.runtime.version
  end

  if type(doc.nodejs) == "table" then
    out["Node.js"] = string.format("%s (%s/%s)",
      doc.nodejs.version or "unknown",
      doc.nodejs.platform or "unknown",
      doc.nodejs.arch or "unknown")
  end

  if type(doc.os) == "table" then
    out["OS"] = string.format("%s %s (%s)",
      doc.os.type or "unknown",
      doc.os.release or "unknown",
      doc.os.arch or "unknown")
  end

  if #out > 0 then
    return out
  end
end
