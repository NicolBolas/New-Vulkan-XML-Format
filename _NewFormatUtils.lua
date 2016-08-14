

local funcs = {}

local function WriteAttribs(writer, attribList, data)
	for _, attrib in ipairs(attribList) do
		if(data[attrib]) then
			if(type(data[attrib]) ~= "string") then
				writer:AddAttribute(attrib, tostring(data[attrib]))
			else
				writer:AddAttribute(attrib, data[attrib])
			end
		end
	end
end

--Produces a function that is passed the `writer` and `...`.
--The function will create an element named `name`,
--call `Func` with `writer` and `...`,
--and pops the element.
--Takes an optional array of attributes to write.
function funcs.NamedElementWriter(name, Func, attribList)
	return function(writer, ...)
		writer:PushElement(name)
		if(attribList) then
			WriteAttribs(writer, attribList, ...)
		end
		Func(writer, ...)
		writer:PopElement()
	end
end

--Produces a function that writes an element that contains the given attributes
--from the `data` parameter.
--Used for nodes where you only need to write attributes of a specific element.
--`attribList` is an array of attributes to write.
--It is not an error if a name is not found. No attribute will be printed in that case.
function funcs.AttributeWriter(name, attribList)
	return function(writer, data)
		assert(type(data) == "table", name)
		writer:PushElement(name)
		WriteAttribs(writer, attribList, data)
		writer:PopElement()
	end
end



return funcs
