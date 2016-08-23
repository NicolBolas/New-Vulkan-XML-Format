--[[
A system for translating from one XML format to another.
This is done by building an array that describes how to process the source format.

The processing of an element can automatically:
	Build a new element, with a possibly different name from the original.
	Build new attributes for that new element, with possibly different names.
	Process child elements, based on matches from a table.
	Call a processing function that can do special-case work for the element.
	Skip creating an element and simply process the child elements.

The main function which processes a file takes an array of "processors". Each processor
is a table that is defined as follows:

{
	--An element name string or a general function(node) that returns
	--`true` or `false`, depending on whether it matches.
	--Test matching is always in the order specified in the outer array; the first
	--matching test wins the right to process the element.
	test = "Input Element Name",
	
	--When present, says that all elements that match this `test`
	--will be processed together, with a single begin/end.
	--The order between elements will be preserved.
	defer = 
	{
		--Creates the named element before processing any nodes in the group,
		--which will be the parent of all nodes in the group.
		--May also be a function(writer), which can do arbitrary writing.
		--Optional.
		start = "Element-To-Wrap", 
		
		--If `start` was a function, then `stop` will be called after all processing.
		stop = function(writer) end,
	}
	
	--Provokes the creation of an element.
	element =
	{
		--The name of the element being generated, or function taking the
		--node and returning the element's name
		name = "Element Name",
		
		--Specifies whether formatting should be applied to 
		--the element's children.
		verbatim = true
		
		--Used only for converting a specific input attribute to a single output attribute.
		--Multiple input attributes can map to the same output, but if that happens,
		--they cannot all match simultaneously.
		attribs = 
		{
			--Verbatim copy of value of Input to Output
			["Input Attrib Name"] = "Output Attrib Name",
			--Verbatim copy of value of Input to attribute of Input name
			["Input Attrib Name"] = true,
			--Arbitrary processing of value of Input, but only
			--to write a single output attribute.
			--Return value is the new attribute's name and the output value.
			["Input Attrib Name"] = function(value, node)
				return NewAttributeName, NewAttributeValue
			end
		},
		
		--After writing any attributes, performs arbitrary writing.
		--Do not PopElement more times than you PushElement
		--within this function.
		proc = function(writer, node)
		end,
	},
	
	--Processes child nodes of this one.
	--If there is no `element`, then any elements created here will be children
	--of whatever came before.
	--If `element` exists, then processing children will happen *after*
	--`element.proc` (if any), which happens after `element.attribs` (if any). But
	--it will still happen within the element created by `element`.
	children =
	{
	},
}
]]



local funcs = {}

local TranslateXML

local function Process(writer, node, proc)
	if(proc.element) then
		local element = proc.element
		local name = element.name
		if(type(name) == "function") then
			name = name(node)
		end
		
		assert(name)
		
		local verbatim = element.verbatim
		
		writer:PushElement(name, nil, verbatim)
		
		if(element.attribs) then
			for attrib, map in pairs(element.attribs) do
				local outname, value
				if(type(map) == "string") then
					outname, value = map, node.attr[attrib]
				elseif(map == true) then
					outname, value = attrib, node.attr[attrib]
				else
					outname, value = map(node.attr[attrib], node)
				end
				
				if(type(value) ~= "string") then
					value = tostring(value)
				end
				
				writer:AddAttribute(outname, value)
			end
		end
		
		if(element.proc) then
			element.proc(writer, node)
		end
	end
	
	if(proc.children) then
		TranslateXML(writer, node.kids, proc.children)
	end
	
	if(proc.element) then
		writer:PopElement()
	end
end


local function ShouldProcess(node, proc)
	--Process by match with node name.
	if(type(proc.test) == "string") then
		if(node.type == "element" and node.name == proc.test) then
			return true
		end
	else
		--Function call to test.
		if(proc.test(node)) then
			return true
		end
	end
	
	return false
end

--Call this with `doc.kids`
TranslateXML = function(writer, node_arr, procs)
	--Array of proc for deferments, and
	--also a map from proc to array of nodes to be processed
	local deferments = {}
	
	for _, node in ipairs(node_arr) do
		for _, proc in ipairs(procs) do
			if(ShouldProcess(node, proc)) then
				--Do we need to defer processing?
				if(proc.defer) then
					if(deferments[proc]) then
						table.insert(deferments[proc], node)
					else
						--New deferment. Array of 1
						deferments[proc] = { node }
						deferments[#deferments + 1] = proc
					end
				else
					Process(writer, node, proc)
				end
			end
		end
	end
	
	--Process deferments.
	for _, proc in ipairs(deferments) do
		--Deferment may have special start/stop needs.
		local start_type = type(proc.defer.start)
		if(start_type == "string") then
			writer:PushElement(proc.defer.start)
		elseif(start_type == "function") then
			assert(proc.defer.stop)
			proc.defer.start(writer)
		end
		
		for _, node in ipairs(deferments[proc]) do
			Process(writer, node, proc)
		end
		
		if(start_type == "string") then
			writer:PopElement()
		elseif(start_type == "function") then
			proc.defer.stop(writer)
		end
	end
end

funcs.TranslateXML = TranslateXML

return funcs
