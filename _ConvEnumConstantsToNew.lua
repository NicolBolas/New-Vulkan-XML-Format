require "_Utils"
local common = require "_ConvCommon"
local enums = require "_ConvCommonEnums"

local enumerator =
{	test = "enum",
	element =
	{	name = "constant",
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

return {	test = function(node)
				return (node.type == "element" and
				node.name == "enums" and
				node.attr.name == "API Constants")
			end,
	element =
	{	name = "constants",
	},
	
	children = {enumerator},
}
