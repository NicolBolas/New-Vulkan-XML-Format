
local common = require "_ConvCommon"

local children =
{
	{	test = "extension",
		
		element =
		{	name = "extension",
			
			attribs =
			{
				name = "name",
				number = "number",
				notation = "comment",
				["match-api"] = "supported",
				define = "protect",
				author = "number",
				contact = "contact",
			},
		},

		children = common.TableConvToOldReqRem(false),
	},
}

return {
	test = "extensions",
	
	element =
	{	name = "extensions",
	},
	
	children = children
}