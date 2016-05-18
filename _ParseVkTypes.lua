
local parse_dom = require "_ParseVkDom"


local funcs = {}

function funcs.Include(node, output)
	local data = {}
	
	--Parse the include name. May be an attribute `name` or a `name` child element.
	if(node.attr.name) then
		data.name = node.attr.name
	else
		local elem = parse_dom.FindChildElement(node, "name")
		if(elem and elem.name == "name") then
			local text = parse_dom.FindNextText(elem)
			if(text) then
				data.name = text.value
			end
		end
	end
	
	assert(data.name)
	
	--Determine if the `name` ends in a `.h`.
	if(data.name:match("%.h$")) then
		data.need_ext = false
	else
		data.need_ext = true
	end
	
	--Determine if the #include statement in the text block uses `"` or `<`.
	local include_stmt = parse_dom.FindNextText(node).value
	local inc_char = include_stmt:match("%#include%s+([\"<])")
	
	assert(inc_char)
	
	if(inc_char == '<') then
		data.style = "bracket"
	else
		data.style = "quote"
	end
	
	print(data.name, data.need_ext, data.style)
	
	if(output) then
		output[#output + 1] = data
	end
end

return funcs
