
local write_utils = require "_NewFormatUtils"

local writers =
{
	constant = write_utils.AttributeWriter("constant", {"name", "number", "c-expression", "notation"})
}

return writers
