require "_Utils"
local common = require "_ConvCommon"

return {	test = "comment",
	element =
	{	name = "notation",
	
		proc = function(writer, node)
			writer:AddText(common.ExtractFullText(node))
		end
	},
	
	children = {},
}
