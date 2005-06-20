----------------------------------------------------------------------------
-- Stable: State persistent table.
-- An official way to bypass VEnv.
--
-- Copyright (c) 2004-2005 Kepler Project
-- $Id: stable.lua,v 1.4 2005-06-20 20:40:08 tomas Exp $
----------------------------------------------------------------------------

local next = next

module ((arg and arg[1]) or "stable")

_COPYRIGHT = "Copyright (C) 2003-2005 Kepler Project"
_DESCRIPTION = "State persistent table"
_VERSION = "Stable 1.0"

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
