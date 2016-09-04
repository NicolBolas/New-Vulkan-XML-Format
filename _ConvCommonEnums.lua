--Utility functions for converting to/from enumerators and constants

require "_Utils"
local common = "_ConvCommon"

local funcs = {}

--Creates a new table containing the standard enum model stuff.
function funcs.TableAttribToOldEnumModel()
	return
	{
		name = "name",
		notation = "comment",
		number = "value",
		hex = function(value, node)
			return "value", "0x" .. value
		end,
		["c-expression"] = "value",
		bitpos = "bitpos",
	}
end

--Takes an `enum` node in the old format. Returns the
--name of the attribute in the new format to use and the data to store in it.
function funcs.OldEnumNodeToNewAttrib(node)
	if(node.attr.value) then
		local value = node.attr.value
		if(value:match("^[+-]?%d+$")) then
			return "number", value
		else
			local hex = value:match("^0x(%d+)$")
			if(hex) then
				return "hex", hex
			else
				return "c-expression", value
			end
		end
	end
	
	if(node.attr.bitpos) then
		return "bitpos", node.attr.bitpos
	end
	
	assert(false, node.attr.name)
end



return funcs
