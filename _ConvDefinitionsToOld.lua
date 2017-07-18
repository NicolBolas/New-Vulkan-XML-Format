
require "_Utils"
local common = require "_ConvCommon"
local types = require "_ConvCommonTypes"
local convert = require "_ConvCommonConvert"

--Splits the string into a sequence of strings, based on an identifier.
--So we verify that the character just before it is not a valid identifier character
--and that the character after it is not a valid identifier.
--Replaces the split value with a given value.
local function SplitOnIdent(str, ident, replace)
	local t = {}
	local fpat = "(.-)" .. ident
	local last_end = 1
	local s, e, cap = str:find(fpat, 1)
	while s do
		--Match is either at the beginning or the last character in the capture
		--is not an identifier character.
		local first_char_correct = (#cap == 0 or cap:match("[^_%w]$"))
		--Match is either at the end, or the character after
		--the match is not an identifier character.
		local last_char_correct = (e == #str or str:sub(e + 1, e + 1):match("[^_%w]"))
		
		if(first_char_correct and last_char_correct) then
			if(#cap == 0) then --match at the beginning.
				t[#t + 1] = replace
			else
				t[#t + 1] = cap
				t[#t + 1] = replace
			end
		else
			--If the first or last characters don't work out, then take the whole
			--thing.
			t[#t + 1] = str:sub(s, e)
		end
		
		--Regardless of whether the characters are correct, move to the next
		--character.
		last_end = e + 1
		s, e, cap = str:find(fpat, last_end)
	end

	if last_end <= #str then
		cap = str:sub(last_end)
		t[#t + 1] = cap
	end
	
	return t
end

--[====[
local temp = "_V332A"
local test_strings =
{
	"_V332A",
	"Stuff _V332A",
	"_V332A Stuff",
	"_V332A(Stuff)",
	"(Stuff)_V332A",
	"_V332A Stuff _V332A",
	"_V332A(_V332A)_V332A(_V332A)",
	"Stuff",
	"AD_V332A",
	"_V332AAD",
	"AD_V332AAD",
	"_V332A _V332AAD_V332A _V332A daa-_V332AQ",
}

for _, test in ipairs(test_strings) do
	print('\t"' .. test .. '"')
	local tbl = SplitOnIdent(test, temp, "VAAPAD")
	print('"' .. table.concat(tbl) .. '"', #tbl)
end
]====]

local function CopyArray(out_arr, in_arr)
	local start = #out_arr
	for _, value in ipairs(in_arr) do
		out_arr[start + _] = value
	end
end

local struct_children =
{
	{
		test = "member",
		
		element =
		{	name = "member",
			verbatim = true,
			
			map_attribs =
			{
				["extension-structs"] = "validextensionstructs",
				["type-enums"] = "values",
			},
			
			proc = types.OldWriteVariable,
		},

		children =
		{
			convert.toOldComment,
		},
	},
	convert.cmdStructValidityToOld,
	convert.toOldComment,
}

local children =
{
	{	test = "include",
		
		element =
		{	name = "type",
			verbatim = true,
			
			map_attribs =
			{	name = function(value, node)
					if(node.attr["need-ext"] == "true") then
						return "name", node.attr.name
					end
				end,
				
				notation = "comment",
			},
			
			attribs =
			{	category = "include",
			},
			
			proc = function(writer, node)
				local style = {
					{ quote = '"', bracket = "<"},
					{ quote = '"', bracket = ">"},
				}
				
				writer:AddText("#include ", style[1][node.attr.style])
				if(node.attr["need-ext"] == "true") then
					writer:AddText(node.attr.name, ".h")
				else
					common.WriteTextElement(writer, "name", node.attr.name)
				end
				writer:AddText(style[2][node.attr.style])
			end
		},
	},
	{	test = "typedef",
		
		element =
		{	name = "type",
			verbatim = true,
			
			map_attribs =
			{
				notation = "comment",
			},
			
			proc = function(writer, node)
				writer:AddAttribute("category", "basetype")
				
				writer:AddText("typedef ")
				common.WriteTextElement(writer, "type", node.attr.basetype)
				writer:AddText(" ")
				common.WriteTextElement(writer, "name", node.attr.name)
				writer:AddText(";")
			end
		},
		
		children =
		{
			convert.toOldComment,
		},
	},
	{	test = "reference",
			
		element =
		{	name = "type",
			verbatim = true,
			
			map_attribs =
			{
				name = "name",
				notation = "comment",
				include = "requires",
			},
		},
		
		children =
		{
			convert.toOldComment,
		},
	},
	{	test = "bitmask",
		
		element =
		{	name = "type",
			verbatim = true,
			
			map_attribs =
			{
				notation = "comment",
				enumref = "requires",
			},
			
			proc = function(writer, node)
				writer:AddAttribute("category", "bitmask")
				
				writer:AddText("typedef ")
				common.WriteTextElement(writer, "type", node.attr.basetype)
				writer:AddText(" ")
				common.WriteTextElement(writer, "name", node.attr.name)
				writer:AddText(";")
			end
		},
		
		children =
		{
			convert.toOldComment,
		},
	},
	{	test = "define",
			
		element =
		{	name = "type",
			verbatim = true,
			
			map_attribs =
			{
				notation = "comment",
			},
			
			proc = function(writer, node)
				writer:AddAttribute("category", "define")
				
				if(node.attr.replace == "true") then
					writer:AddAttribute("name", node.attr.name)
				end
				
				local comment = common.FindChildElement(node, "comment")
				if(comment) then
					comment = common.ExtractFullText(comment)
					--Write each line as a comment.
					for str in comment:gmatch("([^\n]+)") do
						writer:AddText("//", str, "\n")
					end
				end
				
				if(node.attr.replace == "true") then
					local c_expr = common.FindChildElement(node, "c-expression")
					writer:AddText(common.ExtractFullText(c_expr))
					return
				end
				
				--Simple "constant" #define.
				if(node.attr.value) then
					if(node.attr.disable == "true") then
						writer:AddText("//")
					end
					writer:AddText("#define ")
					common.WriteTextElement(writer, "name", node.attr.name)
					writer:AddText(" ", node.attr.value)
					return
				end
				
				--Complex #define.
				--Two complicated parts: parameters and
				--defref replacements.
				local defrefs = {}
				local params = {}
				for _, child in ipairs(node.el) do
					if(child.name == "defref") then
						defrefs[#defrefs + 1] = common.ExtractFullText(child)
					elseif(child.name == "param") then
						params[#params + 1] = common.ExtractFullText(child)
					end
				end
				
				if(node.attr.disabled == "true") then
					writer:AddText("//")
				end
				writer:AddText("#define ")
				common.WriteTextElement(writer, "name", node.attr.name)
				if(#params > 0) then
					writer:AddText("(", table.concat(params, ", "),  ")")
				end
				writer:AddText(" ")
				
				--Split c-expression up into lines.
				local c_expr = common.FindChildElement(node, "c-expression")
				c_expr = common.ExtractFullText(c_expr)

				if(node.attr.disabled == "true") then
					--Replace every "\n" with "\n//"
					c_expr:gsub("\n", "\n//")
				end

				
				--TODO: Make defrefs work.
				if(#defrefs ~= 0) then
					local curr_arr = {c_expr}
					local new_arr = {}
					--Split each line of text based on defrefs.
					--Replace the defref text with an array of one element
					--containing the defref name.
					for _, defref in ipairs(defrefs) do
						for _, elem in ipairs(curr_arr) do
							local tbl = SplitOnIdent(elem, defref, {defref})
							CopyArray(new_arr, tbl)
						end
						curr_arr = new_arr
						new_arr = {}
					end
					
					for _, elem in ipairs(curr_arr) do
						if(type(elem) == "string") then
							writer:AddText(elem)
						else
							common.WriteTextElement(writer, "type", elem[1])
						end
					end
				else
					writer:AddText(c_expr)
				end
			end
		}
	},
	{	test = "handle",
		element =
		{	name = "type",
			verbatim = true,
			
			map_attribs =
			{
				notation = "comment",
				parent = "parent",
			},
			
			proc = function(writer, node)
				writer:AddAttribute("category", "handle")
				
				if(node.attr.type == "dispatch") then
					common.WriteTextElement(writer, "type", "VK_DEFINE_HANDLE")
				else
					common.WriteTextElement(writer, "type", "VK_DEFINE_NON_DISPATCHABLE_HANDLE")
				end
				writer:AddText("(")
				common.WriteTextElement(writer, "name", node.attr.name)
				writer:AddText(")")
			end
		},
		
		children =
		{
			convert.toOldComment,
		},
	},
	{	test = "enumeration",
		element =
		{	name = "type",
			
			map_attribs =
			{
				name = "name",
				notation = "comment",
			},
			
			proc = function(writer, node)
				writer:AddAttribute("category", "enum")
			end
		},
		
		children =
		{
			convert.toOldComment,
		},
	},
	{	test = "struct",
		element =
		{	name = "type",
			
			map_attribs =
			{
				name = "name",
				notation = "comment",
				["is-return"] = "returnedonly",
				extends = "structextends",
			},
			
			proc = function(writer, node)
				writer:AddAttribute("category", "struct")
			end
		},
		
		children = struct_children,
	},
	{	test = "union",
		element =
		{	name = "type",
			
			map_attribs =
			{
				name = "name",
				notation = "comment",
			},
			
			proc = function(writer, node)
				writer:AddAttribute("category", "union")
			end
		},
		
		children = struct_children,
	},
	{	test = "funcptr",
		element =
		{	name = "type",
			verbatim = true,
			
			proc = function(writer, node)
				writer:AddAttribute("category", "funcpointer")
				
				writer:AddText("typedef ")
				--write return type, no type element.
				types.OldWritePrenameType(writer,
					common.FindChildElement(node, "return-type"), false)
				writer:AddText(" (VKAPI_PTR *")
				--write name in <name> element.
				common.WriteTextElement(writer, "name", node.attr.name)
				writer:AddText(")(")
				--If no parameters, write "void)".
				local found_param = false
				for _, child in ipairs(node.el) do
					if(child.name == "param") then
						if(found_param) then
							--Not the first parameter, so add a comma.
							writer:AddText(",")
						end
						
						found_param = true
						writer:AddText("\n\t")
						types.OldWriteVariable(writer, child, true)
					end
				end
				
				if(not found_param) then
					writer:AddText("void")
				end
				
				writer:AddText(");")
			end
		},
	},
	convert.toOldComment,
}


return {
	test = "definitions",
	
	element =
	{	name = "types",
		map_attribs =
		{	notation = "comment",
		},
	},
	
	children = children
}
