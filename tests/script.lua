print("** script 1 loaded **")
assert((_G ~= GLOBAL), "script is not inside venv!")

print("\nglobals in script1 environment: ")
local g=""
for i in pairs(_G) do g = g.." "..i end
print(g)

x = "inside"
assert((x == "inside"), "error setting/accessing var x inside venv", x)

local status, msg = pcall(require, "no_lib")
assert (status == false and string.find (msg, "couldn't load package"),
	"error while require-ing a non-existent file")

local status, msg = pcall (require, "lib_err")
assert (status == false and string.find (msg, "`)' expected near `,'"),
	"error while require-ing a mal-formed Lua file")

require"lib1"
assert(type(lib1) == "table", "error loading lib1")

local x1, t1, s1 = lib1.xp (x)
assert(x1 == true and t1 == "string", 
       "error calling lib1.xp, got >> '"..tostring(x1).."'("..tostring(t1)..")")

print()
require"dir"
print("current dir: ", dir.getcwd())
print()
print("running in venv:", VirtualEnv, "state:", s1)
print("os.date must be inherited >> ".. os.date())
print("getenv must have been redefined >> ".. getenv("VAR"))
assert(os.execute == nil,"os.execute should not be allowed")
assert(string.lower("ANA") == "ana","error calling string.lower")
assert(2^3 == 8, "error in arithmetic expression (pow)")
print("script OK!")
