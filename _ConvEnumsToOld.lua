
local common = require "_ConvCommon"

local enumerator =
{
	{
		test = "enum",
		
		element =
		{
			name = "enum",
			
			attribs =
			{
				name = "name",
				number = "value",
				hex = "value",
				["c-expression"] = "value",
				bitpos = "bitpos",
			},
		},
	},
	
	{
		test = "unused-range",
		
		element =
		{
			name = "unused",
			
			attribs =
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
			
			attribs =
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