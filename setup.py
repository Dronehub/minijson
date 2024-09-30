import os

try:
    from Cython.Build import cythonize
    from Cython.Compiler.Options import get_directive_defaults
except ImportError:
    print('Install Cython in order to build from source')
from setuptools import setup, Extension

directive_defaults = get_directive_defaults()
directive_defaults['language_level'] = '3'
macros = []
if 'DEBUG' in os.environ:
    print('Enabling debug mode')
    directive_defaults['linetrace'] = True
    directive_defaults['profiling'] = True
    directive_defaults['binding'] = True
    macros = [('CYTHON_TRACE', '1')]


setup(ext_modules=cythonize([Extension("minijson", ["minijson.pyx"], define_macros=macros)]))
