

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

funcs.WriteAttribs = WriteAttribs

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

local function WriteCondAttrib(writer, data, attrib, override)
	if(data[attrib] ~= nil) then
		if(override) then
			writer:AddAttribute(attrib, override)
		else
			writer:AddAttribute(attrib, tostring(data[attrib]))
		end
	end
end

funcs.WriteCondAttrib = WriteCondAttrib

--Writes reg.variable.definition.model stuff.
--That is, the typing information.
function funcs.WriteVarDef(writer, data)
	writer:AddAttribute("basetype", data.basetype)
	WriteCondAttrib(writer, data, "const", "true")
	WriteCondAttrib(writer, data, "reference")
	WriteCondAttrib(writer, data, "struct")

	if(data.array) then
		writer:AddAttribute("array", data.array)
		if(data.array == "static") then
			writer:AddAttribute("size", data.size)
		else
			--dynamic
			WriteCondAttrib(writer, data, "size")
			WriteCondAttrib(writer, data, "null-terminate")
		end
	end
end

--Writes reg.variable.meta-data.model stuff.
--Whether the variable is considered optional, auto-validity, inout parameters, etc.
function funcs.WriteVarMetadata(writer, data)
	WriteCondAttrib(writer, data, "optional")
	WriteCondAttrib(writer, data, "auto-validity")
	WriteCondAttrib(writer, data, "inout")
	WriteCondAttrib(writer, data, "sync")
end

function funcs.WriteNamedVariable(writer, data)
	if(data.name) then
		writer:AddAttribute("name", data.name)
	end
	if(data.notation) then
		writer:AddAttribute("notation", data.notation)
	end
	
	funcs.WriteVarDef(writer, data)
	funcs.WriteVarMetadata(writer, data)
end




return funcs
