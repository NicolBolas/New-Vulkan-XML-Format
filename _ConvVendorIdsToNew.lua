require "_Utils"
local common = require "_ConvCommon"

return {	test = "vendorids",
	element =
	{	name = "vendorids",
		map_attribs =
		{	comment = "notation",
		},
	},
	
	children =
	{
		{	test = "vendorid",
			element =
			{	name = "vendorid",
				map_attribs =
				{	name = "name",
					id = "id",
					comment = "notation",
				},
			},
		},
	},
}
