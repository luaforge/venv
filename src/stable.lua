----------------------------------------------------------------------------
-- Stable: State persistent table.
-- An official way to bypass VEnv.
-- $Id: stable.lua,v 1.1 2005-03-24 18:36:30 tomas Exp $
----------------------------------------------------------------------------

local next = next

module ((arg and arg[1]) or "stable")

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
