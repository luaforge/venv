#!/usr/local/bin/lua

print("testing virtual environment")

t1 = { t2 = { t3 = "ok" } }
GLOBAL = _G
x = "outside"

require"venv"

function main()
  assert((t1.t2.t3 == "ok"), "error accessing multi-indexed var")
  os.execute = nil
  getenv = function(s) return "asked for "..s end
  loadfile("script.lua")()
  dofile("script2.lua")
end

print("------------------------run 1--------------------------")
VirtualEnv = 1
local prot_main = venv(main)
prot_main()
assert((x=="outside"),"variable x modified by venv!")
assert((var1==nil),"venv modified external env!")

print("\n------------------------run 2--------------------------")
prot_main()
assert((x=="outside"),"variable x modified by venv!")
assert((var1==nil),"venv modified external env!")

print("\n-------------------------------------------------------")
print("--- new virtual environment")
print("-------------------------------------------------------")
print("\n------------------------run 1--------------------------")
VirtualEnv = 2
prot_main = venv (main)
prot_main()
assert((x=="outside"),"variable x modified by venv!")
assert((var1==nil),"venv modified external env!")

print("\n------------------------run 2--------------------------")
prot_main()
assert((x=="outside"),"variable x modified by venv!")
assert((var1==nil),"venv modified external env!")

print("\n*************** FIM TESTE OK! ******************")
