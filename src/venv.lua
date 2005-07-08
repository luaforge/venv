----------------------------------------------------------------------------
-- VEnv (Lua Virtual Environment) is a simple library which provides a way
-- to execute a Lua function in a separate environment, protecting the
-- original one.
--
-- Copyright (c) 2004-2005 Kepler Project
-- $Id: venv.lua,v 1.14 2005-07-08 19:13:31 carregal Exp $
----------------------------------------------------------------------------

_VENV = "VEnv 1.1"

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

local function clonetable (t)
  local newt = {}
  for i, v in pairs(t) do
    if i ~= "base" and i ~= "_M" and type(v) == "table" then
      newt[i] = clonetable (v)
    else
      newt[i] = v
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

  local env = {
    loaded = ng.package.loaded,
    loaders = ng.package.loaders,
    package = ng.package,
    _G = ng,
  }
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

  local currenv = getfenv(f)

  return function(...)
           setfenv(0, ng)
           setfenv(f, ng)
           local result = pack (xpcall (function () return f (unpack(arg)) end, debug.traceback))
           setfenv(f, currenv)
           setfenv(0, currg)
           if not result[1] then
             error(result[2])
           end
           table.remove (result, 1) -- remove status of pcall
           return unpack(result)
         end
end
