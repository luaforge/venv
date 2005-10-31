#!/usr/local/bin/lua50

print("testing virtual environment")

t1 = { t2 = { t3 = "ok" } }
GLOBAL = _G
x = "outside"
OS_DATE = tostring(os.date)
DATE_FORMAT = "%Y%-%m%-%d"
DATE = os.date (DATE_FORMAT)

require"venv"

execs = {}
local current
function step(v, r)
	if not execs[v] then
		execs[v] = {}
	end
	execs[v][r] = {}
	current = execs[v][r]
end
function log (k,v) current[k] = v end

-- Function to test inside virtual environments
function main()
  step(VirtualEnv, Run)
  log("_G",tostring(_G))
  log("package",tostring(package))
  log("package.loaded",tostring(package.loaded))
  assert((t1.t2.t3 == "ok"), "error accessing multi-indexed var")
  os.execute = nil
  getenv = function(s) return "asked for "..s end
  loadfile("script.lua")()
  dofile("script2.lua")
--[[
  -- manual loading of chunk
  local fh = assert(io.open("script3.lua"))
  local chunk = assert(fh:read"*a")
  fh:close()
  local f = assert(loadstring(chunk, "@script3.lua"))
  f()
--]]
end

print("------------------------run 1--------------------------")
VirtualEnv = 1
Run = 1
local old_pack_lfs = package.loaded.lfs
assert (old_pack_lfs == nil, "test assumes lfs is not loaded!")
local prot_main = venv(main)
prot_main()
assert((x=="outside"),"variable x modified by venv!")
assert((var1==nil),"venv modified external env!")
assert(package.loaded.lfs ~= old_pack_lfs, "could not modify external package.loaded table")

print("\n------------------------run 2--------------------------")
Run = 2
prot_main()
assert((x=="outside"),"variable x modified by venv!")
assert((var1==nil),"venv modified external env!")

print("\n-------------------------------------------------------")
print("--- new virtual environment")
print("-------------------------------------------------------")
print("\n------------------------run 1--------------------------")
VirtualEnv = 2
Run = 1
prot_main = venv (main)
prot_main()
assert((x=="outside"),"variable x modified by venv!")
assert((var1==nil),"venv modified external env!")

print("\n------------------------run 2--------------------------")
Run = 2
prot_main()
assert((x=="outside"),"variable x modified by venv!")
assert((var1==nil),"venv modified external env!")

print("\n*************** FIM TESTE OK! ******************")
