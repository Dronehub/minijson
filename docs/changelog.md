Changelog
=========

v2.8
----

* serializing a dict without :code:`use_strict_order` won't construct a list of it's items,
    allowing you to serialize large dictionaries

v2.7
----

* added option to sort dictionary keys before serialization

v2.6
----

* added option to serialize binary data

v2.5
----

* added :class:`minijson.MiniJSONEncoder`

v2.4
----

* added argument default
* fixing issue with serializing classes that subclass dict, list and tuple

v2.3
----

* :func:`minijson.loads` will now take any object that can provide it's :code:`__bytes__`

v2.2
----

* added support for PyPy and Python 3.5

v2.1
----

* proofed against loading empty strings
* Python 3.6 is supported
* minor speed improvements

v2.0
----

* fixed a bug with serializing uint32a
* added support for arbitrarily large integers
* major refactor
* backwards compatible 100%

v1.5
----

* fixed a bug with wrong type of dict and string was chosen
    for a dict which contains exactly 65535 keys.
    Since this is rare in production, it can wait.
    MiniJSON is still generated correctly.
* fixed a bug with dumping strings longer than 255 characters
    would not return a length
* fixed a bug with unserializing some strings

v1.4
----

* more compact representation for not-all-keys-are-strings object

v1.3
----

* object keys don't have to be strings anymore

v1.2
----

* removed the limit for string length and list and object size

v1.1
----

* fixed to work under older Pythons (got rid of the f-strings)
* fixed docstrings to signal that some functions raise exceptions
* fixed a bug with encoding long lists

v1.0
----

* first release

