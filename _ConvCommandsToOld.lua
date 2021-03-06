
local common = require "_ConvCommon"
local types = require "_ConvCommonTypes"
local convert = require "_ConvCommonConvert"

local cmd_children =
{
	{
		test = "param",
		
		element =
		{
			name = "param",
			verbatim = true,
			
			proc = types.OldWriteVariable,
		},
	},
	convert.cmdStructValidityToOld,
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
	
	if(ret_type.attr.successcodes and #ret_type.attr.successcodes > 0) then
		writer:AddAttribute("successcodes", ret_type.attr.successcodes)
	end
	if(ret_type.attr.errorcodes and #ret_type.attr.errorcodes > 0) then
		writer:AddAttribute("errorcodes", ret_type.attr.errorcodes)
	end
	
	writer:PushElement("proto", nil, true)

	types.OldWritePrenameType(writer, ret_type, true)

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
			
			map_attribs =
			{
				queues = true,
				renderpass = true,
				cmdbufferlevel = true,
				pipeline = true,
				notation = "comment",
			},
			
			
			proc = WriteCommand,
		},

		children = cmd_children,
	},
}

return {
	test = "commands",
	
	element =
	{	name = "commands",
		map_attribs =
		{	notation = "comment",
		},

	},
	
	children = children
}