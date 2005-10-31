print("** script 1 loaded **")
assert(not (_G == GLOBAL), "script is not inside venv!")
assert(tostring(_G) == execs[VirtualEnv][Run]._G, "wrong environment!")

--[[
print("\nglobals in script1 environment: ")
local g=""
for i in pairs(_G) do g = g.." "..i end
print(g)
--]]

x = "inside"
assert((x == "inside"), "error setting/accessing var x inside venv", x)

local status, msg = pcall(require, "no_lib")
assert (status == false and string.find (msg, "no_lib"),
	"error while require-ing a non-existent file: "..msg)

local status, msg = pcall (require, "lib_err")
assert (status == false and string.find (msg, "`)' expected near `,'"),
	"error while require-ing a mal-formed Lua file")

-- Loading Lua library
require"lib1"
assert(type(lib1) == "table", "error loading lib1 ("..type(lib1)..")")
local tl, tg = type(lib1.xp), type(GLOBAL.lib1.xp)
assert(tl == "function", "error loading lib1: internal function not exported")
assert(tg == "function", "error storing lib1: internal function not stored in outer environment")
assert(lib1.xp == GLOBAL.lib1.xp, "error inheriting lib1 functions ("..tostring(lib1.xp).." X "..tostring(GLOBAL.lib1.xp)..")")

local x1, t1, s1, ve = lib1.xp (x)
assert(x1 == true and t1 == "string", 
       "error calling lib1.xp, got >> '"..tostring(x1).."'("..tostring(t1)..")")
print("running in venv:", VirtualEnv, "state:", s1)

print()
-- Loading binary library
require"lfs"
assert(type(lfs) == "table", "error loading binary library lfs ("..type(lfs)..")")
log("lfs",tostring(lfs))
local tl, tg = type(lfs.currentdir), type(GLOBAL.lfs.currentdir)
assert(tl == "function", "error loading lfs: internal function not exported")
assert(tg == "function", "error storing lfs: internal function not stored in outer environment")
assert(lfs.currentdir == GLOBAL.lfs.currentdir, "error inheriting lfs functions ("..tostring(lfs.currentdir).." X "..tostring(GLOBAL.lfs.currentdir))
print("current dir: ", lfs.currentdir())
--print("os.date must be inherited >> ".. os.date())
assert(type(os) == "table", "error inheriting `os' table!")
assert(tostring(os.date) == OS_DATE, "error inheriting `os.date' function!")
assert(os.date(DATE_FORMAT) == DATE, "error building date")
--print("getenv must have been redefined >> ".. getenv("VAR"))
assert(type(getenv) == "function", "error inheriting function `getenv'!")
assert(getenv"VAR" == "asked for VAR", "error while running inherited function")
assert(os.execute == nil,"os.execute should not be allowed")
assert(string.lower("ANA") == "ana","error calling string.lower")
assert(2^3 == 8, "error in arithmetic expression (pow)")
print("script OK!")
