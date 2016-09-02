
local common = require "_ConvCommon"
local enums = require "_ConvCommonEnums"



local enumerator =
{
	{
		test = "enum",
		
		element =
		{
			name = "enum",
			
			map_attribs = enums.TableAttribToOldEnumModel(),
		},
	},
	
	{
		test = "unused-range",
		
		element =
		{
			name = "unused",
			
			map_attribs =
			{
				["range-start"] = "start",
				["range-end"] = "end",
			},
		},
	},
}

local children =
{
	{
		test = "enumeration",
		
		element =
		{
			name = "enums",
			
			map_attribs =
			{
				name = "name",
				purpose = "type",
				notation = "comment",
				["range-start"] = "start",
				["range-end"] = "end",
			},
			
			proc = function(writer, node)
				if(not node.attr.purpose) then
					writer:AddAttribute("type", "enum")
				end
			end
		},

		children = enumerator,
	},
}

return {
	test = "enums",
	
	children = children
}