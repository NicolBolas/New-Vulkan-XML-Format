require "_Utils"
local common = require "_ConvCommon"
local types = require "_ConvCommonTypes"
local convert = require "_ConvCommonConvert"


return {	test = "extensions",

	element =
	{	name = "extensions",
	},
	
	children =
	{	
		{	test = "extension",
			element =
			{	name = "extension",
				map_attribs =
				{
					name = "name",
					number = true,
					author = true,
					contact = true,
					protect = "define",
					supported = "match-api",
					comment = "notation",
				},
			},
			
			children =
			{
				convert.ToNewReqRem(false, true),
				convert.ToNewReqRem(true, true),
			},
		},
	},
}
