
local parse_dom = require "_ParseVkDom"

local Elems = {}

function Elems.vendorid(node)
	local data = {}
	data.kind = "vendorid"
	data.name = node.attr.name
	data.id = node.attr.id
	data.notation = node.attr.comment
	return data
end

local funcs = {}

function funcs.GenProcTable(StoreFunc)
	return parse_dom.GenProcTable(nil, nil, Elems, StoreFunc)
end

return funcs
