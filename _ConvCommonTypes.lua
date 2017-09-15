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

--Advances pos to the next child of `mem_node` (pos may be zero)
--Skips any node that is a `comment` element.
local function AdvanceAndSkipComments(mem_node, pos)

	repeat
		pos = pos + 1
		local sub_node = mem_node.kids[pos]
	until((not sub_node) or sub_node.type ~= "element" or sub_node.name ~= "comment")

	return mem_node.kids[pos], pos
end

--Returns a table containing (in accord with reg.struct.member.attlist:
--	`const = true`: if it is a const type.
--	`struct = true`: if the basetype needs the `struct` prefix.
--	`bastype`: The basic type
--	`reference`: One of the reference strings, if any.
--	`name`: The name of the variable, if any.
--	`array`
--	`size`
--	`size-enumref`
--	`c-size`
--	`sync`
--	`extension-structs`
--	`auto-validity`
--	`type-enums`
--A second return value is a table of `comment` strings, or nil if there are no comments.
function funcs.ParseMemberParam(mem_node)
	local member = {}
	
	--Get member flags and fields.
	member.optional = mem_node.attr.optional
	member["c-size"] = mem_node.attr.altlen

	if(mem_node.attr.len) then
		--Length is a comma-separated list.
		for len_data in mem_node.attr.len:gmatch("[^,]+") do
			if(len_data == "null-terminated") then
				assert(member["null-terminate"] == nil)
				member["null-terminate"] = true
				member.array = "dynamic"
			else
				assert(member.size == nil)
				member.size = len_data
				member.array = "dynamic"
			end
		end
	end
	if(mem_node.attr.externsync) then
		if(mem_node.attr.externsync == "true") then
			member.sync = true
		else
			member.sync = mem_node.attr.externsync
		end
	end
	if(mem_node.attr.noautovalidity) then
		--Simple true/false
		member["auto-validity"] = mem_node.attr.noautovalidity ~= "true"
	end
	if(mem_node.attr.validextensionstructs) then
		member["extension-structs"] = mem_node.attr.validextensionstructs
	end
	if(mem_node.attr.values) then
		member["type-enums"] = mem_node.attr.values
	end

	local sub_node, pos = AdvanceAndSkipComments(mem_node, 0)
	
	--Check for const and/or struct.
	if(sub_node.type == "text") then
		local test = sub_node.value:match("const")
		if(test) then
			member.const = true
		end
		test = sub_node.value:match("struct")
		if(test) then
			member.struct = true
		end
		
		assert(member.const or member.struct)
		sub_node, pos = AdvanceAndSkipComments(mem_node, pos)
	end
	
	--Extract type.
	assert(sub_node.type == "element" and sub_node.name == "type")
	member.basetype = common.ExtractFullText(sub_node)
	
	sub_node, pos = AdvanceAndSkipComments(mem_node, pos)
	
	--Extract pointer/references.
	--Sometimes, no text between `type` and `name`.
	if(sub_node.type == "text") then
		local reference = CheckPtrs(sub_node.value)
		if(reference) then
			member.reference = reference
		end
	
		sub_node, pos = AdvanceAndSkipComments(mem_node, pos)
	end

	--Extract the member name.
	assert(sub_node.type == "element" and sub_node.name == "name")
	member.name = common.ExtractFullText(sub_node)
	
	--Extract static arrays.
	sub_node, pos = AdvanceAndSkipComments(mem_node, pos, member.name)
	
	if(sub_node) then
		assert(sub_node.type == "text")
		--Cannot already have an array
		assert(member.array == nil)
		member.array = "static"
		local match = sub_node.value:match("%[(.+)%]")
		if(match) then
			member.size = assert(tonumber(match))
		else
			pos = pos + 1
			sub_node = mem_node.kids[pos]
			assert(sub_node.type == "element")
			member["size-enumref"] = common.ExtractFullText(sub_node)				
		end
	end
	
	--[[
	--Find all comment children.
	local comments = {}
	
	for _, elem in ipairs(node.el) do
		if(elem.name == "comment") then
			comments[#comments + 1] = common.ExtractFullText(elem))
		end
	end
	
	if(#comments == 0) then
		comments = nil
	end
	]]
	
	return member
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
	common.CopyAttribIfPresent(writer, node, "sync", "externsync")
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

	if(node.attr["c-size"]) then
		writer:AddAttribute("altlen", node.attr["c-size"])
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
		if(node.attr.size) then
			writer:AddText(node.attr.size)
		else
			writer:PushElement("enum")
			writer:AddText(node.attr["size-enumref"])
			writer:PopElement()
		end
		writer:AddText("]")
	end
end

return funcs
