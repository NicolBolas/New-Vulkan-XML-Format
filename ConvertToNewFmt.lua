
require "_Utils"
local XmlWriter = require_local_path("LuaTools/", "XmlWriter")
local parse_vk = require "_ParseVk"

--Has the writers for the internal data.
local internal_writers =
{
	vendorids =		require "_NewVendorIdsWriters",
	tags =			require "_NewTagsWriters",
	definitions =	require "_NewTypesWriters",
	constants =		require "_NewConstantsWriters",
	enums =			require "_NewEnumsWriters",
}

--Writers for the root elements
local root_kinds = {}

function root_kinds.notation(writer, data)
	writer:PushElement("notation")
	writer:AddText(data.text)
	writer:PopElement()
end

--Generate most of the writers from the `internal_writers` table.
for name, writers in pairs(internal_writers) do
	root_kinds[name] = function(writer, data)
		writer:PushElement(name)
		
		for _, child in ipairs(data) do
			if(child.kind) then
				assert(writers[child.kind], name .. " " .. child.kind)
				writers[child.kind](writer, child)
			else
				--TODO: Write out verbatim XML data.
			end
		end
		
		writer:PopElement()
	end
end

--TODO: Constants and enumerations have to be generated specially, since originally
--they were in the same root node. So in the parsed data, they're in the same collection.

local input = parse_vk.Parse()

local writer = XmlWriter.XmlWriter("test.xml")

-- <?oxygen RNGSchema="new_registry.rnc" type="compact"?>
writer:AddProcessingInstruction("oxygen", [[RNGSchema="new_registry.rnc" type="compact"]])

writer:PushElement("registry")

for _, data in ipairs(input) do
	if(data.kind) then
		assert(root_kinds[data.kind], data.kind)
		root_kinds[data.kind](writer, data)
	end
end

writer:PopElement()

writer:Close()
