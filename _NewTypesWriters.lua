
local write_utils = require "_NewFormatUtils"

local tag_only =
{
	include =		{"name", "style", "need-ext", "notation"},
	typedef =		{"name", "base-type", "notation", },
	reference =		{"name", "include", "notation", },
	bitmask =		{"name", "base-type", "notation", },
	handle =		{"name", "type", "parent", "notation", },
	enumeration =	{"name", "notation", },
}

local writers = {}

for kind, attribs in pairs(tag_only) do
	writers[kind] = write_utils.AttributeWriter(kind, attribs)
end

local function define(writer, data)
	--If data has no references or parameters, and it stores
	--its data in a `value` member, then it's simple.
	local complex_model = false
	if(not data.defrefs and not data.params and data.value) then
		--Just has a `value` attribute, and possibly a comment.
		writer:AddAttribute("value", tostring(data.value))
	else
		complex_model = true
		if(data.replace) then
			writer:AddAttribute("replace", "true")
		end
	end
	
	if(data.comment) then
		writer:PushElement("comment")
		writer:AddText(data.comment)
		writer:PopElement()
	end
	
	if(data.defrefs) then
		for _, defref in ipairs(data.defrefs) do
			writer:PushElement("defref")
			writer:AddText(defref)
			writer:PopElement()
		end
	end
	
	if(data.params) then
		for _, param in ipairs(data.params) do
			writer:PushElement("param")
			writer:AddText(param)
			writer:PopElement()
		end
	end
	
	if(data.c_expression) then
		writer:PushElement("c-expression")
		writer:AddText(data.c_expression)
		writer:PopElement()
	end
end

writers.define = write_utils.NamedElementWriter("define", define, {"name", "disabled", "notation"})

function writers.struct(writer, data)
end
function writers.union(writer, data)
end
function writers.funcptr(writer, data)
end


return writers
