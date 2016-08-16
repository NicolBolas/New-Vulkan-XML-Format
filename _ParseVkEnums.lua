local parse_dom = require "_ParseVkDom"

--Handles all of the enum types.

local funcs = {}

local function ParseValue(data, value)
	assert(value)
	if(value:match("^[+-]?%d+$")) then
		data.number = value
	else
		data["c-expression"] = value
	end
end

local function ParseConstants(node)
	local constants = { kind = "constants" }

	local procs = {}
	
	function procs.enum(node)
		local constant = { kind = "constant" }
		constants[#constants + 1] = constant
		
		constant.name = node.attr.name
		ParseValue(constant, node.attr.value)
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
	ParseValue(data, node.attr.value)
	
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
	
	data.enumerators = {}
	data.unused = {}
	
	local proc_tbl = parse_dom.GenProcTable(nil, nil, enumerator_elems, function(new)
		if(new.kind == "enum") then table.insert(data.enumerators, new) end
		if(new.kind == "unused-range") then table.insert(data.unused, new) end
	end)
	
	parse_dom.ProcNodes(proc_tbl, node.kids)
	
	return data
end

local bitmask_elems = {}
function bitmask_elems.enum(node)
	local data = { kind = "bit" }
	
	data.name = node.attr.name
	data.notation = node.attr.comment
	
	if(node.attr.bitpos) then
		data.pos = node.attr.bitpos
	else
		local match = node.attr.value:match("0x(%d+)")
		if(match) then
			data["mask-hex"] = match
		else
			--Convert to hex.
			local value = assert(tonumber(node.attr.value))
			data["mask-hex"] = string.format("%x", value)
		end
	end
	
	return data
end



local function ParseBitmask(node)
	local data = { kind = "bitmask" }

	data.name = node.attr.name
	data.notation = node.attr.comment
	
	data.bits = {}

	local proc_tbl = parse_dom.GenProcTable(nil, nil, bitmask_elems, function(new)
		data.bits[#data.bits + 1] = new
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
	if(node.attr.type == "enum") then
		return ParseEnum(node)
	end
	assert(node.attr.type == "bitmask", node.attr.name)
	return ParseBitmask(node)
end

return funcs
