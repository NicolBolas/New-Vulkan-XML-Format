
require "_Utils"

local funcs = {}

local function CopyAttribIfPresent(writer, node, inputAttrib, outputAttrib)
	outputAttrib = outputAttrib or inputAttrib
	if(node.attr[inputAttrib] ~= nil) then
		local value = node.attr[inputAttrib]
		value = tostring(value)
		writer:AddAttribute(outputAttrib, value)
	end
end

funcs.CopyAttribIfPresent = CopyAttribIfPresent

function funcs.WriteTextElement(writer, elementName, ...)
	writer:PushElement(elementName)
	writer:AddText(...)
	writer:PopElement()
end

local old_reference_map =
{
	["pointer"] = "*",
	["pointer-const-pointer"] = "* const*",
	["pointer-pointer"] = "**",
}

--Writes the text before the name of the value.
--Does not write any array information.
--`wrapInType` if true, then the basetype will be wrapped in a <type> node
function funcs.OldWritePrenameType(writer, type_node, wrapInType)
	if(type_node.attr.const == "true") then
		writer:AddText("const ")
	end
	
	if(type_node.attr.struct == "true") then
		writer:AddText("struct ")
	end
	
	if(wrapInType) then
		writer:PushElement("type")
	end
	
	writer:AddText(type_node.attr.basetype)
	
	if(wrapInType) then
		writer:PopElement()
	end
	
	if(type_node.attr.reference) then
		local ref = old_reference_map[type_node.attr.reference]
		assert(ref)
		writer:AddText(ref)
	end
end

function funcs.OldWriteVariable(writer, node)
	--Write the typed.variable.model attributes.
	CopyAttribIfPresent(writer, node, "optional")
	CopyAttribIfPresent(writer, node, "sync", "externalsync")
	if(node.attr["auto-validity"] ~= nil) then
		writer:AddAttribute("noautovalidity", tostring(node.attr["auto-validity"] == "false"))
	end
		
	--`len` is complex.
	if(node.attr.array == "dynamic") then
		--There is a `len` of some form.
		local length = {}
		if(node.attr.size) then
			length[#length + 1] = node.attr.size
		end
		if(node.attr["null-terminate"]) then
			length[#length + 1] = "null-terminated"
		end
		
		writer:AddAttribute("len", table.concat(length, ","))
	end
	
	--Now, write the typing information.
	funcs.OldWritePrenameType(writer, node, true)
	
	--Insert the name.
	writer:AddText(" ")

	writer:PushElement("name")
	writer:AddText(node.attr.name)
	writer:PopElement()
	
	--Add any static array stuff.
	if(node.attr.array == "static") then
		--Static array numeric sizes don't need an element.
		--Non-numeric sizes do.
		writer:AddText("[")
		if(node.attr.size:match("^%d+$")) then
			writer:AddText(node.attr.size)
		else
			writer:PushElement("enum")
			writer:AddText(node.attr.size)
			writer:PopElement()
		end
		writer:AddText("]")
	end
end

--Creates a new table containing the standard enum model stuff.
function funcs.TableAttribToOldEnumModel()
	return
	{
		name = "name",
		number = "value",
		hex = "value",
		["c-expression"] = "value",
		bitpos = "bitpos",
	}
end



--Processing just the refs.
local toOldRefs =
{
	{	test = "defref",
		
		element =
		{	name = "type",
			attribs =
			{
				name = "name",
				notation = "comment",
			},
		}
	},
	{	test = "commandref",
		
		element =
		{	name = "command",
			attribs =
			{
				name = "name",
				notation = "comment",
			},
		},
	},
	{	test = "enumref",
		
		element =
		{	name = "enum",
			attribs =
			{
				name = "name",
				notation = "comment",
			},
		},
	},
}


local toOldContantAttribs = funcs.TableAttribToOldEnumModel()
--Quoted string
toOldContantAttribs["string"] = function(value, node) return "value", '"' .. value .. '"' end
toOldContantAttribs["enumref"] = "value"

local toOldEnumAttribs = funcs.TableAttribToOldEnumModel()
toOldEnumAttribs["extends"] = true
toOldEnumAttribs["offset"] = true
toOldEnumAttribs["negate"] = function(value, node)
	if(value == "true") then
		return "dir", "-"
	else
		return nil, nil
	end
end

--Constant and enum processing.
local toOldDeclarations =
{
	{	test = "constant",
	
		element =
		{	name = "enum",
			attribs = toOldContantAttribs,
		},
	},
	{	test = "enum",
	
		element =
		{	name = "enum",
			attribs = toOldEnumAttribs,
		},
	},
}

local toOldValidity =
{	test = "validity",

	children =
	{
		{	test = "usage",
			element =
			{	name = "usage",
				attribs =
				{
					struct = "struct",
					command = "command",
				},
				
				proc = function(writer, node)
					writer:AddText(funcs.ExtractFullText(node))
				end
			},
		},
	},
}

--Generates table for converting request/removes to the old format.
function funcs.TableConvToOldReqRem(isFeature)
	local children = {}
	for _, test in ipairs(toOldRefs) do
		children[#children + 1] = test
	end
	if(isFeature == false) then
		for _, test in ipairs(toOldDeclarations) do
			children[#children + 1] = test
		end
	end
	
	children[#children + 1] = toOldValidity
	
	return
	{
		{	test = "require",
			
			element =
			{	name = "require",
				attribs =
				{
					profile = "profile",
					notation = "comment",
					api = iff(isFeature == false, "api", nil),
				},
			},
			
			children = children,
		},
		{	test = "remove",
			
			element =
			{	name = "remove",
				attribs =
				{
					profile = "profile",
					notation = "comment",
					api = iff(isFeature == false, "api", nil),
				},
			},
			
			children = children,
		},
	}
end

funcs.cmdStructValidityToOld =
{
	test = "validity",
	
	element =
	{
		name = "validity",
	},
	
	children =
	{
		{
			test = "usage",
			
			element =
			{
				name = "usage",
				
				proc = function(writer, node)
					writer:AddText(funcs.ExtractFullText(node))
				end
			},
		},
	}
}


--Returns a child element of `node` named `name`.
function funcs.FindChildElement(node, name)
	for _, elem in ipairs(node.el) do
		if(elem.name == name) then
			return elem
		end
	end
	
	return nil
end

--Returns the first text node in `node` after `start`.
--`start` defaults to 0.
--Also returns the index of the node.
function funcs.FindNextText(node, start)
	start = start or 0
	for i = start + 1, #node.kids do
		local test = node.kids[i]
		if(test.type == "text") then
			return test, i
		end
	end
	
	return nil, nil
end

local function ExtractText(node, list)
	for _, child in ipairs(node.kids) do
		if(child.type == "text") then
			list[#list + 1] = child.value
		elseif(child.type == "element") then
			ExtractText(child, list)
		end
	end
end

function funcs.ExtractFullText(node)
	local list = {}
	if(node.type == "text") then
		return node.value
	else
		ExtractText(node, list)
	end
	return table.concat(list)
end

return funcs