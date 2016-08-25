
local funcs = {}

--Returns a child element of `node` named `name`.
function funcs.FindChildElement(node, name)
	for _, elem in ipairs(node.el) do
		if(elem.name == name) then
			return elem
		end
	end
	
	return nil
end

--Returns the first text node in `node` after `start`.
--`start` defaults to 0.
--Also returns the index of the node.
function funcs.FindNextText(node, start)
	start = start or 0
	for i = start + 1, #node.kids do
		local test = node.kids[i]
		if(test.type == "text") then
			return test, i
		end
	end
	
	return nil, nil
end

local function ExtractText(node, list)
	for _, child in ipairs(node.kids) do
		if(child.type == "text") then
			list[#list + 1] = child.value
		elseif(child.type == "element") then
			ExtractText(child, list)
		end
	end
end

function funcs.ExtractFullText(node)
	local list = {}
	if(node.type == "text") then
		return node.value
	else
		ExtractText(node, list)
	end
	return table.concat(list)
end

return funcs