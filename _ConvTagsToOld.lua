
local common = require "_ConvCommon"

local children =
{
	{
		test = "tag",
		element =
		{
			name = "tag",
			
			map_attribs =
			{
				name = "name",
				author = "author",
				contact = "contact",
			},
		},
	},
}

return {
	test = "tags",
	
	element =
	{
		name = "tags",
	},
	
	children = children
}