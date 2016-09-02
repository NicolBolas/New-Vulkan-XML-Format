--Utility functions for dealing with converting to/from
--	variables,
--	return types,
--	function params,
--	and other things dealing with C types.

require "_Utils"
local common = require "_ConvCommon"

local funcs = {}


-------------------------------------------------------
-- OLD TO NEW
--Also returns the remainder of the string after the match.
--Or the entire string if nothing matched.
local function CheckPtrs(str)
	local tests =
	{
		{
			ref = "pointer-const-pointer",
			pttn = "%*%s*const%s*%*",
		},
		{
			ref = "pointer-pointer",
			pttn = "%*%s*%*",
		},
		{
			ref = "pointer",
			pttn = "%*",
		},
	}
	
	for _, test in ipairs(tests) do
		local match = str:match(test.pttn)
		if(match) then
			return test.ref, str:sub(#match)
		end
	end
	
	return nil, str
end

--Processes a variable that's written in plain text (no elements).
--If `type_only` is true, then the string is just the type, with no name or anything else.
--Returns a table containing:
--	`const = true`: if it is a const type.
--	`struct = true`: if the basetype needs the `struct` prefix.
--	`bastype`: The basic type
--	`reference`: One of the reference strings, if any.
--	`name`: The name of the variable, if any.
--Also returns the unparsed portion 
function funcs.ParseTextType(str, type_only)
	local typedef = {}

	local pattern = "%s*([^%s*]+)(.*)";
	local token, next = str:match(pattern)
	while(token) do
		if(token == "const") then
			typedef.const = "true"
		elseif(token == "struct") then
			typedef.struct = "true"
		else
			typedef.basetype = token
			break
		end
		token, next = next:match(pattern)
	end
	
	local reference
	reference, next = CheckPtrs(next)
	typedef.reference = reference
	
	if(not type_only) then
		token, next = next:match("%s*([%a_][%w_]+)(.*)")
		typedef.name = token
		
		--Parse array sizes?
	end
	
	return typedef, next
end


-------------------------------------------------------
-- NEW TO OLD
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
