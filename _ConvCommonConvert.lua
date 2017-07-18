--Utilities for general conversion of elements to/from formats.

require "_Utils"
local common = require "_ConvCommon"
local enums = require "_ConvCommonEnums"

local funcs = {}

-------------------------------------------------------
-- OLD TO NEW
funcs.toNotation =
{	test = "comment",
	element =
	{	name = "notation",

		proc = function(writer, node)
			writer:AddText(common.ExtractFullText(node))
		end,
	},
}

local toNewReqRemUsage =
{	test = "usage",
	collate =
	{
		start = "validity",
	},
	
	element =
	{	name = "usage",
	
		map_attribs =
		{
			command = true,
			struct = true,
		},

		proc = function(writer, node)
			writer:AddText(common.ExtractFullText(node))
		end
	},
}

local toNewReqRemCommand =
{	test = "command",
	element =
	{	name = "commandref",
		map_attribs =
		{
			name = "name",
			comment = "notation",
		},
	},
}

local toNewReqRemType =
{	test = "type",
	element =
	{	name = "defref",
		map_attribs =
		{
			name = "name",
			comment = "notation",
		},
	},
}

--All `enum`s in features are `enumref`s
local toNewReqRemEnumFeature =
{	test = "enum",
	element =
	{	name = "enumref",
		map_attribs =
		{
			name = "name",
			comment = "notation",
		},
	},
}

local toNewReqRemEnumExtension =
{	test = function(node)
		return node.type == "element" and node.attr.extends
	end,
	
	element =
	{	name = "enum",
		map_attribs =
		{
			name = true,
			comment = "notation",
			extends = true,
		},
		
		proc = function(writer, node)
			if(node.attr.offset) then
				writer:AddAttribute("offset", node.attr.offset)
				if(node.attr.dir == "-") then
					writer:AddAttribute("negate", "true")
				end
			else
				local name, value = enums.OldEnumNodeToNewAttrib(node)
				writer:AddAttribute(name, value)
			end
		end
	},
}

--In extensions, `enum`s which have no data are `enumref`s.
local toNewReqRemEnumrefFromEnum =
{
	test = function(node)
		if(node.type ~= "element") then return false end
		if(node.name ~= "enum") then return false end
		
		--Reference elements only have `name` and optionally `comment` attributes.
		for attrib, _ in pairs(node.attr) do
			if(not (type(attrib) == "number" and attrib <= #node.attr)) then
				if(attrib ~= "name" and attrib ~= "comment") then return false end
			end
		end
		
		return true
	end,
	element =
	{	name = "enumref",
		map_attribs =
		{
			name = "name",
			comment = "notation",
		},
	},
}

local toNewReqRemConstant =
{	test = "enum",
	element = 
	{	name = "constant",
	
		map_attribs =
		{
			name = true,
			comment = "notation",
		},

		proc = function(writer, node)
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
--				else
--					name, value = enums.OldEnumNodeToNewAttrib(node)
				end
			end
			
			--Haven't found it yet, so probably a bitpos
			if(not name) then
				name, value = enums.OldEnumNodeToNewAttrib(node)
			end
			
			assert(name, node.name)
			writer:AddAttribute(name, value)
		end,
	},
}


local toNewExtensionReqRem =
{
	toNewReqRemEnumrefFromEnum,
	toNewReqRemEnumExtension,
	toNewReqRemConstant,
	toNewReqRemType,
	toNewReqRemCommand,
	toNewReqRemUsage,
	funcs.toNotation,
}

local toNewFeatureReqRem =
{
	toNewReqRemEnumFeature,
	toNewReqRemType,
	toNewReqRemCommand,
	toNewReqRemUsage,
	funcs.toNotation,
}

function funcs.ToNewReqRem(is_remove, is_extension)
	local name = iff(is_remove, "remove", "require")
	local req_rem =
	{	test = name,
		element =
		{	name = name,
			map_attribs =
			{
				profile = "profile",
				comment = "notation",
			},
		},
		
		children = iff(is_extension, toNewExtensionReqRem, toNewFeatureReqRem),
	}
	
	if(is_extension) then
		req_rem.element.map_attribs.api = "api"
	end
	
	return req_rem
end


funcs.toNewValidity =
{	test = function(node)
		if(node.type == "element" and node.name == "validity") then
			--If no usage, don't write a validity.
			if(common.FindChildElement(node, "usage")) then
				return true
			else
				return false
			end
		end
	end,
	element =
	{	name = "validity",
	},
	
	children =
	{
		{	test = "usage",
			element =
			{	name = "usage",
			
				proc = function(writer, node)
					writer:AddText(common.ExtractFullText(node))
				end
			},
		},
	}
}




-------------------------------------------------------
-- NEW TO OLD
funcs.toOldComment =
{	test = "notation",
	element =
	{	name = "comment",
	
		proc = function(writer, node)
			writer:AddText(common.ExtractFullText(node))
		end
	},
}

--Processing just the refs.
local toOldRefs =
{
	{	test = "defref",
		
		element =
		{	name = "type",
			map_attribs =
			{
				name = "name",
				notation = "comment",
			},
		}
	},
	{	test = "commandref",
		
		element =
		{	name = "command",
			map_attribs =
			{
				name = "name",
				notation = "comment",
			},
		},
	},
	{	test = "enumref",
		
		element =
		{	name = "enum",
			map_attribs =
			{
				name = "name",
				notation = "comment",
			},
		},
	},
}


local toOldContantAttribs = enums.TableAttribToOldEnumModel()
--Quoted string
toOldContantAttribs["string"] = function(value, node) return "value", '"' .. value .. '"' end
toOldContantAttribs["enumref"] = "value"

local toOldEnumAttribs = enums.TableAttribToOldEnumModel()
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
			map_attribs = toOldContantAttribs,
		},
	},
	{	test = "enum",
	
		element =
		{	name = "enum",
			map_attribs = toOldEnumAttribs,
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
				map_attribs =
				{
					struct = "struct",
					command = "command",
				},
				
				proc = function(writer, node)
					writer:AddText(common.ExtractFullText(node))
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
	children[#children + 1] = funcs.toOldComment
	
	return
	{
		{	test = "require",
			
			element =
			{	name = "require",
				map_attribs =
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
				map_attribs =
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
					writer:AddText(common.ExtractFullText(node))
				end
			},
		},
	}
}


return funcs
