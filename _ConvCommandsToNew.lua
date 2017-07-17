require "_Utils"
local common = require "_ConvCommon"
local types = require "_ConvCommonTypes"
local convert = require "_ConvCommonConvert"


local command_param =
{	test = "param",
	element =
	{	name = "param",
	
		proc = function(writer, node)
			local param = types.ParseMemberParam(node)
			
			common.WriteTblAsAttribs(writer, param)
		end
	},
}

local external_sync =
{	test = "implicitexternsyncparams",
	element =
	{	name = "external-sync"
	},
	
	children =
	{
		{	test = "param",
			element =
			{	name = "sync",
				proc = function(writer, node)
					writer:AddText(common.ExtractFullText(node))
				end
			},
		},
	},
}

local command =
{	test = "command",
	element =
	{	name = "command",
		map_attribs =
		{
			comment = "notation",
			renderpass = true,
			cmdbufferlevel = true,
			pipeline = true,
			queues = true
		},
		
		attribs =
		{
			name = function(node)
				local proto = assert(common.FindChildElement(node, "proto"))
				local ret = common.ExtractTextFromChild(proto, "name")
				return ret
			end,
		},
		
		proc = function(writer, node)
			return_string = assert(common.ExtractTextFromChild(node, "proto"))
			local return_type = types.ParseTextType(return_string, false)
			return_type.name = nil
			
			if(node.attr.successcodes) then
				return_type.successcodes = node.attr.successcodes
				return_type.errorcodes = node.attr.errorcodes or ""
			end

			writer:PushElement("return-type")
			common.WriteTblAsAttribs(writer, return_type)
			writer:PopElement()
		end,
	},
	
	children =
	{
		command_param,
		convert.toNewValidity,
		external_sync,
	},
}

return {	test = "commands",
	element =
	{	name = "commands",
		map_attribs =
		{	comment = "notation",
		},
	},
	
	children =
	{
		command,
	},
}
