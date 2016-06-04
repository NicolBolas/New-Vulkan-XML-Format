% How to Read the New Schema

The layout of `new_registry.rnc` is based on the layout of an existing and successful schema: the DocBook 5.x RelaxNG schema. The goal with this layout is ease of extensibility.

RelaxNG has a [comprehensive way of externally referencing a schema](http://books.xmlschemata.org/relaxng/relax-CHP-10.html) when building a new one. This allows one to augment or override elements of one schema via inclusion. However, to take the best advantage of it, the source schema needs to be built in a certain way.

## Pattern naming

The naming convention for patterns used in the schema exists to make it easy to find a particular element or attribute.

All pattern names are of the form `X.Y.Z`, with as many period-delimited divisions as needed. The meaning of each division is as follows.

The first division of a pattern names in this schema will always be `reg`. This represents patterns defined by the new registry schema. This naming makes it easy to avoid accidentally overwriting existing patterns in a schema extension.

Certain pattern name suffixes have special meaning. These are:

* `contents`: Defines the content model for a single element.
* `attlist`: Defines a list of attributes associated with a single element.
* `attrib`: Defines a single attribute.
* `model`: Defines an arbitrary content model.
* `data`: Defines a data type.

### Single Element

Any pattern name which does not have one of these suffixes defines a *single* element. The name of the element defined by that pattern is *always* equivalent to the name of the last division used in the pattern. So `reg.temp.foo` will define an the element named `foo`. `reg.bar` will define the element named `bar`.

The subdivisions that aren't part of the element's name are usually used to associate the element with its parent element. `reg.temp.foo` might define the `foo` element that is a child of the `temp` element, for example. This is typically used when an element is tightly coupled with its parent.

Every element defined by the schema will have a single pattern that defines it.

### Single attribute

Any pattern name that ends in `attrib` defines a *single* attribute. The name of the attribute will match the last division of the pattern name before the `attrib` suffix. Therefore, the pattern named `reg.common.foo.attrib` defines an attribute named `foo`.

The subdivisions in the pattern name that do not name the attribute usually are related to the attribute. They will often name the element that this particular attribute comes from. If the attribute is not associated with a specific element, then they will frequently use some other meaningful division name, to avoid name collisions.

Every attribute defined by the schema will have a single pattern that defines it.

### Element contents

Every element definition is of the form `element element-name { contents }`, where `contents` is a single pattern. The name of this pattern is the element's pattern name with the `contents` suffix. So if there is a pattern named `reg.temp.foo`, then it will define an element named `foo`, which will have its contents defined by the pattern `reg.temp.foo.contents`.

This is done to make it easier to extend the data model for an element without having to redefine the entire element.

### Main element attributes

In most cases, attributes for an element do not participate in the overall content model of the element. That is, the presence or absence of most attributes will not affect whether certain sub-elements will exist in the element. As such, most attributes are simply listed first.

Every element will have a pattern named the same as the element's pattern with the `attlist` suffix. It is used by the `contents` pattern for that element, and it includes the attributes which do not affect the overall element contents.

As an example, `reg.temp.foo` will have a `reg.temp.foo.contents`. One of the patterns used in the contents will be `reg.temp.foo.attlist`, which specifies most of the attributes for that element.

Attributes will only be used outside of an `attlist` if they affect the sub-element contents of the attribute. If the element has no attributes, the `attlist` pattern will still exist; it will simply be `empty`.

### Arbitrary content models

Sometimes, putting a content model into a single pattern would make it unwieldy to read or modify. In some cases, a particular sub-pattern is used in multiple locations, and it is best not to repeat information.

In these cases, it is useful to simply declare a named pattern and use it where it is appropriate. Such patterns will have a suffix of `model`.

### Data types

Any pattern ending in `data` represents some kind of data type, such as `text` or a W3C XML Schema data type. As an example, if there is an attribute who's text must be valid C/C++ identifiers, it would use this:

	reg.some-attribute.attrib =
		attribute { reg.identifier.data }

This is useful for giving a semantic meaning to what would otherwise have been an arbitrary `text` or data type field.