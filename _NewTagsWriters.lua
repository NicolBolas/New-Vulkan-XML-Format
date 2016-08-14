
local write_utils = require "_NewFormatUtils"

local writers =
{
	tag = write_utils.AttributeWriter("tag", {"name", "author", "contact", "notation"})
}

return writers
