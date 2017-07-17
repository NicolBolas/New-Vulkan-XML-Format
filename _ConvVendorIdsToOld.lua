
local common = require "_ConvCommon"

local children =
{
	{
		test = "vendorid",
		element =
		{
			name = "vendorid",
			
			map_attribs =
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
	{	name = "vendorids",
		map_attribs =
		{	notation = "comment",
		},
	},
	
	children = children
}