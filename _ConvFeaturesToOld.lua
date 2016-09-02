
local common = require "_ConvCommon"
local convert = require "_ConvCommonConvert"

local children =
{
	{	test = "feature",
		
		element =
		{	name = "feature",
			
			map_attribs =
			{
				name = "name",
				notation = "comment",
				api = "api",
				version = "number",
				define = "protect",
			},
		},

		children = convert.TableConvToOldReqRem(true),
	},
}

return {
	test = "features",
	
	children = children
}