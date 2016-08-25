
local common = require "_ConvCommon"

local function WriteParam(writer, node)
	common.OldWriteVariable(writer, node)
end

local cmd_children =
{
	{
		test = "param",
		
		element =
		{
			name = "param",
			verbatim = true,
			
			proc = WriteParam,
		},
	},
	{
		test = "validity",
		
		element =
		{
			name = "validity",
		},
		
		children =
		{
			{
				test = "usage",
				
				element =
				{
					name = "usage",
					
					proc = function(writer, node)
						writer:AddText(common.ExtractFullText(node))
					end
				},
			},
		}
	},
	{
		test = "external-sync",
		
		element =
		{
			name = "implicitexternsyncparams",
		},
		
		children =
		{
			{
				test = "sync",
				
				element =
				{
					name = "param",
					
					proc = function(writer, node)
						writer:AddText(common.ExtractFullText(node))
					end
				},
			},
		},
	},
}


local function WriteCommand(writer, node)
	--Get error codes.
	local ret_type = common.FindChildElement(node, "return-type")
	
	if(ret_type.attr.successcodes) then
		writer:AddAttribute("successcodes", ret_type.attr.successcodes)
	end
	if(ret_type.attr.errorcodes) then
		writer:AddAttribute("errorcodes", ret_type.attr.errorcodes)
	end
	
	writer:PushElement("proto", nil, true)

	common.OldWritePrenameType(writer, ret_type, true)

	writer:AddText(" ")

	writer:PushElement("name")
	writer:AddText(node.attr.name)
	writer:PopElement()
	
	writer:PopElement()
end

local children =
{
	{
		test = "command",
		
		element =
		{
			name = "command",
			
			proc = WriteCommand,
		},

		children = cmd_children,
	},
}

return {
	test = "commands",
	
	element = { name = "command", },
	
	children = children
}