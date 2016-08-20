local parse_dom = require "_ParseVkDom"

local nodeMap =
{
	["require"]	= "require",
	["remove"]	= "remove",
}

local require_elem_funcs = {}

function require_elem_funcs.type(node)
	local data = { kind = "defref" }
	
	data.name = node.attr.name
	data.notation = node.attr.comment
	
	return data
end

function require_elem_funcs.command(node)
	local data = { kind = "commandref" }
	
	data.name = node.attr.name
	data.notation = node.attr.comment
	
	return data
end

function require_elem_funcs.enum(node, isExtension)
	if(isExtension) then
		assert(false)
	else
		local data = { kind = "enumref" }
		
		data.name = node.attr.name
		data.notation = node.attr.comment
		
		return data
	end
end

function require_elem_funcs.usage(node, isExtension)
	return parse_dom.ExtractFullText(node)
end



local require_proc = parse_dom.GenProcTable(nil, nil, require_elem_funcs,
function(data, _, req_data)
	if(type(data) == "string") then
		--Usage. Add to usages.
		if(not req_data.usages) then
			req_data.usages = {}
		end
		table.insert(req_data.usages, data)
	else
		table.insert(req_data.elements, data)
	end
end)


local function ParseRequire(node, isExtension)
	local data = { kind = assert(nodeMap[node.name]) }
	
	data.profile = node.attr.profile
	data.notation = node.attr.comment
	
	data.elements = {}
	parse_dom.ProcNodes(require_proc, node.el, isExtension, data)
	
	return data
end

local funcs = {}

function funcs.ProcessSingle(node)
	local data = { kind = "feature" }

	data.name = node.attr.name
	data.version = node.attr.number
	data.api = node.attr.api
	data.notation = node.attr.comment
	data.define = node.attr.protect

	data.references = {}
	for _, child in ipairs(node.el) do
		table.insert(data.references, ParseRequire(child))
	end
	
	return data
end

return funcs
