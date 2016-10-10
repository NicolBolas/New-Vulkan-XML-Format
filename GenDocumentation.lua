require "_Utils"
local XmlWriter = require_local_path("LuaTools/", "XmlWriter")
local slaxmldom = require_local_path("SLAXML/", "slaxdom")


--Generates a function that will process nodes, using
--the table's element processor functions.
local function GenNodeProcessor(NodeTable, recurse)
	local function ProcessNode(node, data)
		if(not data) then
			data = {}
		end
		
		
		if(NodeTable[node.name]) then
			local doChildren = NodeTable[node.name](node, data)

			if(recurse or doChildren) then
				for _, elem in ipairs(node.el) do
					ProcessNode(elem, data)
				end
			end
		end

		if(recurse and not NodeTable[node.name]) then
			for _, elem in ipairs(node.el) do
				ProcessNode(elem, data)
			end
		end

		return data
	end

	return ProcessNode
end


local input = (function()
	local hFile = assert(io.open("new_registry.rng"))
	local str = hFile:read("*a")
	hFile:close()

	return slaxmldom:dom(str)
end)()

local globalRefTable = {}

local GatherReferences = (function()
	local RefProcs = {
		ref = function(node, data)
			local refName = node.attr.name
			local count = globalRefTable[refName] or 0
			globalRefTable[refName] = count + 1
			
			if(not data.found[refName]) then
				data[#data + 1] = refName
				data.found[refName] = true
			end
		end,
	}
	
	local Gatherer = GenNodeProcessor(RefProcs, true)
	return function(node)
		return Gatherer(node, {found = {}})
	end
end)()

local GatherDefines = (function()
	local DefineProcs = {}

	function DefineProcs.grammar() return true end
	function DefineProcs.div() return true end

	local function MakeDef(name, kind, node)
		return {
			name = name,
			kind = kind,
			node = node,
			refs = GatherReferences(node),
			numReferred = 0,
		}
	end
	
	function DefineProcs.start(node, data)
		data.defines[""] = MakeDef("", "start", node)
	end

	function DefineProcs.define(node, data)
		local pattName = node.attr.name
		local pattType = pattName:match("%.([^.]+)$")
		if(pattType) then
			data.defines[pattName] = MakeDef(pattName, pattType, node)
		else
			print("Not found:", pattName)
		end
	end

	return GenNodeProcessor(DefineProcs)
end)()

local data = GatherDefines(input.root, { defines = {} })


--[[
----------------------------------------------------------
-- General algorithm for generating documentation.

Doc generation is done by generating documentation for a particular pattern.
Generally speaking, you recursively iterate through the pattern's definition.
You do different things based on what kind of node it is.

A documented node is a `.elem` node or a `.model` node which is referenced more than once.

The result of this process, for a documented element, is a documentation table. That table is an array of entries. Each entry is one of the following:

* A string, to be copied verbatim. Each separate string is conceptually a paragraph.

* A table with a `block` key. The `block`'s value is a (usually short) paragraph string. The string may be an empty string, in which case nothing for the block is displayed. The table is also a documentation table, so it has array elements formatted as described here. This table may also have a `format` key, which specifies how to format each entry:

	* "sequence" (default): Each entry appears one after the other, as paragraphs.

	* "list": Each entry should appear as its own bullet list. If this occurs within an existing list, then the list should be nested within that list.
	
	* "concat": Sequential string elements should be concatenated into a single string.

We determine the order in which we process documented nodes as follows. Start with the `start` node. If the node has a `ref` to a documented node, add it to the end of the current list of nodes. If the node has a `ref` to a non-documented node, process it. However, any documented nodes in that non-documented `ref` are added to a different list of nodes, one which will be processed *before* any of the others. So the most recent level of recursion determines the next group to be processed.

RelaxNG node types of interest are:

* Non-terminals: things that have children. A non-terminal designated "ephemeral" means that if it only has one child, it shouldn't contribute to documentation.

	* group: (ephemeral) Patterns that appear in an ordered sequence. The direct child of a pattern definition is implicitly a `group`, as is the explicit `<group>` element.
	
		Processed as a `block` with a `format` of "list".
	
	* interleave/mixed: (ephemeral, `interleave` only) Patterns that appear in an arbitrary order. `mixed` also adds text.
	
		Processed as a `block` with a `format` of "list".

	* oneOrMore:
	
		Processed as a `block` with a `format` of "list".

	* zeroOrMore:
	
		Processed as a `block` with a `format` of "list".

	* optional:
	
		Processed as a `block` with a `format` of "sequence".
	
	* choice: Can be a choice between pattern-type elements or a choice of values.
	
		Processed as a `block` with a `format` of "list".

	* ref: A reference to a pattern. If the pattern being referenced is not a documented node, then we continue building our documentation by processing that definition element.

		References can be documented at the point where the reference happens. If it is a reference to a non-documented node, then the documentation for the reference is directly incorporated here.
		
		If it is a reference to a documented node, then any documentation on this reference should be added. If there is no documentation on the reference, then we should generate some generic text based on the pattern's name (element X) and use the base documentation at the destination of that reference. It should also contain a link to its documentation.
		
	* attribute: Defines an attribute. Child nodes exist but should be documented specially. They are the contents of the attribute. Note that attribute nodes with no children except documentation contain just text.
	
		Processed as a nameless `block` with a `format` of sequence. The attribute's name should be introduced somewhere.
	
	* element: defines an element. The local documentation of an element takes primacy over the global one.
	
	* data: Has a type and parameters or values or even other pattern elements.
	
* Terminals: those without children.

	* text: Treat as empty; let the documentation explain it.
	* value:
	* empty:

Certain kinds of definition nodes require special handling:

* data: Don't bother to recurse into theses. Just extract their documentation.

* attrib: `a:default-value`s should be mentioned in the documentation.

]]



--Returns true if the definition is an element or is a
--model that is multiply referenced.
local function ShouldDocument(def)
	if(def.kind == "element") then
		return true
	elseif(def.kind == "model" and globalRefTable[def.name] > 1) then
		return true
	end
	
	return false
end

local PrintData = (function()
	local PrintProcs = {}
	
	function PrintProcs.ref(node, data)
	end
	
	return GenNodeProcessor(PrintProcs, true)
end)()

