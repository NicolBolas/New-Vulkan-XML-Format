
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

function Tests.Define(node)
	return node.name == "type" and node.attr.category == "define"
end

--If the `name` is an attribute, then the entire accumulated text child
--is a massive C-expression, which replaces any definition.
--Otherwise, must part #define <name/> c-expression.
--
--Must check to see if there are comments to be extracted into comment fields.
--The c-expression in the text may contain `type` elements.
--These are extracted into `defrefs` clauses.
--
--If the C expression is just a naked integer, then it will be in the `value` member.
--Otherwise, it will be `c_expression`.
--If `is_complex`, then the `c_expression` must be repeated verbatum. Otherwise, use
--the parameter lists and such.
--If `params`, then the define has the list of named params.
--If `disabled`, then you should comment out the #define.
--`comment` is a comment string that should be shown with this define.
--  You must add any commenting stuff manually. Can be multiline.
function Procs.Define(node)
	local data = { kind = "define" }
	
	--Name can be in an element or an attribute.
	if(node.attr.name) then
		data.name = node.attr.name
		data.is_complex = true
	else
		local name_el = parse_dom.FindChildElement(node, "name")
		local name = parse_dom.ExtractFullText(name_el)
		assert(#name > 0)
		data.name = name
		data.is_complex = false
	end
	
	--Search for any `type` child nodes. These are references to definitions.
	local defrefs = {}
	for _, child in ipairs(node.el) do
		if(child.name == "type") then
			local name = parse_dom.ExtractFullText(child)
			defrefs[#defrefs + 1] = name
		end
	end
	
	if(#defrefs ~= 0) then
		data.defrefs = defrefs
	end
	
	--Search for a prefixing comment in the overall text.
	local whole_text = parse_dom.ExtractFullText(node)
	local text_lines = {}
	for str in whole_text:gmatch("([^\n]+)") do
		text_lines[#text_lines + 1] = str
	end
	
	local comment = {}
	local real_lines = {}
	for _, str in ipairs(text_lines) do
		local test = str:match("%s*//%s*(.+)")
		if(test) then
			comment[#comment + 1] = test
		else
			real_lines[#real_lines + 1] = str
		end
	end
	
	comment = table.concat(comment, "\n")
	if(#comment ~= 0) then
		data.comment = comment
	end
	
	if(#real_lines == 0) then
		real_lines = text_lines
		data.disabled = true
	end
	
	--Extract the actual C-expression.
	if(data.is_complex) then
		data.c_expression = table.concat(text_lines, "\n")
	else
		--Find the #define in the real_lines.
		local relevant_text
		for _, line in ipairs(real_lines) do
			local check = line:match("#define%s+([_%a][_%w]*)")
			if(check == data.name) then
				relevant_text = table.concat(real_lines, "\n", _)
				break
			end
		end
		
		--See if there are parameters
		local param_text, expr = relevant_text:match("#define%s+[_%a][_%w]*%((.+)%)%s*(.+)")
		if(not param_text) then
			expr = relevant_text:match("#define%s+[_%a][_%w]*%s*(.+)")
		else
			local params = {}
			for param in param_text:gmatch("([^,]+)") do
				params[#params + 1 ] = params
			end
			
			data.params = params
		end
		
		if(data.params) then
			data.c_expression = expr
		else
			local num = expr:match("^%s*(%d+)%s*$")
			if(num) then
				data.value = num
			else
				data.c_expression = expr
			end
		end
	end
	
	return data
end

function Tests.Basetype(node)
	return node.name == "type" and node.attr.category == "basetype"
end

--`type` and `name` are sub-elements.
function Procs.Basetype(node)
	local data = { kind = "typedef" }
	
	data.name = parse_dom.ExtractFullText(parse_dom.FindChildElement(node, "name"))
	data.base_type = parse_dom.ExtractFullText(parse_dom.FindChildElement(node, "type"))

	return data
end

function Tests.Bitmask(node)
	return node.name == "type" and node.attr.category == "bitmask"
end

--`type` and `name` are sub-elements.
function Procs.Bitmask(node)
	local data = Procs.Basetype(node)
	data.kind = "bitmask"
	return data
end

function Tests.Handle(node)
	return node.name == "type" and node.attr.category == "handle"
end

--`type` and `name` are sub-elements.
function Procs.Handle(node)
	local data = { kind = "handle" }
	
	data.name = parse_dom.ExtractFullText(parse_dom.FindChildElement(node, "name"))
	local handle_type = parse_dom.ExtractFullText(parse_dom.FindChildElement(node, "type"))
	if(handle_type == "VK_DEFINE_HANDLE") then
		data.type = "dispatch"
	elseif(handle_type == "VK_DEFINE_NON_DISPATCHABLE_HANDLE") then
		data.type = "nodispatch"
	else
		assert(false, data.name)
	end

	return data
end

function Tests.Enum(node)
	return node.name == "type" and node.attr.category == "enum"
end

function Procs.Enum(node)
	local data = { kind = "enumeration" }
	
	data.name = node.attr.name

	return data
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
