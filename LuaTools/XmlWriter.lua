--[[--
An XML writing system.

@module XmlWriter

To create an @{xml_writer}, use the function @{XmlWriter.XmlWriter}, passing in a filename that you want written to. This function will open the file and automatically create the XML header. The function returns an xml_writer "class", which is why creation looks like a class constructor.

The files are always UTF-8, version 1.0, with the appropriate XML header.
]]

--[=[--
@function escape_string
@local 

Performs string escaping, in accord with the XML standard. Escapes the five characters that cannot appear in XML: `&"'<>`.

@param str The string to be escaped.
@treturn string The escaped string.
@treturn number The number of replacements done.
]=]
local escape_string

do
	local escape_table =
	{
		["&"] = "&amp;",
		['"'] = "&quot;",
		["'"] = "&apos;",
		["<"] = "&lt;",
		[">"] = "&gt;",
	}

	local escape_pattern = (function()
		local chars = {}
		for char, _ in pairs(escape_table) do
			chars[#chars + 1] = "%" .. char
		end
		return "([" .. table.concat(chars) .. "])"
	end)()
	
	escape_string = function(str)
		return string.gsub(str, escape_pattern, escape_table)
	end
end

--[=[--
@type xml_writer

The writer, created by @{XmlWriter.XmlWriter}. Has a C# writer-style interface for creating elements, attributes, and other XML features.

The writer does verify some basic things about the structure of the XML. You cannot add multiple roots.

Strings passed to the API as regular text or attributes will be escaped against the 5 characters that XML does not allow.
]=]

local xml_writer = {};

--[=[--
Copies functions from the `xml_writer` into the table returned to the user.
]=]
local function AddMembers(writer)
	for funcName, func in pairs(xml_writer) do
		writer[funcName] = func;
	end
end

--[=[--
Utility function. An effective member of `xml_writer`. Closes the current element.
]=]
local function CloseElement(self, postChar)
	if(self.needCloseElem) then
		self.hFile:write(">");
		self.needCloseElem = false;
		self.lastWasElement = true;
	end
end

--[=[--
Inserts a new element as a child of the current element.

The `elementName` is a QName. No checking is made to see if the element name has a qualifier at the same time as a default namespace.

Redundant default namespace definitions will not be printed, so feel free to always pass a namespace parameter.

Errors if this function is called after popping the root element. XML files cannot contain multiple roots.

@tparam string elementName The unescaped QName of the element to be inserted.
@tparam[opt] string namespace The new default namespace for this element, if any.
@tparam[opt] boolean noPrettyPrint If `true`, then the element's contents will not have indentation. If not present, then it inherits the behavior of the parent element.
]=]
function xml_writer:PushElement(elementName, namespace, noPrettyPrint)
	CloseElement(self);
	
	if(#self.elemStack == 0) then
		assert(not self.hasRoot, "There can only be one root element in an XML file.");
		self.hasRoot = true;
	end
	
	--Intention and line spacing.
	if(self.lastWasElement or #self.elemStack == 0) then
		local topOfStack = self.formatStack[#self.formatStack];
		if(not topOfStack or (topOfStack.form == false)) then
			self.hFile:write("\n", string.rep("\t", #self.elemStack));
		end
	end

	self.hFile:write("<", elementName);
	self.needCloseElem = true;
	self.elemStack[#self.elemStack + 1] = elementName;
	if(namespace) then
		local topOfStack = self.nsStack[#self.nsStack];
		if(not topOfStack or topOfStack.ns ~= namespace) then
			--Change the current namespace.
			self.hFile:write(" xmlns=\"", namespace, "\"");
			self.nsStack[#self.nsStack + 1] = { ns=namespace, loc=(#self.elemStack) };
		end
	end
	
	if(type(noPrettyPrint) == "boolean") then
		self.formatStack[#self.formatStack + 1] = {form=noPrettyPrint, loc=(#self.elemStack)};
	end
end

--[=[--
Terminates the current element, writing an end tag. If no element contents were added, then it will write a `/>` end to the element rather than an end tag.

This function must be paired with an element that was pushed. Errors if you attempt to pop after popping the root element.
]=]
function xml_writer:PopElement()
	assert(#self.elemStack > 0, "Element stack underflow.");

	if(self.needCloseElem) then
		self.hFile:write("/>");
		self.needCloseElem = false;
	else
		--Intention and line spacing.
		if(self.lastWasElement) then
			local topOfStack = self.formatStack[#self.formatStack];
			if(not topOfStack or (topOfStack.form == false)) then
				self.hFile:write("\n", string.rep("\t", #self.elemStack - 1));
			end
		end

		self.hFile:write("</", self.elemStack[#self.elemStack], ">");
		self.lastWasElement = true;
	end
	self.elemStack[#self.elemStack] = nil;
	
	local topOfStack = self.nsStack[#self.nsStack];
	if(topOfStack) then
		if(#self.elemStack < topOfStack.loc) then
			self.nsStack[#self.nsStack] = nil;
		end
	end

	topOfStack = self.formatStack[#self.formatStack];
	if(topOfStack) then
		if(#self.elemStack < topOfStack.loc) then
			self.formatStack[#self.formatStack] = nil;
		end
	end
end

--[=[--
Does the business end of adding an attribute, such as escaping it.
]=]
local function PutAttrib(self, attribName, data)
	assert(attribName ~= "xmlns", "You cannot manually change the default namespace.");

	data = escape_string(data)
	self.hFile:write(" ", attribName, "=\"", data, "\"");
end

--[=[--
Adds one or more attributes to the current element. It must be called *before* adding any kind of node to the XML file (child elements, text, PIs, comments).

No precautions are taken to prevent the same attribute from being added twice. Nor does this function prevent you from adding `xmlns:X` namespace definition attributes.

However, this function will error if you attempt to add the `xmlns` attribute, which defines the default namespace.

This function must be called within an element.

@param attribName This is either the QName of the attribute to add or a table. If it is a table, then the key/value pairs of the table will be added to the element as attributes. The keys will be the attribute's name, with the corresponding value being its data. Only keys that are strings in the table will be added to the element. Values will be escaped.
@tparam[opt] string data The text value of the attribute. The string will be escaped. Only optional if `attribName` is a table.
]=]
function xml_writer:AddAttribute(attribName, data)
	assert(self.needCloseElem, "The element has been closed. Cannot add attributes");

	if(type(attribName) == "table") then
		for attrib, attribData in pairs(attribName) do
			if(type(attrib) == "string") then
				PutAttrib(self, attrib, attribData)
			end
		end
	else
		PutAttrib(self, attribName, data)
	end
end

--[=[--
Adds namespace prefixes to an element. It inserts an `xmlns:foo=""` attribute into the element, so it has all of the limitations of @{AddAttribute}.

No measures are taken to ensure that the same `prefix` is not used twice in the same element.

This function must be called within an element, before adding any non-attribute child nodes.

@tparam string prefix The NCName for the prefix to insert.
@tparam string namespace The URI namespace to add.
 function takes a prefix (NCName) and a namespace string. Basically, it's a utility version of AddAttribute, except that it doesn't have a table version.
]=]
function xml_writer:AddNamespace(prefix, namespace)
	assert(self.needCloseElem, "The element has been closed. Cannot add namespace " .. namespace);

	PutAttrib(self, "xmlns:" .. prefix, namespace);
end

--[=[--
Adds one or more text nodes to the current element. This function takes any number of parameters. It will escape all of the given strings, then write them one after the other, with no spacing or other characters between.

This function must be called within an element.
]=]
function xml_writer:AddText(...)
	CloseElement(self);
	assert(#self.elemStack > 0, "Text cannot be written at the top of the scope; only within an element.");
	
	--Escape the text.
	local text_count = select("#", ...)
	local text_data = {...}
	for i = 1, text_count do
		text_data[i] = escape_string(tostring(text_data[i]))
	end
	
	self.hFile:write(unpack(text_data, 1, text_count));
	self.lastWasElement = false;
end

--[=[--
Adds one or more text nodes to the current element as a single XML CData node. This function takes any number of parameters. It will escape all of the given strings, then write them one after the other, with no spacing or other characters between. All of the strings will be within the same CData node.

This function must be called within an element.
]=]
function xml_writer:AddCDataText(...)
	CloseElement(self);
	assert(#self.elemStack > 0, "CDATA Text cannot be written at the top of the scope; only within an element.")
	self.hFile:write("<![CDATA[", ...)
	self.hFile:write("]]>")
	self.lastWasElement = false;
end

--[=[--
Adds an XML processing instruction.

This function may be called at any time.

@tparam string name The XML QName for the processing instruction.
@tparam string data A string to be written for the PI's data. ***Will not be escaped.***
]=]
function xml_writer:AddProcessingInstruction(name, data)
	CloseElement(self);
	self.hFile:write("<?", name, " ", data, "?>");
	if(#self.elemStack == 0) then self.hFile:write("\n"); end
	self.lastWasElement = false;
end

--[=[--
Alternate name for @{AddProcessingInstruction}.
@function xml_writer:AddPI
]=]
xml_writer.AddPI = xml_writer.AddProcessingInstruction;

--[=[--
Inserts one or more strings as comments. No spaces are inserted between the string parameters.

This function may be called at any time.
]=]
function xml_writer:AddComment(...)
	CloseElement(self);
	--@todo Escape "-->" strings
	self.hFile:write("<!--", ...)
	self.hFile:write("-->");
	self.lastWasElement = false;
end

--[=[--
Adds a public, external DOCTYPE setting to the XML file. This function can only be called before creating a root element.

@tparam string doctype The DOCTYPE name to add.
@tparam string loc1 The first location after PUBLIC.
@tparam string loc2 The second location after PUBLIC.
]=]
function xml_writer:AddDocTypePublic(doctype, loc1, loc2)
	assert(not self.hasRoot, "You can only set the doctype before a root element has been created.");
	assert(not self.hasDocType, "You can only set the doctype once.");
	
	self.hasDocType = true;
	
	self.hFile:write(string.format([[<!DOCTYPE %s PUBLIC %s %s>]], doctype, loc1, loc2), "\n");
end

--[=[--
Closes the XML file. No other functions can be called after closing the writer.

Must be called after closing the root element.
]=]
function xml_writer:Close()
	assert(#self.elemStack == 0, "You must pop all of the elements before closing.");
	self.hFile:close();
end

--[=[--
@section end
]=]

local XmlWriter = {}

--[=[--
Creates an @{xml_writer} object for a file.

This function will write the XML header. The writer will be positioned just after the XML header. In particular, the root element will *not* have been created yet. So you can add comments, PIs and DocType instructions before the root.

@tparam string strFilename The file to open. The file will be overwritten.
@treturn XmlWriter.xml_writer The created writer to the given file.
]=]
function XmlWriter.XmlWriter(strFilename)
	local writer = {};
	writer.elemStack = {};
	writer.nsStack = {};
	writer.formatStack = {};
	writer.needCloseElem = false;
	
	writer.hFile = assert(io.open(strFilename, "w"), "Could not open file " .. strFilename);
	
	writer.hFile:write([[<?xml version="1.0" encoding="UTF-8"?>]], "\n")
	
	AddMembers(writer);
	
	return writer;
end

return XmlWriter
