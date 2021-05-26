.. MiniJSON documentation master file, created by
   sphinx-quickstart on Wed May 26 13:28:36 2021.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Welcome to MiniJSON's documentation!
====================================

.. toctree::
   :maxdepth: 2
   :caption: Contents:

   usage
   specification

MiniJSON is a space-aware binary format for representing arbitary JSON.
It's however most efficient when dealing with short (less than 16 elements) lists and objects,
whose all keys are strings.

You should avoid objects with keys different than strings, since they will always use a
4-byte length field. This is to be improved in a future release.

Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
