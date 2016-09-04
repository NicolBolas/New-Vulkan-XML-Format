
local common = require "_ConvCommon"
local convert = require "_ConvCommonConvert"

local children =
{
	{	test = "extension",
		
		element =
		{	name = "extension",
			
			map_attribs =
			{
				name = "name",
				number = "number",
				notation = "comment",
				["match-api"] = "supported",
				define = "protect",
				author = "author",
				contact = "contact",
			},
		},

		children = convert.TableConvToOldReqRem(false),
	},
}

return {
	test = "extensions",
	
	element =
	{	name = "extensions",
	},
	
	children = children
}