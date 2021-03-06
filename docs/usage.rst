Usage
=====

.. warning:: Take care for your data to be without cycles. Feeding the encoder cycles
   will probably dump your interpreter's core.

MiniJSON implements the same interface as json or yaml, namely:

.. warning:: Cycles are not automatically detected. They might make the application hang
    or cause an MemoryError.

.. autofunction:: minijson.loads

.. autofunction:: minijson.dumps

.. autofunction:: minijson.dump

.. autofunction:: minijson.parse

For serializing objects you got the following:

.. autofunction:: minijson.dumps_object

.. autofunction:: minijson.loads_object

And the following exceptions:

.. autoclass:: minijson.MiniJSONError

.. autoclass:: minijson.EncodingError

.. autoclass:: minijson.DecodingError

Controlling float output
------------------------

By default, floats are output as IEEE 754 single. To switch to double just call:

.. autofunction:: minijson.switch_default_double

or to go again into singles:

.. autofunction:: minijson.switch_default_float

Serializing objects
-------------------

If you got an object, whose entire contents can be extracted from it's :code:`__dict__`,
and which can be instantiated with a constructor providing this :code:`__dict__` as keyword
arguments to the program, you can use functions below to serialize/unserialize them:

.. autofunction:: minijson.dumps_object

.. autofunction:: minijson.loads_object

Dumps returns objects of type :code:`bytes`.

Example:

.. code-block:: python

    from minijson import loads_object, dumps_object

    class Test:
        def __init__(self, a):
            self.a = a

    a = Test(3)
    b = dumps_object(a)
    c = loads_object(b, Test)
    assert a.a == c.a

MiniJSONEncoder
---------------

There's also a class available for encoding. Use it like you would a normal Python
:code:`JSONEncoder`:

.. autoclass:: minijson.MiniJSONEncoder
    :members:

.. warning:: The exact binary content output by :class:`~minijson.MiniJSONEncoder` will
    depend on internal Python hash order. To have same dicts return the same representation, you
    must use the parameter :code:`use_strict_order` in :class:`~minijson.MiniJSONEncoder`.

:class:`~minijson.MiniJSONEncoder` will then extract the items from the dictionary,
and sort them before dumping them to binary output. By enabling this feature you guarantee
that identical dicts, serialized by identical Pythons will have the exact same binary representation.

So take care when serializing that with large dicts, :code:`use_strict_order` will construct a list
of all it's items, while serializing a normal dict won't.
Only then strict order will be guaranteed. Your keys must be comparable anyway.
