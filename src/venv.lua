----------------------------------------------------------------------------
-- $Id: venv.lua,v 1.7 2005-03-22 10:04:16 tomas Exp $
----------------------------------------------------------------------------

local ipairs, pairs = ipairs, pairs

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

--
-- auxiliar function to read "nested globals"
--
local function getfield (t, f)
  for w in string.gfind(f, "[%w_]+") do
    if not t then return nil end
    t = t[w]
  end
  return t
end


--
-- auxiliar function to write "nested globals"
--
local function setfield (t, f, v)
  for w in string.gfind(f, "([%w_]+)%.") do
    t[w] = t[w] or {} -- create table if absent
    t = t[w]            -- get the table
  end
  local w = string.gsub(f, "[%w_]+%.", "")   -- get last field name
  t[w] = v            -- do the assignment
end


----------------------------------------------------------------------------
-- "newindex" function for the new environment
----------------------------------------------------------------------------
local function newIndex(t, key, val)
  setcontrol(t, key)
  rawset(t, key, val)
end

local newcontrolledtable

----------------------------------------------------------------------------
-- "index" function for the new environment
----------------------------------------------------------------------------
local function createIndex(parent)
  local newcontrolledtable = newcontrolledtable
  return function(t, key)
           if getcontrol(t, key) then return nil end
           v = parent[key]
           if v == nil then return nil end
           if type(v) == "table" then
            local nv = newcontrolledtable(v)
            v = nv
           end
           setcontrol(t, key)
           rawset(t,key,v)
           return v
         end
end

----------------------------------------------------------------------------
-- create a new table which inherits its fields from the given table.
----------------------------------------------------------------------------
newcontrolledtable = function (inherit)
  local newt = {}
  setmetatable(newt, {__index = createIndex(inherit),
                      __newindex = newIndex})
  createcontrol(newt)
  return newt
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

local function new_require_and_module(ng, currg)
  local _p = currg.package
  local loaded = newcontrolledtable(_p.loaded)
  -- build a copy of `package' table
  local package = newcontrolledtable(_p)
  package.path = _p.path
  package.cpath = _p.cpath
  package.loaded = loaded
  package.loaders = _p.loaders
  ng.package = package
  local module = _G.module
  local getfield, setfield = getfield, setfield

  -- redefine `require'
  local new_req = function(name)
    assert(type(name) == "string", string.format(
      "bad argument #1 to `require' (string expected, got %s)", type(name)))
    local p = getfield(loaded, name)
    if p then return p end
    -- first mark it as loaded
    setfield(loaded, name, true)
    --local f = load(name)
    --setfield(preload, name, f)
    local actual_arg = arg
    arg = { name }
    loaded[name] = load(name)(name) or true
    --loaded[name] = f(name) or true
    arg = actual_arg
    return getfield(loaded, name)
  end
--[[
    -- test if module was loaded in this environment
    if not loaded[name] then
      loaded[name] = true
      -- test if the module is stored in the global environment
      local f = preload[name]
      if not f then
        local filename = string.gsub(name, "%.", "/")
        local fullname = search(package.cpath, filename)
        if fullname then
          local openfunc = "luaopen_"..string.gsub(name, "%.", "")
          f = assert(loadlib(fullname, openfunc))
        else
          fullname = search(package.path, filename)
          if not fullname then
            error("cannot find "..name.." in path "..package.path.." nor in "..package.cpath, 2)
          end
          f = assert(loadfile(fullname))
        end
        -- store module in the global environment
        preload[name] = f
      end
      -- run module inside virtual environment if not loaded yet
      pcall (setfenv, f, ng)
      local old_arg = ng.arg
      ng.arg = { name }
      local res = f(name)
      ng.arg = old_arg
      if res then loaded[name] = res end
    end
    return loaded[name]
  end
--]]
  -- redefine `module'
  local new_mod = function(name)
    local _G = ng
    local ns = getfield(_G, name)
    if not ns then
      ns = {}
      setfield(_G, name, ns)
    elseif type(ns) ~= "table" then
      error("name conflict for module `"..name.."'")
    end
    if not ns._NAME then
      ns._NAME = name
      ns._PACKAGE = string.gsub(name, "[^.]*$", "")
    end
    setmetatable(ns, {__index = _G})
    loaded[name] = ns
    setfenv(2, ns)
    return ns
  end
  return new_req, new_mod
end

local function clonetable (t, n)
if not n then n = 1 end
  local newt = {}
  for i, v in pairs(t) do
    if i ~= "base" then
      if type(v) == "table" then
        newt[i] = clonetable (v, n+1)
      else
        newt[i] = v
      end
    end
  end
  return newt
end

----------------------------------------------------------------------------
-- Creates a virtual environment for the given function
----------------------------------------------------------------------------
function venv(f)
  if type(f) ~= "function" then
    error("bad argument #1 to venv ('function' expected got '"..type(f).."')")
  end
  local currg = getfenv(0)
  local ng = newcontrolledtable(currg)
  ng._G = ng
  ng.package = clonetable (currg.package)

  local env = { package = ng.package, loaded = ng.package.loaded, _G = ng, }
  setfenv(ng.require, env)
  setfenv(ng.module, env)
  local i = 1
  local loaders = ng.package.loaders
  while loaders[i] do
    setfenv(loaders[i], env)
    i = i+1
  end

  ng.ipairs = ipairs
  ng.next = next
  ng.tostring = tostring
  ng.__pow = __pow

  setfenv(f, ng)

  return function(...)
           setfenv(0, ng)
           local result = pack (xpcall (function () return f (unpack(arg)) end, debug.traceback))
           setfenv(0, currg)
           if not result[1] then
             error(result[2])
           end
           table.remove (result, 1) -- remove status of pcall
           return unpack(result)
         end
end
