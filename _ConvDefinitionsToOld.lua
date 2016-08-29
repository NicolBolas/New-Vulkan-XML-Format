
local common = require "_ConvCommon"

local struct_children =
{
	{
		test = "member",
		
		element =
		{
			name = "member",
			verbatim = true,
			
			attribs =
			{
				["extension-structs"] = "validextensionstructs",
				["type-enums"] = "values",
			},
			
			proc = common.OldWriteVariable,
		},
	},
	common.cmdStructValidityToOld,
}

local children =
{
	{	test = "include",
		
		element =
		{	name = "type",
			verbatim = true,
			
			attribs =
			{
				name = function(value, node)
					if(node.attr["need-ext"] == "true") then
						return "name", node.attr.name
					end
				end,
				
				notation = "comment",
			},
			
			proc = function(writer, node)
				local style = {
					{ quote = '"', bracket = "<"},
					{ quote = '"', bracket = ">"},
				}
				
				writer:AddAttribute("category", "include")
				
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
			
			attribs =
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
		}
	},
	{	test = "reference",
			
		element =
		{	name = "type",
			verbatim = true,
			
			attribs =
			{
				name = "name",
				notation = "comment",
				include = "include",
			},
		}
	},
	{	test = "bitmask",
		
		element =
		{	name = "type",
			verbatim = true,
			
			attribs =
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
		}
	},
	{	test = "define",
			
		element =
		{	name = "type",
			verbatim = true,
			
			attribs =
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
					--
					if(child.name == "defref") then
						defrefs[#defrefs + 1] = common.ExtractFullText(child)
					elseif(child.name == "param") then
						params[#params + 1] = common.ExtractFullText(child)
					else
						--Next is the c-expression.
						break
					end
				end
				
				local stmt = "#define " .. node.attr.name
				if(#params > 0) then
					stmt = stmt .. "(" .. table.concat(params, ", ") .. ")"
				end
				
				stmt = stmt .. " "
				
				--Split c-expression up into lines.
				local c_expr = common.FindChildElement(node, "c-expression")
				c_expr = common.ExtractFullText(c_expr)
				local lines = {}
				for str in c_expr:gmatch("([^\n]+)") do
					lines[#lines + 1] = str
				end

				--Comment the lines out.
				if(node.attr.disable == "true") then
					for _, line in ipairs(lines) do
						lines[_] = "//" .. line
					end
				end
				
				--TODO: Make defrefs work.
				writer:AddText(stmt, table.concat(lines, "\n"))
			end
		}
	},
	{	test = "handle",
		element =
		{	name = "type",
			verbatim = true,
			
			attribs =
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
		}
	},
	{	test = "enumeration",
		element =
		{	name = "type",
			
			attribs =
			{
				name = "name",
				notation = "comment",
			},
			
			proc = function(writer, node)
				writer:AddAttribute("category", "enum")
			end
		}
	},
	{	test = "struct",
		element =
		{	name = "type",
			
			attribs =
			{
				name = "name",
				notation = "comment",
				["is-return"] = "returnedonly",
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
			
			attribs =
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
}

local da =
{	test = "typedef",
		
	element =
	{	name = "type",
		verbatim = true,
		
		attribs =
		{
			notation = "comment",
		},
		
		proc = function(writer, node)
			writer:AddAttribute("category", "include")
		end
	}
}


return {
	test = "definitions",
	
	element = { name = "types", },
	
	children = children
}
