Welcome to MiniJSON's documentation!
====================================

.. toctree::
   :maxdepth: 2
   :caption: Contents:

   usage
   specification
   changelog


MiniJSON is a space-aware binary format for representing arbitary superset JSON.
It's however most efficient when dealing with short (less than 16 elements) lists and objects,
whose all keys are strings.

By superset I mean anything that is correct JSON, including binary strings, which JSON
doesn't code for.

You should avoid objects with keys different than strings, since they will always use a
4-byte length field. This is to be improved in a future release. Key not being strings
is anyway invalid JSON_.

.. warning::

   Note that the valid mimetype for this is :code:`application/x-minijson`,
   although you can use the :code:`application/minijson` in a pinch.

.. _JSON: https://www.w3schools.com/js/js_json_objects.asp


Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
