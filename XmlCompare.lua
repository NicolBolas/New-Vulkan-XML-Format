
require "_Utils"
local slaxmldom = require_local_path("SLAXML/", "slaxdom")
local diff = require_local_path("lua-diff/lua/", "diff")

local function LoadXml(filename)
	local hFile = assert(io.open(filename))
	local str = hFile:read("*a")
	hFile:close()
	
	return slaxmldom:dom(str)
end

local function IgnoreNode(node)
	if(node.type == "element") then
		return false
	end
	if(node.type == "text") then
		if(node.value:match("^%s+$")) then
			return true
		else
			return false
		end
	end
	
	--Ignore comments, PIs, etc.
	return true
end

local function FindNextValidChild(node, index)
	index = index or 0
	for ix = index + 1, #node.kids do
		local kid = node.kids[ix]
		if(not IgnoreNode(kid)) then
			return kid, ix
		end
	end
	
	return nil, nil
end

local elementStack = {}

local function PushStack(node)
	elementStack[#elementStack + 1] = node
end

local function BuildPath()
	local data = {""}
	for n_ix, node in ipairs(elementStack) do
		local parent = node.parent
		if(parent.type == "document") then
			data[n_ix + 1] = string.format("%s[%i]", node.name, 1)
		else
			for ix, test in ipairs(parent.el) do
				if(test == node) then
					data[n_ix + 1] = string.format("%s[%i]", node.name, ix)
				end
			end
		end
	end


	return table.concat(data, "/")
end

local errors = {}

local function ErrorOut(str, lhs, rhs)
	errors[#errors + 1] = {
		msg = str,
		lhs = lhs,
		rhs = rhs,
		context = BuildPath()
	}
end

local NodeComps

NodeComps =
{
	text = function(lhs_node, rhs_node)
		if(lhs_node.value ~= rhs_node.value) then
			--Perform a stronger diff.
			local d_val = diff.diff(lhs_node.value, rhs_node.value)
			for _, test in ipairs(d_val) do
				if(test[2] ~= "same" and not test[1]:match("^%s+$")) then
					ErrorOut("Text nodes don't match.", lhs_node.value, rhs_node.value)
					break
				end
			end
		end
	end,
	element = function(lhs_node, rhs_node)
		if(lhs_node.name ~= rhs_node.name) then
			ErrorOut("Element names don't match.", lhs_node.name, rhs_node.name)
			return
		end
		
		PushStack(lhs_node)
		
		--Check attributes.
		do
			local tested = {}
			for _, attrib in ipairs(lhs_node.attr) do
				if(not rhs_node.attr[attrib.name]) then
					ErrorOut("LHS element has an attribute not found in RHS.",
						attrib.name)
				elseif(rhs_node.attr[attrib.name] ~= attrib.value) then
					ErrorOut("The attribute '" .. attrib.name .. "' has different values.",
						'"' .. attrib.value .. '"', '"' .. rhs_node.attr[attrib.name] .. '"')
				end
				
				tested[attrib.name] = true
			end
			for _, attrib in ipairs(rhs_node.attr) do
				if(not tested[attrib.name]) then
					ErrorOut("RHS element has an attribute not found in LHS.",
						nil, attrib.name)
				end
			end
		end
		
		--Match children.
		local lchild, lindex = FindNextValidChild(lhs_node)
		local rchild, rindex = FindNextValidChild(rhs_node)
		while(lchild and rchild) do
			if(lchild == nil) then
				ErrorOut("Exhausted lhs children.")
				break
			elseif(rchild == nil) then
				ErrorOut("Exhausted rhs children.")
				break
			elseif(lchild.type ~= rchild.type) then
				ErrorOut("Mismatched XML node types.", lchild.type, rchild.type)
			else
				if(NodeComps[lchild.type]) then
					NodeComps[lchild.type](lchild, rchild)
				end
			end
			
			lchild, lindex = FindNextValidChild(lhs_node, lindex)
			rchild, rindex = FindNextValidChild(rhs_node, rindex)
		end
		
		elementStack[#elementStack] = nil
	end,
}



local lhs_filename, rhs_filename = ...

lhs_filename = lhs_filename or "vk_new.xml"
rhs_filename = rhs_filename or "vk_new2.xml"

local lhs, rhs = LoadXml(lhs_filename), LoadXml(rhs_filename)

NodeComps.element(lhs.root, rhs.root)

for _, err in ipairs(errors) do
	print(err.context)
	print("\t" .. err.msg)
	if(err.lhs) then
		print("\tLHS: " .. err.lhs)
	end
	if(err.rhs) then
		print("\tRHS: " .. err.rhs)
	end
end
