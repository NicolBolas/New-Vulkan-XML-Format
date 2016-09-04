
require "_Utils"
local slaxmldom = require_local_path("SLAXML/", "slaxdom")

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

local function BuildPath()
	return table.concat(elementStack, "/")
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
			ErrorOut("Text nodes don't match.", lhs_node.value, rhs_node.value)
		end
	end,
	element = function(lhs_node, rhs_node)
		if(lhs_node.name ~= rhs_node.name) then
			ErrorOut("Element names don't match.", lhs_node.name, rhs_node.name)
			return
		end
		
		elementStack[#elementStack + 1] = lhs_node.name
		
		--Check attributes.
		do
			local tested = {}
			for _, attrib in ipairs(lhs_node.attr) do
				if(not rhs_node.attr[attrib.name]) then
					ErrorOut("LHS element has an attribute not found in RHS.",
						attrib.name)
				elseif(rhs_node.attr[attrib.name] ~= attrib.value) then
					ErrorOut("The attribute '" .. attrib.name "' has different values.",
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
