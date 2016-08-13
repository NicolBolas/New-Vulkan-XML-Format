--Includes all of the parsers for the root elements of vk.xml
--They are named exactly as the XML elements they parse.
--Each entry has a "GenProcTable" function that takes a function to be called
--for each element processed within that element.

local tbl = {}

--Nothing for `comment`. Has no subelements, so it will be handled elsewhere.
tbl["vendorids"] = require "_ParseVkVendorIds"
tbl["tags"] = require "_ParseVkTags"
tbl["types"] = require "_ParseVkTypes"

return tbl