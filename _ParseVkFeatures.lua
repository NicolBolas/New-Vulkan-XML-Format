local parse_dom = require "_ParseVkDom"
local common = require "_ParseVkCommon"

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

local function ParseEnumref(node)
	local data = { kind = "enumref" }
	
	data.name = node.attr.name
	data.notation = node.attr.comment
	
	return data
end

-- Old format heavily overloads "enum":
--  `enum` with a `value` or `bitpos` and no `extends` is declaring a
--		*constant*, not an enumerator. The constant may be a number/bitpos,
--		a quoted string, or an existing enumerator/constant.
--		The existing constant may come from the same extension.
--  `enum` with a `value/bitpos` and `extends` is extending an existing
--		enumeration with the specific value.
--	`enum` with an `offset/dir` and `extends` is extending an existing enumeration,
--      using the offsetting extension scheme outlined in the docs.
local function ParseEnum(node)
	local data = { kind = "enum" }
	
	data.name = node.attr.name
	data.notation = node.attr.comment
	data.extends = node.attr.extends

	if(node.attr.offset) then
		data.offset = node.attr.offset
		if(node.attr.dir == "-") then
			data.negate = "true"
		end
	else
		local name, value = common.ExtractEnumNameData(node)
		data[name] = value
	end
	
	return data
end

local function ParseConstant(node)
	local data = { kind = "constant" }
	
	data.name = node.attr.name
	data.notation = node.attr.comment

	local name, value
	local val = node.attr.value
	if(val) then
		--First thing is a quote, so quoted string.
		if(val:match("^\"")) then
			name, value = "string", val:match([[^"(.+)"$]])
		--If the whole thing is a valid C++ identifier,
		--then it's an enum reference.
		elseif(val:match("^[_%a][_%w]*$")) then
			name, value = "enumref", val
		else
			name, value = common.ExtractEnumNameData(node)
		end
	end
	
	--Haven't found it yet, so probably a bitpos
	if(not name) then
		name, value = common.ExtractEnumNameData(node)
	end
	
	assert(name, node.name)
	data[name] = value
	
	return data
end

function require_elem_funcs.enum(node, isExtension)
	if(isExtension) then
		if(node.attr.extends) then
			return ParseEnum(node)
		else
			return ParseConstant(node)
		end
	else
		return ParseEnumref(node)
	end
end

function require_elem_funcs.usage(node, isExtension)
	local data = { kind = "usage" }
	
	data.text = parse_dom.ExtractFullText(node)
	data.command = node.attr.command
	data.struct = node.attr.struct
	
	return data
end


local require_proc = parse_dom.GenProcTable(nil, nil, require_elem_funcs,
function(data, _, req_data)
	if(data.kind == "usage") then
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

local Elems = {}

function Elems.extension(node)
	local data = { kind = "extension" }
	
	data.name = node.attr.name
	data.notation = node.attr.comment
	data.number = node.attr.number
	data["match-api"] = node.attr.supported
	data.define = node.attr.protect
	data.author = node.attr.author
	data.contact = node.attr.contact
	
	data.references = {}
	for _, child in ipairs(node.el) do
		table.insert(data.references, ParseRequire(child, true))
	end
	
	return data
end

function funcs.GenProcTable(StoreFunc)
	return parse_dom.GenProcTable(nil, nil, Elems, StoreFunc)
end

return funcs
