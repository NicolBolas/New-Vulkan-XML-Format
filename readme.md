% Improved Vulkan XML format

This project is an attempt to improve the Vulkan XML registry file. The design goals for the new format, in roughly priority order:

1. Ensure that 100% of the current information in `vk.xml` is captured in the new format. Transformation back and forth should be lossless.

2. Make it easier to generate bindings for non-C languages. Extracting information from the current registry requires being able to parse C type declarations. This should be avoided where possible.

3. Make the RelaxNG schema actually verify the basic integrity of the document. The current `registry.rnc` doesn't provide much verification, even of the basic structure of the registry. For example, according to the schema, the `<type category="basetype">` element can include struct `<member>` child elements, even though such a thing has no meaning and cannot be correctly processed by tools.

4. Make the format more consistent. For example, the name of a `type` element sometimes appears in an attribute and sometimes in a `<name>` sub-element within the element. This makes processing such declarations more difficult. However, do note that improving consistency can sometimes lead to information being in two places.

5. Make the format more logically structured. For example, the current schema allows the content model of an element to radically change because of an attribute being set to a certain value.

    The various `<type category="whatever">` elements are really completely different elements, and in many cases have entirely different conceptual content models. Yet they still claim to be `type` elements. This requires processing code to be radically different for the same element, based on the presence or absence of an attribute.

6. Minimize changes needed to the existing processing infrastructure, where they do not conflict with the above. If the existing infrastructure is going to be able to process the new format, it will have to change somewhat. But using different element names is typically an easy fix. By contrast, using a completely different structural layout is not. The latter should be avoided unless there is a genuine need.

7. Layout the RelaxNG schema in a way that makes it easier to extend via RelaxNG's own extension/inclusion mechanisms. This also makes it easier to extend when adding new kinds of data. It should be possible to search for where an attribute or element is defined just by knowing the attribute/element's name.

8. Make the format amenable to transformation to and processing in non-XML formats like JSON. This means avoiding lots of "markup"-style formatting.

## Files of interest

`new_registry.rnc` contains the RelaxNG compact schema that defines the new XML format. `new_registr.rng` is a non-compact version of the schema (it may be out of date, since I primarily edit the compact version).

The old registry schema and `vk.xml` files are in the `src` directory.

All of the .lua files are tools for converting between the old and new formats.

`reading_the_schema.md` explains some of the decisions behind the way the schema is defined, as well as providing the conventions used in its authoring.

## Dependencies

Generating the new format requires the use of [Lua 5.1 or later](http://www.lua.org/download.html). It requires no other dependencies than this; any files needed for XML processing are provided.

## Usage

Executing `lua.exe ConvertToNewFmt.lua` from this directory will generate `test.xml`, which is a file that stores the `vk.xml` data in the new format. No other parameters are needed for this process.

