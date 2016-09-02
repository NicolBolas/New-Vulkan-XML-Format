require "_Utils"
local common = require "_ConvCommon"
local enums = require "_ConvCommonEnums"

local enumerator =
{	test = "enum",
	element =
	{	name = "enum",
		map_attribs =
		{
			name = "name",
			comment = "notation",
		},
		
		proc = function(writer, node)
			local attrib, data = enums.OldEnumNodeToNewAttrib(node)
			writer:AddAttribute(attrib, data)
		end
	},
}

local unused =
{	test = "unused",
	element =
	{	name = "unused-range",
		map_attribs =
		{
			start = "range-start",
			["end"] = "range-end",
		},
	},
}

return {	test = "enums",

	collate =
	{
		start = "enums",
	},

	element =
	{	name = "enumeration",
		map_attribs =
		{
			name = "name",
			comment = "notation",
			start = "range-start",
			["end"] = "range-end",
		},
		
		attribs =
		{
			purpose = function(node)
				if(node.attr.type == "bitmask") then
					return "bitmask"
				else
					return nil
				end
			end,
		},
	},
	
	children =
	{
		enumerator,
		unused,
	},
}
