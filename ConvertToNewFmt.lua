require "_Utils"
local XmlWriter = require_local_path("LuaTools/", "XmlWriter")
local slaxmldom = require_local_path("SLAXML/", "slaxdom")
local trans = require "_TranslateXML"


local registry_proc =
{
	{	test = "registry",
		
		element =
		{
			name = "registry",
		},
		
		children =
		{
			require "_ConvCommentToNew",
			require "_ConvVendorIdsToNew",
			require "_ConvTagsToNew",
			require "_ConvTypesToNew",
			require "_ConvEnumConstantsToNew",
			require "_ConvEnumsToNew",
			require "_ConvCommandsToNew",
			require "_ConvFeatureToNew",
			require "_ConvExtensionsToNew",
		},
	},
}

--Actual Conversion.
local hFile = assert(io.open("src/vk.xml"))
local str = hFile:read("*a")
hFile:close()

local input = slaxmldom:dom(str)

local filename = ... or "vk_new.xml"

local writer = XmlWriter.XmlWriter(filename)
writer:AddProcessingInstruction("oxygen", [[RNGSchema="new_registry.rnc" type="compact"]])
trans.TranslateXML(writer, input.kids, registry_proc)
writer:Close()
