
local common = require "_ConvCommon"

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

		children = common.TableConvToOldReqRem(true),
	},
}

return {
	test = "features",
	
	children = children
}