print("\n** lib '".._REQUIREDNAME.."' loaded **")
assert((_G ~= GLOBAL), "lib is not inside a venv!")

print("\nglobals in lib environment")
local g=""
--for i,v in pairs(_G) do print(i,'>',type(v)) end
for i in pairs(_G) do g = g.." "..i end
print(g)

require"lib2"
local print, type = print, type
local _G = _G
local wq = lib2.wq

local Public = {}
lib1 = Public

-- internal state variables
local state

setfenv (1, Public)

function xp(x)
	local state = _G.VirtualEnv
	local xx = wq(x)
	return (x..x == xx), type(x), state
end
