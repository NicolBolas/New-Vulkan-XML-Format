
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

--"comment" needs special parsing.
function root_procs.comment(node, roots)
	local data = {kind = "notation"}
	data.text = parse_dom.ExtractFullText(node)
	roots[#roots + 1] = data
end

local parse_enums = require "_ParseVkEnums"
--"enum" is unorthodox, so it needs special parsing.
function root_procs.enums(node, roots)
	local data = parse_enums.ProcessSingleEnum(node)
	
	if(data.kind == "constants") then
		if(roots.constants_index) then
			--We've already processed some constants, so fold them together.
			local constants = roots[roots.constants_index]
			for _, constant in ipairs(data) do
				constants[#constants + 1] = constant
			end
		else
			--Pick the current location for the constants.
			roots.constants_index = #roots + 1
			roots[#roots + 1] = data	--Data's `kind` is already correct.
		end
	else
		assert(data.kind == "bitmask" or data.kind == "enumeration", node.name)
		if(roots.enums_index) then
			--We've already processed some enums, so add this to the pile.
			table.insert(roots[roots.enums_index], data)
		else
			local enums = { kind = "enums" }
			roots.enums_index = #roots + 1
			roots[roots.enums_index] = enums
			enums[1] = data
		end
	end
end

local parse_enums = require "_ParseVkFeatures"
function root_procs.feature(node, roots)
	local data = parse_enums.ProcessSingle(node)

	if(not roots.features_index) then
		roots.features_index = #roots + 1
		local features = { kind = "features" }
		roots[roots.features_index] = features
	end
	
	table.insert(roots[roots.features_index], data)
end

local funcs = {}

function funcs.Parse()
	local data = {}
	parse_dom.ProcNodes(root_procs, vkxml.root.el, data)
	
	return data
end

return funcs
