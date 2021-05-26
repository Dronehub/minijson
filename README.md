MiniJSON
========

Usage
-----

As usual, please [RTFM](minijson/routines.pxd).
Here's the [specification](specification.md) of MiniJSON

It works pretty the same as pyyaml or json:

```python
from minijson import dumps, loads

b_bytes = dumps({'hello': 'world'})
data = loads(b_bytes)
assert data == {'hello': 'world'}

import io
from minijson import dump

cio = io.BytesIO()
dump({'hello': 'world'}, cio)
```

By defaults floats are encoded as IEEE 754 singles. To force them to be encoded as doubles, do:

```python
from minijson import switch_default_float, switch_default_double

switch_default_double()
# now everything is encoded as a double
switch_default_float()
# and now as float
```

Exceptions
----------

```python
from minijson import MiniJSONError, EncodingError, DecodingError

assert issubclass(MiniJSONError, ValueError)
assert issubclass(DecodingError, MiniJSONError)
assert issubclass(EncodingError, MiniJSONError)
```

Loading and dumping objects
---------------------------

Assume you have an object defined like this:

```python
class Test:
    def __init__(self, a):
        self.a = a

    def __eq__(self, o):   
        """Not necessary"""
        return self.a == o.a
```

You can use provided methods to serialize and unserialize it:

```python
from minijson import loads_object, dumps_object

a = Test(2)
b = dumps_object(a)
c = loads_object(b, Test)
assert a == c
```
