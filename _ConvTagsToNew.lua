require "_Utils"
local common = require "_ConvCommon"

return {	test = "tags",
	element =
	{	name = "tags",
	},
	
	children =
	{
		{	test = "tag",
			element =
			{	name = "tag",
				map_attribs =
				{	name = "name",
					author = "author",
					contact = "contact",
				},
			},
		},
	},
}
