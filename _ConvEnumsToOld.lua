
local common = require "_ConvCommon"
local enums = require "_ConvCommonEnums"
local convert = require "_ConvCommonConvert"

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
	convert.toOldComment,
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
	convert.toOldComment,
}

return {
	test = "enums",
	
	children = children
}