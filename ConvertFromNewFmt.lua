require "_Utils"
local XmlWriter = require_local_path("LuaTools/", "XmlWriter")
local slaxmldom = require_local_path("SLAXML/", "slaxdom")
local trans = require "_TranslateXML"

local hFile = io.open("vk_new.xml")
assert(hFile, "???")
local str = hFile:read("*a")
hFile:close()

local vk_new = slaxmldom:dom(str)

local registry_proc =
{
	test = "registry",
	
	element =
	{
		name = "registry",
	},
	
	children =
	{
		require "_ConvNotationToOld",
		require "_ConvVendorIdsToOld",
		require "_ConvTagsToOld",
		
		require "_ConvConstantsToOld",
		require "_ConvEnumsToOld",
	},
}

local procs =
{
	registry_proc,
}

local writer = XmlWriter.XmlWriter("vk_old.xml")
trans.TranslateXML(writer, vk_new.kids, procs)
writer:Close()




