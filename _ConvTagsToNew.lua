require "_Utils"
local common = require "_ConvCommon"

return {	test = "tags",
	element =
	{	name = "tags",
		map_attribs =
		{	comment = "notation",
		},
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
