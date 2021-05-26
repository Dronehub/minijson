import os
from distutils.extension import Extension

from Cython.Build import cythonize
from Cython.Compiler.Options import get_directive_defaults
from distutils.core import setup

directive_defaults = get_directive_defaults()
directive_defaults['language_level'] = '3'
macros = []
if 'DEBUG' in os.environ:
    print('Enabling debug mode')
    directive_defaults['linetrace'] = True
    directive_defaults['profiling'] = True
    directive_defaults['binding'] = True
    macros = [('CYTHON_TRACE', '1')]

extensions = [Extension("minijson", ["minijson.pyx"],
                        define_macros=macros),
              ]

setup(version='2.0',
      ext_modules=cythonize(extensions),
      )
