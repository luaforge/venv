----------------------------------------------------------------------------
-- Stable: State persistent table.
-- An official way to bypass VEnv.
-- $Id: stable.lua,v 1.2 2005-03-28 17:51:35 tomas Exp $
----------------------------------------------------------------------------

local next = next

module ((arg and arg[1]) or "stable")

_COPYRIGHT = "Copyright (C) 2003-2005 Kepler Project"
_DESCRIPTION = "State persistent table"
_NAME = "Stable"
_VERSION = "1.0"

local persistent_table = {}

function get (i)
	return persistent_table[i]
end

function set (i, v)
	persistent_table[i] = v
end

local function _next (_, key)
	return next (persistent_table, key)
end

function pairs ()
	return _next, persistent_table, nil
end
