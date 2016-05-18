
package.path = package.path .. ";./SLAXML/?.lua"
local slaxmldom = require "slaxdom"


local dom = (function()
	local hFile = io.open("src/vk.xml")
	assert(hFile, "???")
	local str = hFile:read("*a")
	hFile:close()
	
	return slaxmldom:dom(str)
end)()


local funcs = {}

function funcs.DOM() return dom end

--ProcTbl is a table of procedures.
--The non-array elements are of the form `[ElemName] = Proc`.
--If the node is an element, and its name matches `ElemName`
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
		local proc = ProcTbl[node.name]
		if((node.type == "element") and proc) then
			proc(node, ...)
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


return funcs
