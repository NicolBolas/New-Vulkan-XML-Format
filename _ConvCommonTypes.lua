--Utility functions for dealing with converting to/from
--	variables,
--	return types,
--	function params,
--	and other things dealing with C types.

require "_Utils"
local common = require "_ConvCommon"

local funcs = {}

local old_reference_map =
{
	["pointer"] = "*",
	["pointer-const-pointer"] = "* const*",
	["pointer-pointer"] = "**",
}

--Writes the text before the name of the value.
--Does not write any array information.
--`wrapInType` if true, then the basetype will be wrapped in a <type> node
function funcs.OldWritePrenameType(writer, type_node, wrapInType)
	if(type_node.attr.const == "true") then
		writer:AddText("const ")
	end
	
	if(type_node.attr.struct == "true") then
		writer:AddText("struct ")
	end
	
	if(wrapInType) then
		writer:PushElement("type")
	end
	
	writer:AddText(type_node.attr.basetype)
	
	if(wrapInType) then
		writer:PopElement()
	end
	
	if(type_node.attr.reference) then
		local ref = old_reference_map[type_node.attr.reference]
		assert(ref)
		writer:AddText(ref)
	end
end

function funcs.OldWriteVariable(writer, node, rawName)
	--Write the typed.variable.model attributes.
	common.CopyAttribIfPresent(writer, node, "optional")
	common.CopyAttribIfPresent(writer, node, "sync", "externalsync")
	if(node.attr["auto-validity"] ~= nil) then
		writer:AddAttribute("noautovalidity", tostring(node.attr["auto-validity"] == "false"))
	end
		
	--`len` is complex.
	if(node.attr.array == "dynamic") then
		--There is a `len` of some form.
		local length = {}
		if(node.attr.size) then
			length[#length + 1] = node.attr.size
		end
		if(node.attr["null-terminate"]) then
			length[#length + 1] = "null-terminated"
		end
		
		writer:AddAttribute("len", table.concat(length, ","))
	end
	
	--Now, write the typing information.
	funcs.OldWritePrenameType(writer, node, true)
	
	--Insert the name.
	writer:AddText(" ")

	if(rawName) then
		writer:AddText(node.attr.name)
	else
		common.WriteTextElement(writer, "name", node.attr.name)
	end
	
	--Add any static array stuff.
	if(node.attr.array == "static") then
		--Static array numeric sizes don't need an element.
		--Non-numeric sizes do.
		writer:AddText("[")
		if(node.attr.size:match("^%d+$")) then
			writer:AddText(node.attr.size)
		else
			writer:PushElement("enum")
			writer:AddText(node.attr.size)
			writer:PopElement()
		end
		writer:AddText("]")
	end
end

return funcs
