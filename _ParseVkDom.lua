
require "_Utils"
local slaxmldom = require_local_path("SLAXML/", "slaxdom")


local dom = (function()
	local hFile = io.open("src/vk.xml")
	assert(hFile, "???")
	local str = hFile:read("*a")
	hFile:close()
	
	return slaxmldom:dom(str)
end)()


local funcs = {}

function funcs.DOM() return dom end


--Generates a table suitable for use in ProcNodes.
--	Tests: Table of functions to test nodes. Can be `nil`, which is
--		equivalent to an empty table.
--	Procs: Table of functions to process a node for which `Tests[key]` returned true.
--		For every key in `Tests`, there must be a key in `Procs`.
--	Elems: Table of processing functions. Instead of having separate tests and procs
--		this works by element name. The key of the table is an element's name.
--		The function is the processor that will be called if an element matches it.
--		Can be `nil`, which is equivalent to an empty table.
--	StoreFunc: A function that will be called after each `Proc`.
--		It will be passed the first return value of `Proc`, followed by the
--		extra values passed to ProcNodes.
function funcs.GenProcTable(Tests, Procs, Elems, StoreFunc)
	local procTable = {}
	if(Tests) then
		for name, test in pairs(Tests) do
			local procEntry = {}
			procTable[#procTable + 1] = procEntry
			procEntry.Test = test
			local Proc = assert(Procs[name])
			
			procEntry.Proc = function(node, ...)
				local data = Proc(node, ...)
				StoreFunc(data, ...)
			end
		end
	end
	if(Elems) then
		for name, Proc in pairs(Elems) do
			procTable[name] = function(node, ...)
				local data = Proc(node, ...)
				StoreFunc(data, ...)
			end
		end
	end
	return procTable
end

--ProcTbl is a table of procedures.
--The non-array elements are of the form `[name] = Proc`.
--If the node is an element, and its name matches `name`
--then `Proc` should be called.
--The array elements are tables that contain `Test` and `Proc` members.
--`Test` is a function that takes a node and tests it. If it 
--returns `true`, then the `Proc` should be called.
--Testing for these is done in order.
--
--When `Proc` is called, it is passed the node that passed the test,
--followed by any extra parameters.
function funcs.ProcNodes(ProcTbl, NodeList, ...)
	for _, node in ipairs(NodeList) do
		--Only elements are matched purely by name.
		if((node.type == "element") and ProcTbl[node.name]) then
			ProcTbl[node.name](node, ...)
		else
			--Array elements in ProcTbl are tables of "Test" and "Proc"
			--functions.
			for _, tester in ipairs(ProcTbl) do
				if(tester.Test(node)) then
					tester.Proc(node, ...)
					break
				end
			end
		end
	end
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

--Takes all text nodes, recursively, and concatenates them together.
--Effectively strips out all markup.
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
