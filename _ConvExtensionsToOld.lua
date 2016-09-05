
local common = require "_ConvCommon"
local convert = require "_ConvCommonConvert"

local children =
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
				notation = "comment",
				define = "protect",
			},
			
			attribs =
			{
				supported = function(node)
					if(node.attr.disabled) then
						return "disabled"
					end
					return node.attr["match-api"]
				end
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