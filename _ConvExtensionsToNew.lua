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
					name = true,
					number = true,
					author = true,
					contact = true,
					requires = true,
					type = true,
					protect = "define",
					comment = "notation",
				},
				
				attribs =
				{
					["match-api"] = function(node)
						if(node.attr.supported and node.attr.supported ~= "disabled") then
							return node.attr.supported
						end
					end,
					disabled = function(node)
						if(node.attr.supported == "disabled") then
							return "true"
						end
					end,
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
