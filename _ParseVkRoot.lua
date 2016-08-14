--Includes all of the parsers for the root elements of vk.xml
--They are named exactly as the XML elements they parse.
--Each entry has a "GenProcTable" function that takes a function to be called
--for each element processed within that element.

--Nothing for `comment`. Has no subelements, so it will be handled elsewhere.
local tbl =
{
	vendorids =		require "_ParseVkVendorIds",
	tags =			require "_ParseVkTags",
	types = 		require "_ParseVkTypes",
}

return tbl