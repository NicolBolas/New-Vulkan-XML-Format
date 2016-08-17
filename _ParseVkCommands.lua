
local parse_dom = require "_ParseVkDom"
local common = require "_ParseVkCommon"


local Elems = {}

function Elems.command(node)
	local data = { kind = "command" }
	
	data.successcodes = node.attr.successcodes
	data.errorcodes = node.attr.errorcodes
	data.renderpass = node.attr.renderpass
	data.cmdbufferlevel = node.attr.cmdbufferlevel
	data.queues = node.attr.queues
	
	--Extract the return type and name from `proto` node.
	local return_string = {}
	local proto = assert(parse_dom.FindChildElement(node, "proto"))
	for _, node in ipairs(proto.kids) do
		if(node.type == "text") then return_string[#return_string + 1] = node.value end
		if(node.type == "element") then
			if(node.name == "name") then
				data.name = parse_dom.ExtractFullText(node)
				break
			end
			return_string[#return_string + 1] = parse_dom.ExtractFullText(node)
		end
	end
	
	return_string = table.concat(return_string)
	data.return_type = common.ParseReturnType(return_string)
	
	--Extract parameters
	local params = nil
	for _, param_node in ipairs(node.el) do
		if(param_node.name == "param") then
			params = params or {}
			params[#params + 1] = common.ParseMemberParam(param_node)
		end
	end
	data.params = params
	
	--Extract validity and misc. data.
	local validity_node = parse_dom.FindChildElement(node, "validity")
	if(validity_node) then
		data.usages = common.ParseValidity(validity_node)
	end
	
	local external_sync_node = parse_dom.FindChildElement(node, "implicitexternsyncparams")
	if(external_sync_node) then
		local external_sync = nil
		for _, param_node in ipairs(external_sync_node.el) do
			if(param_node.name == "param") then
				external_sync = external_sync or {}
				external_sync[#external_sync + 1] = parse_dom.ExtractFullText(param_node)
			end
		end
		
		data.external_sync = external_sync
	end
	
	--HACK: Fix for oddity.
	if(data.successcodes and not data.errorcodes) then
		data.errorcodes = ""
	elseif(not data.successcodes and data.errorcodes) then
		data.successcodes = ""
	end
	
	return data
end

local funcs = {}

function funcs.GenProcTable(StoreFunc)
	return parse_dom.GenProcTable(nil, nil, Elems, StoreFunc)
end

return funcs
