#!/bin/bash

# Env to set:
#   * PYPI_USER
#   * PYPI_PWD

apt-get update
apt-get install -y patchelf
pip install auditwheel doctor-wheel twine cython
python setup.py bdist_wheel
cd dist
doctor-wheel "*.whl"
auditwheel repair --plat "manylinux2014_$(uname -m)" "*.whl"
twine upload -u $PYPI_USER -p $PYPI_PWD "wheelhouse/*.whl"
