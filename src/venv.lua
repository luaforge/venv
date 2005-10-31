----------------------------------------------------------------------------
-- VEnv (Lua Virtual Environment) is a simple library which provides a way
-- to execute a Lua function in a separate environment, protecting the
-- original one.
--
-- Copyright (c) 2004-2005 Kepler Project
-- $Id: venv.lua,v 1.16 2005-10-31 13:47:58 tomas Exp $
----------------------------------------------------------------------------

_VENV = "VEnv 1.2.0"

local assert, ipairs, loadfile, loadstring, pairs, rawget, setfenv, tostring, type, unpack = assert, ipairs, loadfile, loadstring, pairs, rawget, setfenv, tostring, type, unpack
local _open = io.open
local find, format, gfind, gsub, sub = string.find, string.format, string.gfind, string.gsub, string.sub
local tremove = table.remove

local LUA_DIRSEP = LUA_DIRSEP or '/'
local LUA_OFSEP = LUA_OFSEP or '_'
local OLD_LUA_OFSEP = OLD_LUA_OFSEP or ''
local POF = POF or 'luaopen_'
local LUA_PATH_MARK = LUA_PATH_MARK or '?'
local LUA_IGMARK = LUA_IGMARK or ':'

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
             v = newcontrolledtable(v)
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
-- Serches for a file in a search path.
----------------------------------------------------------------------------
local function findfile (name, pname, package)
    name = gsub (name, "%.", LUA_DIRSEP)
    local path = package[pname]
    assert (type(path) == "string", format ("package.%s must be a string", pname))
    for c in gfind (path, "[^;]+") do
        c = gsub (c, "%"..LUA_PATH_MARK, name)
        local f = _open (c)
        if f then
            f:close ()
            return c
        end
    end
    return nil -- not found
end

----------------------------------------------------------------------------
-- check whether library is already loaded
----------------------------------------------------------------------------
local function loader_preload (name, preload)
	assert (type(preload) == "table", "`package.preload' must be a table")
	return preload[name]
end

----------------------------------------------------------------------------
-- Lua library loader
----------------------------------------------------------------------------
local function loader_Lua (name, package)
	local filename = findfile (name, "path", package)
	if not filename then
		return false
	end
	local f, err = loadfile (filename)
	if not f then
		error (format ("error loading module `%s' (%s)", name, err))
	end
	return f
end

----------------------------------------------------------------------------
-- Builds the name of the "luaopen" function.
----------------------------------------------------------------------------
local function mkfuncname (name)
	name = gsub (name, "^.*%"..LUA_IGMARK, "")
	name = gsub (name, "%.", LUA_OFSEP)
	return POF..name
end

----------------------------------------------------------------------------
-- Builds the name of the "luaopen" function using the old policy.
----------------------------------------------------------------------------
local function old_mkfuncname (name)
	--name = gsub (name, "^.*%"..LUA_IGMARK, "")
	name = gsub (name, "%.", OLD_LUA_OFSEP)
	return POF..name
end

----------------------------------------------------------------------------
-- C library loader
----------------------------------------------------------------------------
local function loader_C (name, package)
	local filename = findfile (name, "cpath", package)
	if not filename then
		return false
	end
	local funcname = mkfuncname (name)
	local f, err = loadlib (filename, funcname)
	if not f then
		funcname = old_mkfuncname (name)
		f, err = loadlib (filename, funcname)
		if not f then
			error (format ("error loading module `%s' (%s)", name, err))
		end
	end
	return f
end

----------------------------------------------------------------------------
----------------------------------------------------------------------------
local function loader_Croot (name, package)
	local p = gsub (name, "^([^.]*).-$", "%1")
	if p == "" then
		return
	end
	local filename = findfile (p, "cpath", package)
	if not filename then
		return
	end
	local funcname = mkfuncname (name)
	local f, err, where = loadlib (filename, funcname)
	if f then
		return f
	elseif where ~= "init" then
		error (format ("error loading module `%s' (%s)", name, err))
	end
end

----------------------------------------------------------------------------
-- iterate over available loaders
----------------------------------------------------------------------------
local function load (name, loaders)
	-- iterate over available loaders
	assert (type (loaders) == "table", "`package.loaders' must be a table")
	for i, loader in ipairs (loaders) do
		local f = loader[1] (name, loader[2])
		if f then
			return f
		end
	end
	error (format ("module `%s' not found", name))
end

----------------------------------------------------------------------------
-- findtable
----------------------------------------------------------------------------
local function findtable (t, f)
	assert (type(f)=="string", "not a valid field name ("..tostring(f)..")")
	local ff = f.."."
	local ok, e, w = find (ff, '(.-)%.', 1)
	while ok do
		local nt = rawget (t, w)
		if not nt then
			nt = {}
			t[w] = nt
		elseif type(t) ~= "table" then
			return sub (f, e+1)
		end
		t = nt
		ok, e, w = find (ff, '(.-)%.', e+1)
	end
	return t
end

-- sentinel
local sentinel = function () end

----------------------------------------------------------------------------
-- Define package-related functions and tables.
----------------------------------------------------------------------------
local function set_package_functions (ng, currg)
	local _p = currg.package
	--local _loaded = newcontrolledtable (_p.loaded)
	local _loaded = _p.loaded
	-- build a copy of `package' table
	local _package = newcontrolledtable (_p)
	_package.loaded = _loaded
	ng.package = _package
	-- create `loaders' table
	_loaders = {
		{ loader_preload, _package.preload },
		{ loader_Lua, _package },
		{ loader_C, _package },
		{ loader_Croot, _package },
	}
	ng.package.loaders = _loaders
	--
	-- New require function
	--
	ng.require = function (modname)
		assert (type(modname) == "string", format (
			"bad argument #1 to `require' (string expected, got %s)", type(name)))
		local p = _loaded[modname]
		if p then -- is it there?
			if p == sentinel then
				error (format ("loop or previous error loading module '%s'", modname))
			end
			return p -- package is already loaded
		end
		local init = load (modname, _loaders)
		_loaded[modname] = sentinel
		local actual_arg = ng.arg
		ng.arg = { modname }
		pcall (setfenv, init, ng)
		local res = init (modname)
		if res then
			_loaded[modname] = res
		end
		ng.arg = actual_arg
		if _loaded[modname] == sentinel then
			_loaded[modname] = true
		end
		return _loaded[modname]
	end
	--
	-- New module function
	--
	ng.module = function (modname, ...)
		local ns = _loaded[modname]
		if type(ns) ~= "table" then
			--ns = findtable (ng, modname)
			ns = findtable (currg, modname)
			if not ns then
				error (format ("name conflict for module '%s'", modname))
			end
			_loaded[modname] = ns
		end
		if not ns._NAME then
			ns._NAME = modname
			ns._M = ns
			ns._PACKAGE = gsub (modname, "[^.]*$", "")
		end
		local _, err = setfenv (2, ns)
		for i, f in ipairs (arg) do
			f (ns)
		end
	end
end

----------------------------------------------------------------------------
-- Creates a virtual environment for the given function
----------------------------------------------------------------------------
function venv(f)
  if type(f) ~= "function" then
    error("bad argument #1 to venv ('function' expected got '"..type(f).."')")
  end
  local currg = getfenv(f)
  local ng = newcontrolledtable(currg)
  ng._G = ng
  if ng.require or ng.module then
    set_package_functions (ng, currg)
  end

  ng.ipairs = ipairs
  ng.next = next
  ng.tostring = tostring
  ng.__pow = __pow
  ng.loadstring = function (str, chunkname)
                  local f, err = loadstring (str, chunkname)
                  if not f then
                    return nil, err
                  end
                  setfenv (f, ng)
                  return f
  end
  ng.loadfile = function (filename)
		local f, err = loadfile (filename)
		if not f then
			return nil, err
		end
		setfenv (f, ng)
		return f
  end
  ng.dofile = function (filename)
		if filename then
			return ng.loadfile (filename)()
		else
			local chunk = io.stdin:read ("*a")
			setfenv (chunk, ng)
			return chuck ()
		end
  end

  return function(...)
           setfenv(f, ng)
           local result = pack (xpcall (function () return f (unpack(arg)) end, debug.traceback))
           setfenv(f, currg)
           if not result[1] then
             error(result[2])
           end
           tremove (result, 1) -- remove status of pcall
           return unpack(result)
         end
end

return venv
