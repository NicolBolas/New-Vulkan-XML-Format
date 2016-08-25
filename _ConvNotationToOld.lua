
local common = require "_ConvCommon"

return {
	test = "notation",
	
	element =
	{
		name = "comment",
		proc = function(writer, node)
			writer:AddText(common.ExtractFullText(node))
		end
	}
}