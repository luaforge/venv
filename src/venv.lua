----------------------------------------------------------------------------
-- $Id: venv.lua,v 1.5 2004-09-28 14:55:33 tomas Exp $
----------------------------------------------------------------------------

----------------------------------------------------------------------------
-- control to prevent an explicitly set global to be re-inherited
----------------------------------------------------------------------------
local _CONTROL = {}
setmetatable(_CONTROL, {__mode = "k"})

local function createcontrol(t)
  _CONTROL[t] = {}
end

local function setcontrol(t, key)
  _CONTROL[t][key] = true
end

local function getcontrol(t, key)
  return _CONTROL[t][key]
end

local function pack (...) return arg end

----------------------------------------------------------------------------
-- "newindex" function for the new environment
----------------------------------------------------------------------------
local function newIndex(t, key, val)
  setcontrol(t, key)
  rawset(t, key, val)
end

----------------------------------------------------------------------------
-- "index" function for the new environment
----------------------------------------------------------------------------
local function createIndex(parent)
  return function(t, key)
           if getcontrol(t, key) then return nil end
           v = parent[key]
           if v == nil then return nil end
           if type(v) == "table" then
            local nv = {}
            setmetatable(nv, {__index = createIndex(v),
                              __newindex = newIndex})
            v = nv
            createcontrol(v)
           end
           setcontrol(t, key)
           rawset(t,key,v)
           return v
         end
end

----------------------------------------------------------------------------
-- Redefinition of 'require', allowing libraries to be stored in the
-- global environment but executed within a virtual environment
----------------------------------------------------------------------------

local function getpath(ng)
  local path = ng._PATH
  if type(path) ~= "string" then
    path = os.getenv("LUA_PATH")
    if path == nil then
      path = "?;?.lua"
    end
  end
  return path
end

local function search (path, name)
  for c in string.gfind(path, "[^;]+") do
    c = string.gsub(c, "%?", name)
    local f = io.open(c)
    if f then   -- file exist?
      f:close()
      return c
    end
  end
  return nil
end

local function new_require(ng)
  return function(name)
    -- test if module was loaded in this environment
    if not ng.package.loaded[name] then
      ng.package.loaded[name] = true
      -- test if the module is stored in the global environment
      local f = ng.package.preload[name]
      if not f then
        local filename = string.gsub(name, "%.", "/")
        local fullname = search(ng.package.cpath, filename)
        if fullname then
          local openfunc = "luaopen_"..string.gsub(name, "%.", "")
          f = assert(loadlib(fullname, openfunc))
        else
          fullname = search(ng.package.path, filename)
          if not fullname then
            error("cannot find "..name.." in path "..ng.package.path.." nor in "..ng.package.cpath, 2)
          end
          f = assert(loadfile(fullname))
        end
      end
      -- run module inside virtual environment if not loaded yet
      pcall (setfenv, f, ng)
      local old_arg = ng.arg
      ng.arg = { name }
      local res = f(name)
      ng.arg = old_arg
      if res then ng.package.loaded[name] = res end
    end
    return ng.package.loaded[name]
  end
end

----------------------------------------------------------------------------
-- Creates a virtual environment for the given function
----------------------------------------------------------------------------
function venv(f)
  if type(f) ~= "function" then
    error("bad argument #1 to venv ('function' expected got '"..type(f).."')")
  end
  local currg = getfenv(0)
  local ng = {}
  
  setmetatable(ng, {__index = createIndex(currg),
                    __newindex = newIndex})
  createcontrol(ng)

  ng._G = ng
  ng.require = new_require(ng)

  ng.ipairs = ipairs
  ng.next = next
  ng.tostring = tostring
  ng.__pow = __pow

  setfenv(f, ng)

  return function(...)
           setfenv(0, ng)
           local result = pack (pcall (f, unpack(arg)))
           setfenv(0, currg)
           table.remove (result, 1) -- remove status of pcall
           return unpack(result)
         end
end
