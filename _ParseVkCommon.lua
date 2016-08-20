--Common parsing tools

local parse_dom = require "_ParseVkDom"

local funcs = {}

--Returns the name of the attribute for the output and the data.
function funcs.ExtractEnumNameData(node)
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



function funcs.rtrim(s)
  local n = #s
  while n > 0 and s:find("^%s", n) do n = n - 1 end
  return s:sub(1, n)
end

function funcs.CheckPtrs(str, no_prefix)
	local tests =
	{
		{
			ref = "pointer-const-pointer",
			pttn_prefix = "(.+)%*%s*const%s*%*",
			pttn = "%*%s*const%s*%*",
		},
		{
			ref = "pointer-pointer",
			pttn_prefix = "(.+)%*%s*%*",
			pttn = "%*%s*%*",
		},
		{
			ref = "pointer",
			pttn_prefix = "(.+)%*",
			pttn = "%*",
		},
	}
	
	for _, test in ipairs(tests) do
		local pttn = no_prefix and test.pttn or test.pttn_prefix
		local match = str:match(pttn)
		if(match) then
			return match, test.ref
		end
	end
	
	return nil, nil
end

--Processes a return type string (no elements).
--Returns a table appropriate to "return-type".
--Pass `true` to `no_prefix` if the return type 
function funcs.ParseReturnType(return_string, no_prefix)
	local return_type = {}
	--Transform return type string into data.
	--Could have `const`
	local non_const = return_string:match("const (.+)")
	if(non_const) then
		return_string = non_const
		return_type.const = true
	end
	
	--Could have pointers.
	local non_pointer, reference = funcs.CheckPtrs(return_string, no_prefix)
	if(non_pointer) then
		return_string = non_pointer
		return_type.reference = reference
	end

	--Whatever is left is the base type.
	return_type.basetype = funcs.rtrim(return_string)
	
	return return_type
end

--Extracts a `member` or `param` from a struct or command member.
--These are expected to wrap the member/param name and type in `<name>`
--and `<type>` elements
--Returns the parsed node.
function funcs.ParseMemberParam(mem_node)
	local member = {}
	
	--Get member flags and fields.
	if(mem_node.attr.optional == "true") then
		member.optional = true
	end
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

	local pos = 1
	local sub_node = mem_node.kids[pos]
	
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
		pos = pos + 1
	end
	
	sub_node = mem_node.kids[pos]
	
	--Extract type.
	assert(sub_node.type == "element" and sub_node.name == "type")
	member.basetype = parse_dom.ExtractFullText(sub_node)
	
	pos = pos + 1
	sub_node = mem_node.kids[pos]
	
	--Extract pointer/references.
	--Sometimes, no text between `type` and `name`.
	if(sub_node.type == "text") then
		local match, reference = funcs.CheckPtrs(sub_node.value, true)
		if(match) then
			member.reference = reference
		end
	
		pos = pos + 1
		sub_node = mem_node.kids[pos]
	end

	--Extract the member name.
	assert(sub_node.type == "element" and sub_node.name == "name")
	member.name = parse_dom.ExtractFullText(sub_node)
	
	--Extract static arrays.
	pos = pos + 1
	sub_node = mem_node.kids[pos]
	
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
			member.size = parse_dom.ExtractFullText(sub_node)				
		end
	end
	
	return member
end


--Processes a struct/command validity node.
--Returns usages, or `nil` if none were found.
function funcs.ParseValidity(validity_node)
	if(#validity_node.el == 0) then
		return nil
	end
	
	local usages = {}
	
	for _, usage in ipairs(validity_node.el) do
		usages[#usages + 1] = parse_dom.ExtractFullText(usage)
	end
	
	--Sometimes, there are validity statements with no usages.
	--We don't want any usages then.
	return usages
end

return funcs