
local common = require "_ConvCommon"

local children =
{
	{
		test = "constant",
		
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
}

return {
	test = "constants",
	
	element =
	{
		name = "enums",
		
		attribs =
		{
			notation = "comment"
		},
		
		proc = function(writer, node)
			writer:AddAttribute("name", "API Constants")
		end
	},
	
	children = children
}