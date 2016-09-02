--Utility functions for converting to/from enumerators and constants

require "_Utils"
local common = "_ConvCommon"

local funcs = {}

--Creates a new table containing the standard enum model stuff.
function funcs.TableAttribToOldEnumModel()
	return
	{
		name = "name",
		number = "value",
		hex = "value",
		["c-expression"] = "value",
		bitpos = "bitpos",
	}
end


return funcs
