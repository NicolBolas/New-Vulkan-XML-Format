--Utility functions for writing attributes/elements and otherwise
--manipulating XML.


require "_Utils"

local funcs = {}

function funcs.CopyAttribIfPresent(writer, node, inputAttrib, outputAttrib)
	outputAttrib = outputAttrib or inputAttrib
	if(node.attr[inputAttrib] ~= nil) then
		local value = node.attr[inputAttrib]
		value = tostring(value)
		writer:AddAttribute(outputAttrib, value)
	end
end

--Writes each of the table fields as attributes.
function funcs.WriteTblAsAttribs(writer, tbl)
	for name, value in pairs(tbl) do
		writer:AddAttribute(name, tostring(value))
	end
end



function funcs.WriteTextElement(writer, elementName, ...)
	writer:PushElement(elementName)
	writer:AddText(...)
	writer:PopElement()
end

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
	if(not node) then return nil end
	
	local list = {}
	if(node.type == "text") then
		return node.value
	else
		ExtractText(node, list)
	end
	return table.concat(list)
end

function funcs.ExtractTextFromChild(node, name)
	return funcs.ExtractFullText(funcs.FindChildElement(node, name))
end

return funcs