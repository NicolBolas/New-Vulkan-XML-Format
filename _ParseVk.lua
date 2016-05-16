package.path = package.path .. ";./SLAXML/?.lua"
local slaxml = require "slaxml"

local vk_xml_str = (function()
	local hFile = io.open("src/vk.xml")
	assert(hFile, "???")
	local str = hFile:read("*a")
	hFile:close()
	return str
end)()

local funcs = {}

function funcs.parse(builder)
	local parser = slaxml:parser(builder)
	parser:parse(vk_xml_str, {stripWhitespace=false})
end

return funcs
