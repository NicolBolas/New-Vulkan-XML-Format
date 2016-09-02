require "_Utils"
local common = require "_ConvCommon"
local types = require "_ConvCommonTypes"

local function TestCategory(cat)
	return function(node)
		return (node.type == "element") and
			node.name == "type" and
			node.attr.category == cat
	end
end

--May be an attribute `name` or a `name` child element.
local function GetIncludeName(node)
	if(node.attr.name) then
		return node.attr.name
	end
	
	local elem = common.FindChildElement(node, "name")
	if(elem) then
		return common.ExtractFullText(elem)
	end
	
	assert(false)
end

local child_include =
{	test = TestCategory("include"),
	element =
	{	name = "include",
		attribs =
		{
			name = GetIncludeName,
			["need-ext"] = function(node)
				local name = GetIncludeName(node)
				if(name:match("%.h$")) then
					return nil
				else
					return "true"
				end
			end,
			style = function(node)
				local include_stmt = common.FindNextText(node).value
				local inc_char = include_stmt:match("%#include%s+([\"<])")
				
				assert(inc_char)
				
				if(inc_char == '<') then
					return "bracket"
				else
					return "quote"
				end
			end
		},
	},
}


local child_require =
{	test = function(node)
		return node.name == "type" and node.attr.category == nil and node.attr.requires
	end,
	
	element =
	{	name = "reference",
		map_attribs =
		{
			name = "name",
			requires = "include",
		},
	},
}

local child_define =
{	test = TestCategory("define"),
	element =
	{	name = "define",
		attribs =
		{
			name = function(node)
				if(node.attr.name) then
					return node.attr.name
				else
					local name = common.FindChildElement(node, "name")
					name = common.ExtractFullText(name)
					assert(#name > 0)
					return name
				end
			end,
			replace = function(node)
				if(node.attr.name) then
					return true
				else
					return nil
				end
			end,
		},
		
		proc = function(writer, node)
			--DON'T WRITE ELEMENTS UNTIL THE END.
			--Search for any `type` child nodes. These are references to definitions.
			local defrefs = {}
			for _, child in ipairs(node.el) do
				if(child.name == "type") then
					local name = common.ExtractFullText(child)
					defrefs[#defrefs + 1] = name
				end
			end
			
			--Search for a prefixing comment in the overall text.
			local whole_text = common.ExtractFullText(node)
			local text_lines = {}
			for str in whole_text:gmatch("([^\n]+)") do
				text_lines[#text_lines + 1] = str
			end
			
			local comment = {}
			local real_lines = {}
			local storeCommentsInLines = false
			local fullyCommented = true
			for _, str in ipairs(text_lines) do
				local test = str:match("%s*//%s*(.+)")
				if(test) then
					--If the comment is a #define, then it's the actual data.
					if(storeCommentsInLines or test:match("^#define")) then
						storeCommentsInLines = true
						real_lines[#real_lines + 1] = test
					else
						comment[#comment + 1] = test
					end
				else
					real_lines[#real_lines + 1] = str
					fullyCommented = false
				end
			end
			
			if(#real_lines == 0) then
				real_lines = text_lines
			end
			if(fullyCommented) then
				writer:AddAttribute("disabled", "true")
			end
			
			--Extract the actual C-expression.
			local c_expression
			local params = {}
			if(node.attr.name) then
				--Replace the whole thing.
				c_expression = table.concat(text_lines, "\n")
			else
				--Find the #define in the real_lines.
				local relevant_text
				for _, line in ipairs(real_lines) do
					local check = line:match("#define%s+([_%a][_%w]*)")
					if(check) then
						relevant_text = table.concat(real_lines, "\n", _)
						break
					end
				end
				
				--See if there are parameters
				local param_text, expr = relevant_text:match("#define%s+[_%a][_%w]*(%b())%s*(.+)")
				if(not param_text) then
					expr = relevant_text:match("#define%s+[_%a][_%w]*%s*(.+)")
				else
					--Remove parens
					param_text = param_text:sub(2, #param_text - 1)
					for param in param_text:gmatch("([_%a][_%w]+)") do
						params[#params + 1] = param
					end
				end
				
				if(param_text) then
					c_expression = expr
				else
					local num = expr:match("^%s*(%d+)%s*$")
					if(num) then
						writer:AddAttribute("value", num)
					else
						c_expression = expr
					end
				end
			end
			
			
			--WRITE ELEMENTS PAST THIS POINT.
			if(#comment > 0) then
				common.WriteTextElement(writer, "comment", table.concat(comment, "\n"))
			end

			for _, defref in ipairs(defrefs) do
				common.WriteTextElement(writer, "defref", defref)
				did_write_element = true
			end
			
			for _, param in ipairs(params) do
				common.WriteTextElement(writer, "param", param)
			end
			
			if(c_expression) then
				common.WriteTextElement(writer, "c-expression", c_expression)
			end
			
			return data
		end
	},
}

local children =
{
	child_include,
	child_require,
	child_define,
}

return {	test = "types",
	element =
	{	name = "definitions",
	},
	
	children = children,
}
