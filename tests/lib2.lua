print("\n** lib '".._REQUIREDNAME.."' loaded **")
assert((_G ~= GLOBAL), "lib is not inside a venv!")

print("\nglobals in lib2 environment")
local g=""
--for i,v in pairs(_G) do print(i,'>',type(v)) end
for i in pairs(_G) do g = g.." "..i end
print(g)

local Public = {}
lib2 = Public

setfenv (1, Public)

function wq(x) return x..x end
