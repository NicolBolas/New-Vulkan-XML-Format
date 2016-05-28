
local parse_dom = require "_ParseVkDom"

local Tests = {}
local Procs = {}

function Tests.Include(node)
	return node.name == "type" and node.attr.category == "include"
end

function Procs.Include(node)
	local data = {kind = "include"}
	
	--Parse the include name. May be an attribute `name` or a `name` child element.
	if(node.attr.name) then
		data.name = node.attr.name
	else
		local elem = parse_dom.FindChildElement(node, "name")
		if(elem and elem.name == "name") then
			local text = parse_dom.FindNextText(elem)
			if(text) then
				data.name = text.value
			end
		end
	end
	
	assert(data.name)
	
	--Determine if the `name` ends in a `.h`.
	if(data.name:match("%.h$")) then
		data.need_ext = false
	else
		data.need_ext = true
	end
	
	--Determine if the #include statement in the text block uses `"` or `<`.
	local include_stmt = parse_dom.FindNextText(node).value
	local inc_char = include_stmt:match("%#include%s+([\"<])")
	
	assert(inc_char)
	
	if(inc_char == '<') then
		data.style = "bracket"
	else
		data.style = "quote"
	end
	
	return data
end

function Tests.Require(node)
	return node.name == "type" and node.attr.category == nil and node.attr.requires
end

function Procs.Require(node)
	local data = { kind = "reference" }
	
	data.name = node.attr.name
	data.include = node.attr.requires
	
	return data
end

--If the `name` is an attribute, then the entire accumulated text child
--is a massive C-expression, which replaces any definition.
--Otherwise, must part #define <name/> c-expression.
--
--Must check to see if there are comments to be extracted into comment fields.
--The c-expression may contain `type` elements. These must be extracted into `requires` clauses.
--The c-expression may be an integer value. Should be extracted into a simple value expression.
function Procs.Define(node)
end


local funcs = {}


function funcs.GenProcTable(StoreFunc)
	local procTable = {}
	for name, test in pairs(Tests) do
		local procEntry = {}
		procTable[#procTable + 1] = procEntry
		procEntry.Test = test
		local Proc = assert(Procs[name])
		
		procEntry.Proc = function(node, ...)
			local data = Proc(node)
			StoreFunc(data, ...)
		end
	end
	return procTable
end

return funcs
