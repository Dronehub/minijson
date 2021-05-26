Usage
=====

MiniJSON implements the same interface as json or yaml, namely:

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

Example:

.. code-block:: python

    from minijson import loads_object, dumps_object

    class Test:
        def __init__(self, a):
            self.a = a

    a = Test(3)
    b = dumps_object(a)
    loads_object(b, Test)
