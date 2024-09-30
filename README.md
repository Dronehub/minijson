MiniJSON
========

Further development of MiniJSON has been moved to [our servers](https://git.dms-serwis.com.pl/smokserwis/minijson).

![Passing CI](https://github.com/smok-serwis/minijson/actions/workflows/main.yml/badge.svg)
[![Maintainability](https://api.codeclimate.com/v1/badges/20392a075de646680403/maintainability)](https://codeclimate.com/github/smok-serwis/minijson/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/20392a075de646680403/test_coverage)](https://codeclimate.com/github/smok-serwis/minijson/test_coverage)
[![Issue Count](https://codeclimate.com/github/smok-serwis/minijson/badges/issue_count.svg)](https://codeclimate.com/github/smok-serwis/minijson)
[![Documentation Status](https://readthedocs.org/projects/minijson/badge/?version=latest)](http://minijson.readthedocs.io/en/latest/?badge=latest)
[![PyPI](https://img.shields.io/pypi/pyversions/minijson.svg)](https://pypi.python.org/pypi/minijson)
[![PyPI version](https://badge.fury.io/py/minijson.svg)](https://badge.fury.io/py/minijson)
[![PyPI](https://img.shields.io/pypi/implementation/minijson.svg)](https://pypi.python.org/pypi/minijson)
[![PyPI](https://img.shields.io/pypi/wheel/minijson.svg)]()
[![License](https://img.shields.io/pypi/l/minijson)](https://github.com/smok-serwis/minijson)

MiniJSON is a codec for a compact binary representation of a superset of JSON
(binary values) are supported.

Note that source builds are submitted to [PyPI](https://pypi.python.org/pypi/minijson), however in order to leverage binary wheels you should use `--index-url https://git.dms-serwis.com.pl/api/v4/groups/330/-/packages/pypi/simple`.

Note
----

Active development of **minijson** is moved to this fork.
[Dronehub](https://github.com/Dronehub) has no interest in further developing this awesome
technology.

Usage
-----

Refer to the [documentation](http://minijson.readthedocs.io/en/latest/?badge=latest)
for use.

If there are no binary wheels precompiled for this platform, you will need to
compile it yourself.
Alternatively, you can
[file an issue](https://github.com/smok-serwis/minijson/issues/new)
and I'll do my best to compile a wheel for you.

Compiling own wheels
--------------------

If there's no wheel, and you'd like to compile it on your own, you'll
require [Cython](https://cython.org/) installed.

Run the Dockerfile to launch unit tests locally.
