% How to Read the New Schema

The way `new_registry.rnc` is structured is based on the structure of an existing and successful schema: the DocBook 5.x RelaxNG schema. The goal with this structure is ease of extensibility.

RelaxNG has a [comprehensive way of externally referencing a schema](http://books.xmlschemata.org/relaxng/relax-CHP-10.html) when building a new one. This allows one to augment or override elements of one schema via inclusion. However, to take the best advantage of it, the source schema needs to be built in a certain way.

## Naming

The naming convention for patterns used in the schema exists to make it easy to find a particular element or attribute.

All pattern names are of the form `X.Y.Z`, with as many `.`-delimited divisions as needed. The meaning of each division is as follows.

The first division of a pattern name is always `reg`. This represents patterns defined by the new registry schema. This naming makes it easy to avoid accidentally overwriting existing patterns in your extension.

The pattern named `reg.root-element` is the starting pattern for the registry format.

The division `reg.data.X` represents some kind of data type, such as `text` or a W3C XML Schema data type. The `X` is a description of the meaning of the data type. For example, text strings which must be valid C/C++ identifiers use `reg.data.identifier` as their data type.

Certain pattern name suffixes have special meaning. These are:

* `contents`
* `attribs`
* `attrib`
* `model`

Any pattern name which does not have one of these suffixes, is not one of the `reg.data` patterns, and is not `reg.root-element`, defines a *single element*. The name of the element defined by that pattern is *always* equivalent to the name of the last division used in it. So `reg.temp.foo` will define the element `foo`. `reg.bar` will define the element `bar`.

Every element definition is of the form `element ElementName { contents }`, where `contents` is a single pattern. Namely, it is a pattern that is named the same as the element's pattern, but with the `contents` suffix. So if there is a pattern named `reg.temp.foo`, then it will define an element named `foo`, which will have its contents defined by the pattern `reg.temp.foo.contents`.

The `contents` pattern for an element will usually define the attributes of that element by specifying a single pattern that ends in `attribs`, using the element's pattern name as the rest. So `reg.temp.foo` will have a `reg.temp.foo.contents`, and one of the pattern used in those contents will be `reg.temp.foo.attribs`, which specifies most of the attributes for that element.

This will only be averted if an attribute needs to interpose itself into the element's content model. Or if there are no attributes on that element.



