% Improved Vulkan XML format

An attempt to improve the Vulkan XML registry file.

Design goals, in roughly priority order:

1. Ensure that 100% of the current information in `vk.xml` is captured in the new format. Transformation back and forth should be lossless.
2. Make it easier to generate bindings for non-C/C++ languages. Ideally, it should not require tools to parse C/C++ code directly.
3. Make the RelaxNG schema actually verify the basic integrity of the document. The current `registry.rnc` doesn't provide much verification, even of the basic structure of the registry. For example, `<type category="basetype">` can include struct `<member>` elements, even though such a thing has no meaning and will not parse correctly.
4. Make the format more consistent. For example, the name of a `type` element sometimes appears in an attribute and sometimes in a `<name>` element within the element.
5. Make the format more logically structured. For example, the current schema allows the content model of an element to radically change because of an attribute being set to a certain value. `registry.rnc`'s `<type category="whatever">` elements are really different kinds of elements with their own content models.
6. Minimize changes needed to existing infrastructure, where they do not conflict with the above. Changing element names is generally OK, but rearranging the basic structure of the file should be avoided.
7. Structure the RelaxNG schema to make it easier to extend via RelaxNG's own extension/inclusion mechanisms. This also makes it easier to extend when adding new kinds of data.


