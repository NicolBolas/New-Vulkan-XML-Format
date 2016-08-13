
local parse_dom = require "_ParseVkDom"
local parse_types = require "_ParseVkTypes"

local vkxml = parse_dom.DOM()


local typesProcs = parse_types.GenProcTable(function(data, output)
	if(output) then
		output[#output + 1] = data
	end
end)

local function ProcessTypes(typesNode)
	local types = {}
	parse_dom.ProcNodes(typesProcs, typesNode.el, types)
	
	for _, curr in ipairs(types) do
		print(curr.kind, curr.name)
	end
end


local baseNodeProcs =
{
	["types"] = ProcessTypes,
}

parse_dom.ProcNodes(baseNodeProcs, vkxml.root.el)

for _, test in ipairs(vkxml.root.el) do
	if(test.name == "types") then
		
	end
end
