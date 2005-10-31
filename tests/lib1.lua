print("\n** lib '"..arg[1].."' loaded **")
assert((_G ~= GLOBAL), "lib is not inside a venv!")
assert(tostring(_G) == execs[VirtualEnv][Run]._G, "wrong environment!")

--[[
print("\nglobals in lib environment")
local g=""
for i in pairs(_G) do g = g.." "..i end
print(g)
--]]

require"lib2"
local print, type = print, type
local _G = _G
local wq = lib2.wq

module ("lib1")

-- internal state variables
local state

function xp(x)
	local state = _G.VirtualEnv
	local xx = wq(x)
	return (x..x == xx), type(x), state
end
