--[[
self library is for writing XML files. The files are always UTF-8, version 1.0, with the appropriate XML header.

To create a writer, use the function XmlWriter.XmlWriter, passing in a filename that you want written to. self function will automatically create the XML header. The function returns an XmlWriter "class", which is why creation looks like a class constructor. All of the following are member functions of the class.

== PushElement/PopElement ==
Elements are added in a push/pop fasion. PushElement creates an element, and PopElement creates the end-tag (or the closing "/>" for empty elements). PushElement takes 2 parameters: the element's QName, and the optional default namespace. No checking is made to see if the element name has a qualifier at the same time as a default namespace.

Redundant default namespace definitions will not be printed, so feel free to always pass a namespace parameter. If no namespace is passed in, the currently set default namespace is used.

== AddAttribute ==
Attributes can be added, within the scope of a Push/PopElement, and before any other node additions (IE: adding elements, text, PIs, or comments), with the AddAttribute function. self function takes an attribute QName and a string. Currently, it does not attempt to properly adjust the string for the right kind of quotes, always using double-quotes.

AddAttribute can add multiple attributes at once. If you pass in a table rather than 2 parameters, it will walk all of the string members of that table and set the element's attributes to key="value" for each one.

== AddNamespace ==
If you want to add namespace prefix definitions to an element, use AddNamespace. self function takes a prefix (NCName) and a namespace string. Basically, it's a utility version of AddAttribute, except that it doesn't have a table version.

== AddText/AddCDataText ==
The AddText function can be used to add text. CDATA text can be added with AddCDataText. As with similar Lua writing functions, you may pass multiple strings as multiple parameters, and they will be written out in sequence. For AddCDataText, all the strings will be in one big CData. No escaping or checks of any kind is done here.

== AddProcessingInstruction/AddPI ==
The AddProcessingInstruction (or AddPI for short) adds a processing instruction. It takes a processing instruction name and a string containing the processing instruction's data.

== AddComment ==
The AddComment creates a comment node with the given text. Again, no escaping is done.
]]

module(..., package.seeall);

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

local ClassMembers = {};

local function AddMembers(writer)
	for funcName, func in pairs(ClassMembers) do
		writer[funcName] = func;
	end
end

local function CloseElement(self, postChar)
	if(self.needCloseElem) then
		self.hFile:write(">");
		self.needCloseElem = false;
		self.lastWasElement = true;
	end
end

function ClassMembers.PushElement(self, elementName, namespace, noPrettyPrint)
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

function ClassMembers.PopElement(self)
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

local function PutAttrib(self, attribName, data)
	assert(attribName ~= "xmlns", "You cannot manually change the default namespace.");

	data = escape_string(data)
	self.hFile:write(" ", attribName, "=\"", data, "\"");
end

function ClassMembers.AddAttribute(self, attribName, data)
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

function ClassMembers.AddNamespace(self, prefix, namespace)
	assert(self.needCloseElem, "The element has been closed. Cannot add namespace " .. namespace);

	PutAttrib(self, "xmlns:" .. prefix, namespace);
end

function ClassMembers.AddText(self, ...)
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

function ClassMembers.AddCDataText(self, ...)
	CloseElement(self);
	assert(#self.elemStack > 0, "CDATA Text cannot be written at the top of the scope; only within an element.")
	self.hFile:write("<![CDATA[", ...)
	self.hFile:write("]]>")
	self.lastWasElement = false;
end

function ClassMembers.AddProcessingInstruction(self, name, data)
	CloseElement(self);
	self.hFile:write("<?", name, " ", data, "?>");
	if(#self.elemStack == 0) then self.hFile:write("\n"); end
	self.lastWasElement = false;
end

ClassMembers.AddPI = ClassMembers.AddProcessingInstruction;

function ClassMembers.AddComment(self, ...)
	CloseElement(self);
	--Escaepe "-->" strings
	self.hFile:write("<!--", ...)
	self.hFile:write("-->");
	self.lastWasElement = false;
end

function ClassMembers.AddDocTypePublic(self, doctype, loc1, loc2)
	assert(not self.hasRoot, "You can only set the doctype before a root element has been created.");
	assert(not self.hasDocType, "You can only set the doctype once.");
	
	self.hasDocType = true;
	
	self.hFile:write(string.format([[<!DOCTYPE %s PUBLIC %s %s>]], doctype, loc1, loc2), "\n");
end

function ClassMembers.Close(self, elementName)
	assert(#self.elemStack == 0, "You must pop all of the elements before closing.");
	self.hFile:close();
end

function XmlWriter(strFilename)
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


