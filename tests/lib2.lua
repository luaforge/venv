print("\n** lib '"..arg[1].."' loaded **")
assert((_G ~= GLOBAL), "lib is not inside a venv!")
-- current globals table should the same of the current running VEnv
assert(tostring(_G) == execs[VirtualEnv][Run]._G, "wrong environment!")

--[[
print("\nglobals in lib2 environment")
local g=""
for i in pairs(_G) do g = g.." "..i end
print(g)
--]]

module ("lib2")

function wq(x) return x..x end
