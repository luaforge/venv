print("\n** script 2 loaded **")
assert((_G ~= GLOBAL), "script is not inside a venv!")

var1 = "var1"
assert(GLOBAL.var1 == nil, "venv modified external env!")
tab = { f1 = "f1", f2="f2"}
local function f()
  print("\nglobals in nested environment: ")
  local g=""
  for i in pairs(_G) do g = g.." "..i end
  print(g)

  assert(var1 == "var1", "error inheriting global")
  assert(string.lower("ANA") == "ana", "error inheriting global")
  var1 = "mudei"
  assert(var1 == "mudei", "error modifying var inside venv")
  var1 = nil
  assert(var1 == nil, "global in venv should not have been re-inherited")
  string.lower = nil
  assert(string.upper("ana") == "ANA", "error inheriting global")
  assert(string.lower == nil, "global in venv should not have been re-inherited")
  tab.f1 = nil
  assert(tab.f1 == nil, "global in venv should not have beem re-inherited")
  assert(tab.f2 == "f2", "error inheriting global")
  string = nil 
  assert(string == nil, "global in venv should not have been re-inherited")
  print = nil
end

local prot2 = venv(f)
prot2()
assert(var1 == "var1", "internal venv modified external venv!")
assert(tab.f1 == "f1", "internal venv modified external venv!")
print("script 2 OK!")
