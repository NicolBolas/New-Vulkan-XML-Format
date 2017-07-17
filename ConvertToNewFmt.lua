require "_Utils"
local XmlWriter = require_local_path("LuaTools/", "XmlWriter")
local slaxmldom = require_local_path("SLAXML/", "slaxdom")
local trans = require "_TranslateXML"


--[[
What needs to be fixed:

* `struct` definitions need an "extends" attribute from `structextends`.
* The following need `notation` attributes, taken from the `comment` attribute of the originals:
	* `vendorids`
	* `tags`
	* `definitions`
	* `commands`
* There can be `comment` nodes in various places; these need to become `notation` elements. The position of these nodes needs to be kept. The places are:
	* interleaved among definition types.
	* within struct `member`s.
	* within enumerations.
	* within `feature` items (but oddly not in `extension`s).

In round-tripping, `comment`s in `member`s need to be placed at the end of the `member`, with no space inbetween it and the text of the member.
]]

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
--local hFile = assert(io.open("src/vk_old.xml"))
local str = hFile:read("*a")
hFile:close()

local input = slaxmldom:dom(str)

local filename = ... or "vk_new.xml"

local writer = XmlWriter.XmlWriter(filename)
writer:AddProcessingInstruction("oxygen", [[RNGSchema="new_registry.rnc" type="compact"]])
trans.TranslateXML(writer, input.kids, registry_proc)
writer:Close()
