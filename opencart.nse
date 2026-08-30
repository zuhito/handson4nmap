local http = require "http"
local nmap = require "nmap"
local shortport = require "shortport"
local stdnse = require "stdnse"
local string = require "string"

description = [[
Identifies an OpenCart storefront and reports what it exposes.

The storefront is recognised by the markup OpenCart emits, the administration
panel is looked up at its default location and the installation directory is
probed. OpenCart tells the administrator to delete that directory once the
setup is finished, so finding it still in place is worth reporting. When the
administration login page carries a version string it is reported as well.
]]

---
-- @usage
-- nmap -p 8081 --script opencart.nse <host>
--
-- @args opencart.root the sub path the shop is served from. Default: /
--
-- @output
-- PORT     STATE SERVICE
-- 8081/tcp open  opencart
-- | opencart:
-- |   Storefront: /index.php
-- |   Admin panel: /admin/ (reachable)
-- |_  Install directory: present (should be removed after setup)

author = "kazuhitoyokoi"
license = "Same as Nmap--See https://nmap.org/book/man-legal.html"
categories = {"discovery", "safe"}

portrule = shortport.port_or_service({80, 443, 8080, 8081}, {"http", "https", "http-alt"}, "tcp")

local function join(root, endpoint)
  if not root:match("/$") then root = root .. "/" end
  if not root:match("^/") then root = "/" .. root end
  return root .. endpoint
end

local function is_opencart(body)
  if not body then return false end
  return body:find("opencart%-logo") ~= nil
    or body:find("Powered By%s*<a[^>]*opencart") ~= nil
    or body:find("www%.opencart%.com") ~= nil
end

action = function(host, port)
  local root = stdnse.get_script_args(SCRIPT_NAME .. ".root") or "/"

  local store = http.get(host, port, join(root, "index.php"))
  if not store or store.status ~= 200 or not is_opencart(store.body) then
    return nil
  end

  local out = stdnse.output_table()
  out["Storefront"] = join(root, "index.php")

  local admin = http.get(host, port, join(root, "admin/index.php?route=common/login"))
  if admin and admin.status == 200 and is_opencart(admin.body) then
    out["Admin panel"] = join(root, "admin/") .. " (reachable)"
    local version = admin.body:match("Version%s+([%d%.]+)")
    if version then
      out["Version"] = version
    end
  else
    out["Admin panel"] = "not at the default location"
  end

  local install = http.get(host, port, join(root, "install/index.php"))
  if install and (install.status == 200 or install.status == 302) then
    out["Install directory"] = "present (should be removed after setup)"
  else
    out["Install directory"] = "removed"
  end

  port.version.name = "opencart"
  port.version.product = "OpenCart"
  nmap.set_port_version(host, port)
  return out
end
