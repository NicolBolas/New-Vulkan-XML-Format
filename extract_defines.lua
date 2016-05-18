local parse = require "_ParseVk"

local elements = {}

function elements:push(name)
	table.insert(self, name)
end

function elements:pop(name)
	assert(#self > 0)
	assert(name == self[#self])
	self[#self] = nil
end

function elements:index(index)
	index = index or -1
	if(index < 0) then
		local retIx = #self + 1 + index
		assert(retIx > 0)
		return self[retIx]
	elseif(index > 0) then
		assert(index <= #self)
		return self[index]
	else
		assert(false)
	end
end

function elements:top() return self:index() end


local categories = {}

local builder = {}

local hasCat = false
local inTypedef = false

function builder.startElement(name, nsURI)
	elements:push(name)
	if((name == "type") and (elements:index(-2) == "types")) then
		assert(inTypedef == false)
		inTypedef = true
		hasCat = false
	end
end

function builder.closeElement(name, nsURI)
	if((name == "type") and (elements:index(-2) == "types")) then
		assert(inTypedef == true)
		inTypedef = false
		if(not hasCat) then
			local count = categories[0] or 0
			categories[0] = count + 1
		end
	end
	elements:pop(name)
end

function builder.attribute(name, value, nsURI)
	if(inTypedef) then
		if(name == "category") then
			local count = categories[value] or 0
			categories[value] = count + 1
			hasCat = true
		end
	end
end

function builder.text(text)
end

function builder.comment(content)
end

function builder.pi(target, content)
end

parse.parse(builder)

for catName, count in pairs(categories) do
	if(catName == 0) then
		print("<<Unknown>>", count)
	else
		print(catName, count)
	end
end


