--Utilities are put into the main namespace. They're also exported in a table.

local funcs = {}

--Packs the variadic parameters into a table, with `n` being the count of parameters.
--For Lua 5.1
function funcs.pack_params(...)
	return {n = select("#", ...), ...}
end

if(not unpack) then
	--Lua 5.2+
	unpack = table.unpack
	funcs.pack_params = table.pack
end


--Performs `require`, using a given local path. Restores the path afterwards.
--Path should be the local directory name, ending in a `/`
function funcs.require_local_path(path, ...)
	local old_path = package.path
	package.path = "./" .. path .. "?.lua;" .. package.path
	
	local rets = pack_params(require(...))
	package.path = old_path
	return unpack(rets, 1, rets.n)
end

function funcs.iff(test, true_val, false_val)
	if(test) then return true_val else return false_val end
end

--Trim whitespace off the right side.
function funcs.rtrim(s)
  local n = #s
  while n > 0 and s:find("^%s", n) do n = n - 1 end
  return s:sub(1, n)
end

--Make all of these available in the global namespace.
for key, func in pairs(funcs) do
	_G[key] = func
end

return funcs