----------------------------------------------------------------------------
-- $Id: venv.lua,v 1.4 2004-07-20 12:07:43 tomas Exp $
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
local _STOREDLIBS = {}

local function getpath(ng)
  local path = ng.LUA_PATH
  if type(path) ~= "string" then
    path = os.getenv("LUA_PATH")
    if path == nil then
      path = "?;?.lua"
    end
  end
  return path
end

local function new_require(ng)
  return function(lib)
    -- test if module was loaded in this environment
    local res = ng._LOADED[lib]
    if res then
      return res
    end

    -- test if the module is stored in the global environment
    local libfunction = _STOREDLIBS[lib]
    if type(libfunction) ~= "function" then
      libfunction = nil
      local path = getpath(ng)
      local comppath = string.gsub(path,"?",lib)
      for p in string.gfind(comppath, "([^;]+)") do
        local fh = io.open(p,"r")
        if fh then
          fh:close()
          local l, err = loadfile(p)
          if l then
            libfunction = l ; break
          else
            error (err)
          end
        end
      end
      if libfunction then
        _STOREDLIBS[lib] = libfunction
      else
        error("couldn't load package '"..lib.."' from path '"..path.."'")
        return
      end
    end
    
    -- run module inside virtual environment if not loaded yet
    local reqname = ng._REQUIREDNAME
    ng._REQUIREDNAME = lib
    if res ~= false then
      setfenv(libfunction, ng)
    end
    res = libfunction()
    ng._REQUIREDNAME = reqname
    if res == nil then
      res = true
    end
    ng._LOADED[lib] = res
    return res
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
  ng._LOADED = {}
  ng.require = new_require(ng)

  ng.ipairs = ipairs
  ng.next = next
  ng.tostring = tostring
  ng.__pow = __pow

  setfenv(f, ng)

  return function(...)
           setfenv(0, ng)
           local result = pack (f(unpack(arg)))
           setfenv(0, currg)
           return unpack(result)
         end
end
