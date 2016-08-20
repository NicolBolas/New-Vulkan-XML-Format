
local write_utils = require "_NewFormatUtils"

local reference_attribs = {}
local reference_writers = {}

reference_attribs.defref = {"name", "notation"}
reference_attribs.commandref = {"name", "notation"}
reference_attribs.enumref = {"name", "notation"}

local reference_funcs = {}
for name, attribs in pairs(reference_attribs) do
	if(reference_writers[name]) then
		reference_funcs[name] = write_utils.NamedElementWriter(
			name, reference_writers[name], attribs)
	else
		reference_funcs[name] = write_utils.AttributeWriter(name, attribs)
	end
end


local function WriteReference(writer, data)
	writer:PushElement(data.kind)
	
	write_utils.WriteAttribs(writer, {"profile", "notation"}, data)
	for _, ref in ipairs(data.elements) do
		assert(reference_funcs[ref.kind])
		reference_funcs[ref.kind](writer, ref)
	end
	
	if(data.usages) then
		writer:PushElement("validity")
		for _, usage in ipairs(data.usages) do
			writer:PushElement("usage")
			write_utils.WriteAttribs(writer, {"struct", "command"}, usage)
			writer:AddText(usage.text)
			writer:PopElement()
		end
		writer:PopElement()
	end
	
	writer:PopElement()
end

local func_writers = {}
local func_attribs = {}

func_attribs.feature = {"api", "version", "name", "define", "notation", }
function func_writers.feature(writer, data)
	for _, reference in ipairs(data.references) do
		WriteReference(writer, reference, false)
	end
end

local writers = {}

for name, func in pairs(func_writers) do
	writers[name] = write_utils.NamedElementWriter(name, func, func_attribs[name])
end

return writers
