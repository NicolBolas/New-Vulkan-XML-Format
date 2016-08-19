
local write_utils = require "_NewFormatUtils"

local tag_only =
{
	include =		{"name", "style", "need-ext", "notation"},
	typedef =		{"name", "basetype", "notation", },
	reference =		{"name", "include", "notation", },
	bitmask =		{"name", "basetype", "enumref", "notation", },
	handle =		{"name", "type", "parent", "notation", },
	enumeration =	{"name", "notation", },
}

local writers = {}

for kind, attribs in pairs(tag_only) do
	writers[kind] = write_utils.AttributeWriter(kind, attribs)
end

local func_writers = {}
local func_attribs = {}

func_attribs.define = {"name", "disabled", "notation"}
function func_writers.define(writer, data)
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


func_attribs.funcptr = {"name", "notation"}
function func_writers.funcptr(writer, data)
	writer:PushElement("return-type")
	do
		write_utils.WriteVarDef(writer, data.return_type)
	end
	writer:PopElement()
	
	if(data.params) then
		for _, param in ipairs(data.params) do
			writer:PushElement("param")
			write_utils.WriteNamedVariable(writer, param)
			writer:PopElement()
		end
	end
end

func_attribs.struct = {"name", "is-return", "notation"}
function func_writers.struct(writer, data)
	for _, member in ipairs(data.members) do
		writer:PushElement("member")
		write_utils.WriteNamedVariable(writer, member)
		write_utils.WriteCondAttrib(writer, member, "extension-structs")
		write_utils.WriteCondAttrib(writer, member, "type-enums")
		writer:PopElement()
	end
	
	if(data.usages) then
		writer:PushElement("validity")
		for _, usage in ipairs(data.usages) do
			writer:PushElement("usage")
			writer:AddText(usage)
			writer:PopElement()
		end
		writer:PopElement()
	end
end

func_attribs.union = {"name", "notation"}
function func_writers.union(writer, data)
	for _, member in ipairs(data.members) do
		writer:PushElement("member")
		write_utils.WriteNamedVariable(writer, member)
		writer:PopElement()
	end
end

for name, func in pairs(func_writers) do
	writers[name] = write_utils.NamedElementWriter(name, func, func_attribs[name])
end



return writers
