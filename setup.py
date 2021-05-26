import os
from setuptools import find_packages
from distutils.core import setup
from snakehouse import Multibuild, build, monkey_patch_parallel_compilation, find_pyx

monkey_patch_parallel_compilation()

build_kwargs = {}
directives = {'language_level': '3'}
dont_snakehouse = False
multi_kwargs = {}
if 'DEBUG' in os.environ:
    print('Enabling debug mode')
    dont_snakehouse = True
    build_kwargs.update(gdb_debug=True)
    directives.update(embedsignature=True,
                      profile=True,
                      linetrace=True,
                      binding=True)
    multi_kwargs['define_macros'] = [('CYTHON_TRACE', '1'),
                                     ('CYTHON_TRACE_NOGIL', '1')]

    import Cython.Compiler.Options
    Cython.Compiler.Options.annotate = True


setup(version='1.7',
      packages=find_packages(include=['minijson', 'minijson.*']),
      ext_modules=build([Multibuild('minijson', find_pyx('minijson'),
                                    dont_snakehouse=dont_snakehouse,
                                    **multi_kwargs), ],
                        compiler_directives=directives, **build_kwargs),
      python_requires='!=2.7.*,!=3.0.*,!=3.1.*,!=3.2.*,!=3.3.*,!=3.4.*,!=3.5.*,!=3.6.*,!=3.7.*',
      )
