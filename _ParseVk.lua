
local parse_dom = require "_ParseVkDom"
local root = require "_ParseVkRoot"
local vkxml = parse_dom.DOM()

--Used to remap from vk.xml element names to new_registry element names.
local name_remap =
{
	types =		"definitions",
}

--Table that is called for each root element when found.
local root_procs = {}

for root_name, parser in pairs(root) do
	local proc_tbl = parser.GenProcTable(function(data, output)
		if(output) then
			output[#output + 1] = data
		end
	end)
	
	root_procs[root_name] = function(node, roots)
		local data = {kind = name_remap[root_name] and name_remap[root_name] or root_name}
		parse_dom.ProcNodes(proc_tbl, node.kids, data)
		
		roots[#roots + 1] = data
	end
end

function root_procs.comment(node, roots)
	local data = {kind = "notation"}
	data.text = parse_dom.ExtractFullText(node)
	roots[#roots + 1] = data
end

local funcs = {}

function funcs.Parse()
	local data = {}
	parse_dom.ProcNodes(root_procs, vkxml.root.el, data)
	return data
end

return funcs
