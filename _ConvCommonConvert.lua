--Utilities for general conversion of elements to/from formats.

require "_Utils"
local common = require "_ConvCommon"
local enums = require "_ConvCommonEnums"

local funcs = {}

-------------------------------------------------------
-- OLD TO NEW

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
