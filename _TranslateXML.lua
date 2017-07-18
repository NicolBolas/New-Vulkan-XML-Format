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
	test = "Input_Element_Name",
	
	--When present, says that all elements that match this `test`
	--will be processed together, with a single begin/end.
	--The order between elements that match will be preserved.
	--By default, all elements that match the `test` will be processed
	--in sequence before processing the next element that *doesn't* match
	--the test.
	collate =
	{
		--If true, then the collation will only collate consecutive runs of that
		--matched element. That is, if you have 3 <name>s followed by a <type>
		--followed by 2 <name>s, if the <name> parser uses `consecutive`,
		--then it will invoke the processor for the 3 consecutive <name>s, then
		--process the <type>, then process the 2 consecutive <name>s.
		--So if you use `start` and `stop` elements, you can wrap runs of
		--such elements.
		consecutive = true,
		
		--Normally, when building a collation, all other processors at this level
		--are checked against each node. This means that if earlier tests
		--match nodes in `test`, then they will be processed by those
		--processors instead of the collation.
		--By setting `consume`, once we find a node that matches
		--`test`, then the only thing that determines whether subsequent
		--nodes go into the collation is whether they match the `consume`
		--critera.
		--The `consume` value may be an element name string or
		--a general function(node) that returns `true` or `false`,
		--depending on whether it matches.
		consume = "Consume_Element_Name",
	
		--If present, then processing elements that match this test will take place
		--after processing all non-deferred elements. The number provided by this
		--property is a priority. Deferred processing will happen
		--in the order of the priorities, from highest to lowest.
		--If you use both `defer` and `consecutive`, an assert will trigger.
		defer = 23,
	
		--Creates the named element before processing any nodes in the collation group,
		--which will be the parent of all nodes in the group.
		--May also be a function(writer), which can do arbitrary writing.
		--Optional.
		start = "Element-To-Wrap", 
		
		--If `start` was a function, then `stop` will be called after all processing.
		stop = function(writer) end,
		
		--Normally, when doing collation, each individual element in the 
		--collation is processed by the `element` and `children` part of
		--the rule.
		--However, if this is set to `true`, then `element` processing is skipped.
		--Instead, it will match the collated nodes against the `children`
		--rules as though the collated nodes were all the child nodes of
		--a single parent.
		--This makes it possible to do collation on a group of multiple
		--kinds of elements, which generate multiple kinds of elements.
		--It will still do `start`/`stop` elements.
		group = true,
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
		
		--Used for mapping a specific input attribute to a single output attribute.
		--Multiple input attributes can map to the same output, but if that happens,
		--they cannot all match simultaneously.
		map_attribs = 
		{
			--Verbatim copy of value of Input to Output
			["Input Attrib Name"] = "Output Attrib Name",
			--Verbatim copy of input to output of the same name.
			["Input Attrib Name"] = true,
			--Arbitrary processing of value of input, but only
			--to write a single output attribute.
			--Return value is the new attribute's name and the output value.
			["Input Attrib Name"] = function(value, node)
				return NewAttributeName, NewAttributeValue
			end
		},
		
		--Used for creating new attributes.
		attribs =
		{
			--Creates a new attribute from a given, unchanging value.
			["Output Attrib Name"] = "attribute value",
			--Creates a new attribute by calling a function.
			--If the function returns `nil`, the attribute will not be written.
			["Output Attrib Name"] = function(node)
			end
		},
		
		--After writing any attributes, performs arbitrary writing.
		--You may write attributes here, but obviously before any elements.
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
		
		assert(name, proc.test)
		
		local verbatim = element.verbatim
		
		writer:PushElement(name, nil, verbatim)
		
		--Don't map attributes for nodes that don't have any.
		if(element.map_attribs and node.attr) then
			for attrib, map in pairs(element.map_attribs) do
				local outname, value
				if(type(map) == "string") then
					outname, value = map, node.attr[attrib]
				elseif(map == true) then
					outname, value = attrib, node.attr[attrib]
				elseif(node.attr[attrib]) then
					--No mapping if input attribute doesn't exist.
					outname, value = map(node.attr[attrib], node)
				end
				
				--Don't write nils
				if(value ~= nil) then
					if(type(value) ~= "string") then
						value = tostring(value)
					end
				
					writer:AddAttribute(outname, value)
				end
			end
		end
		
		if(element.attribs) then
			for attrib, value in pairs(element.attribs) do
				if(type(value) == "function") then
					value = value(node)
				end
				
				if(value ~= nil) then
					if(type(value) ~= "string") then
						value = tostring(value)
					end
				
					writer:AddAttribute(attrib, value)
				end
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


local function ShouldProcess(node, proc, test)
	test = test or proc.test

	--Process by match with node name.
	if(type(test) == "string") then
		if(node.type == "element" and node.name == test) then
			return true
		end
	else
		--Function call to test.
		if(test(node)) then
			return true
		end
	end
	
	return false
end

local function ProcessCollation(writer, proc, node_arr)
	--Deferment may have special start/stop needs.
	local start_type = type(proc.collate.start)
	if(start_type == "string") then
		writer:PushElement(proc.collate.start)
	elseif(start_type == "function") then
		assert(proc.collate.stop)
		proc.collate.start(writer)
	end
	
	if(proc.collate.group == true) then
		print(#node_arr)
		TranslateXML(writer, node_arr, proc.children)
	else
		for _, node in ipairs(node_arr) do
			Process(writer, node, proc)
		end
	end
	
	if(start_type == "string") then
		writer:PopElement()
	elseif(start_type == "function") then
		proc.collate.stop(writer)
	end
end

--Searches through `node_arr`, starting from `start_node_ix` + 1,
--with `start_node_ix` pointing to a matching node..
--For each node, checks `procs`. If all `procs` before `test_ix` test
--negative and procs[test_ix]` tests positive, then the node is added to an array.
--If the node doesn't match any processor, then it is ignored.
--If `consecutive` is true, then will return the array when the first matched node is 
--found which doesn't match with `procs[test_ix]`.
--Otherwise, returns all such elements.
--Returns an array and the number of elements to skip.
local function AccumulateCollation(start_node_ix, node_arr, test_ix, procs, consecutive)

	local collate_proc = procs[test_ix]

	--`start_node_ix` is assumed to point to the first matching node. So keep it.
	local arr = { node_arr[start_node_ix] }
	local num_elements = 1
	for node_ix = start_node_ix + 1, #node_arr do
		local node = node_arr[node_ix]
		local found = false
		
		if(collate_proc.collate.consume) then
			if(ShouldProcess(node, collate_proc, collate_proc.collate.consume)) then
				found = collate_proc
			end
		else
			for proc_ix = 1, #procs do
				local proc = procs[proc_ix]
				if(ShouldProcess(node, proc)) then
					found = collate_proc
					break
				end
			end
		end
		
		--Ignore unprocessed nodes.
		if(found) then
			if(found == collate_proc) then
				--Valid match, add to list
				arr[#arr + 1] = node
			elseif(consecutive) then
				--early exit.
				break
			end
		end
		
		num_elements = num_elements + 1
	end
	
	return arr, num_elements
end

--Call this with `doc.kids`
TranslateXML = function(writer, node_arr, procs)
	--Array of proc for deferments, and
	--also a map from proc to array of nodes to be processed
	local deferments = {}
	
	--If a processor matches and is in this list, then we should skip the node.
	--It has already been processed for collation.
	local skips = {}
	
	local node_ix, node_len = 1, #node_arr
	while(node_ix <= node_len) do
		local node = node_arr[node_ix]
		for proc_ix, proc in ipairs(procs) do
			if(ShouldProcess(node, proc)) then
				--Did we already process it?
				if(not skips[proc]) then
					if(proc.collate) then
						local collate = proc.collate
						assert(not(collate.defer and collate.consecutive))
						if(collate.defer) then
							assert(type(collate.defer) == "number")
							--Store node for later processing.
							if(deferments[proc]) then
								table.insert(deferments[proc], node)
							else
								--New deferment. Array of 1
								deferments[proc] = { node }
								deferments[#deferments + 1] = proc
							end
						elseif(collate.consecutive) then
							local nodes, skip_count = AccumulateCollation(
								node_ix, node_arr, proc_ix, procs, true)
							ProcessCollation(writer, proc, nodes)
							--Skip these nodes.
							node_ix = node_ix + skip_count - 1
						else
							local nodes = AccumulateCollation(
								node_ix, node_arr, proc_ix, procs)
							ProcessCollation(writer, proc, nodes)
							skips[proc] = true
						end
					else
						--Regular processing.
						Process(writer, node, proc)
					end
				end
				
				break --Process it.
			end
		end
		
		node_ix = node_ix + 1
	end
	
	--Process deferments, in order highest-to-lowest
	table.sort(deferments, function(lhs, rhs) return lhs.collate.defer > rhs.collate.defer end)
	for _, proc in ipairs(deferments) do
		ProcessCollation(writer, proc, deferments[proc])
	end
end

funcs.TranslateXML = TranslateXML

return funcs
