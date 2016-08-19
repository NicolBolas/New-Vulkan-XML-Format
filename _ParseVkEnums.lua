local parse_dom = require "_ParseVkDom"

--Handles all of the enum types.

local funcs = {}

local function ParseValue(data, value)
	assert(value)
	if(value:match("^[+-]?%d+$")) then
		data.number = value
	else
		local hex = value:match("^0x(%d+)$")
		if(hex) then
			data.hex = hex
		else
			data["c-expression"] = value
		end
	end
end

--Returns the name of the attribute and the data.
local function ExtractEnumNameData(node)
	if(node.attr.value) then
		local value = node.attr.value
		if(value:match("^[+-]?%d+$")) then
			return "number", value
		else
			local hex = value:match("^0x(%d+)$")
			if(hex) then
				return "hex", hex
			else
				return "c-expression", value
			end
		end
	end
	
	if(node.attr.bitpos) then
		return "bitpos", node.attr.bitpos
	end
	
	assert(false, node.attr.name)
end

local function ParseConstants(node)
	local constants = { kind = "constants" }

	local procs = {}
	
	function procs.enum(node)
		local constant = { kind = "constant" }
		constants[#constants + 1] = constant
		
		constant.name = node.attr.name
		local name, value = ExtractEnumNameData(node)
		constant[name] = value
	end
	
	procs[1] =
	{
		Test = function(node) return node.type == "comment" end,
		Proc = function(node)
			local prev = constants[#constants]
			if(prev) then
				prev.notation = node.value
			end
		end
	}
	
	parse_dom.ProcNodes(procs, node.kids)
	
	return constants
end

local function ParseRange(data, node)
	--Legitimate to have a start with no end, but not just an end.
	if(node.attr.start) then
		data["range-start"] = node.attr.start
		data["range-end"] = node.attr["end"]
	end
end

local enumerator_elems = {}

function enumerator_elems.enum(node)
	local data = { kind = "enum" }
	
	data.name = node.attr.name
	data.notation = node.attr.comment
	local name, value = ExtractEnumNameData(node)
	data[name] = value
	
	return data
end

function enumerator_elems.unused(node)
	local data = { kind = "unused-range" }
	
	data["range-start"] = node.attr.start
	data["range-end"] = node.attr["end"]
	
	return data
end

local function ParseEnum(node)
	local data = { kind = "enumeration" }	
	data.name = node.attr.name
	data.notation = node.attr.comment
	ParseRange(data, node)
	
	if(node.attr.type == "bitmask") then
		data.purpose = "bitmask"
	end
	
	data.enumerators = {}
	data.unused = {}
	
	local proc_tbl = parse_dom.GenProcTable(nil, nil, enumerator_elems, function(new)
		if(new.kind == "enum") then table.insert(data.enumerators, new) end
		if(new.kind == "unused-range") then table.insert(data.unused, new) end
	end)
	
	parse_dom.ProcNodes(proc_tbl, node.kids)
	
	return data
end

--Returns a value with `kind` equal to:
--	"constants": An array of `constant` values. To be combined with
--		any existing `constant`s.
--	"enumeration": A single `enumeration` value, to be stored in the `enums` list.
--	"bitmask": A single `bitmask` value, to be stored in the `enums` list.
function funcs.ProcessSingleEnum(node)
	if(not node.attr.type) then
		return ParseConstants(node)
	end

	return ParseEnum(node)
end

return funcs
