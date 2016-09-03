require "_Utils"
local common = require "_ConvCommon"
local types = require "_ConvCommonTypes"
local convert = require "_ConvCommonConvert"


return {	test = "feature",
	collate =
	{
		start = "features",
	},

	element =
	{	name = "feature",
		map_attribs =
		{
			name = "name",
			api = "api",
			comment = "notation",
			number = "version",
			protect = "define",
		},
	},
	
	children =
	{
		convert.ToNewReqRem(false, false),
		convert.ToNewReqRem(true, false),
	},
}
