
local common = require "_ConvCommon"

local children =
{
	{
		test = "vendorid",
		element =
		{
			name = "vendorid",
			
			attribs =
			{
				id = "id",
				name = "name",
				notation = "comment",
			},
		},
	},
}

return {
	test = "vendorids",
	
	element =
	{
		name = "vendorids",
	},
	
	children = children
}