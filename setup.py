import os
from distutils.core import setup
from distutils.extension import Extension

from Cython.Build import cythonize
from Cython.Compiler.Options import get_directive_defaults


directive_defaults = get_directive_defaults()
directive_defaults['language_level'] = '3'
macros = []
if 'DEBUG' in os.environ:
    print('Enabling debug mode')
    directive_defaults['linetrace'] = True
    directive_defaults['binding'] = True
    macros = [('CYTHON_TRACE', '1')]

extensions = [Extension("minijson", ["minijson.pyx"],
    define_macros=macros),
]

setup(version='1.7',
      ext_modules=cythonize(extensions),
      python_requires='!=2.7.*,!=3.0.*,!=3.1.*,!=3.2.*,!=3.3.*,!=3.4.*,!=3.5.*,!=3.6.*,!=3.7.*',
      )
