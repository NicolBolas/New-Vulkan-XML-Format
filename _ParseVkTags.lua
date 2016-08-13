
local parse_dom = require "_ParseVkDom"

local Elems = {}

function Elems.tag(node)
	local data = {}
	data.kind = "tag"
	data.name = node.attr.name
	data.author = node.attr.author
	data.contact = node.attr.contact
	return data
end

local funcs = {}

function funcs.GenProcTable(StoreFunc)
	return parse_dom.GenProcTable(nil, nil, Elems, StoreFunc)
end

return funcs
