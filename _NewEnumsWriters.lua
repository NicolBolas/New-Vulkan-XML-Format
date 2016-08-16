
local write_utils = require "_NewFormatUtils"

local func_writers = {}
local func_attribs = {}

local enum_writer = write_utils.AttributeWriter("enum", {"name", "number", "c-expression", "notation"})
local unusued_writer = write_utils.AttributeWriter("unused-range", {"range-start", "range-end"})

func_attribs.enumeration = {"name", "range-start", "range-end", "notation", }
function func_writers.enumeration(writer, data)
	for _, enum in ipairs(data.enumerators) do
		enum_writer(writer, enum)
	end
	for _, unused in ipairs(data.unused) do
		unusued_writer(writer, unused)
	end
end

local bit_writer = write_utils.AttributeWriter("bit",
	{"name", "pos", "mask-hex", "notation"})

func_attribs.bitmask = {"name", "notation",}
function func_writers.bitmask(writer, data)
	for _, bit in ipairs(data.bits) do
		bit_writer(writer, bit)
	end
end

local writers =
{
}

for name, func in pairs(func_writers) do
	writers[name] = write_utils.NamedElementWriter(name, func, func_attribs[name])
end

return writers
