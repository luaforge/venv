-- $Id: dir.lua,v 1.1 2004-05-31 14:23:59 ana Exp $
if not dir and loadlib then
	local libname = "libdir.1.0a.so"
	local libopen = "luaopen_dir"
	local init, err1, err2 = loadlib (libname, libopen)
	assert (init, (err1 or '')..(err2 or ''))
	init ()
end
