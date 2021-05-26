import os
from setuptools import find_packages
from distutils.core import setup
from snakehouse import Multibuild, build, monkey_patch_parallel_compilation, find_pyx

monkey_patch_parallel_compilation()

build_kwargs = {}
directives = {'language_level': '3'}
dont_snakehouse = False
if 'DEBUG' in os.environ:
    dont_snakehouse = True
    build_kwargs.update(gdb_debug=True)
    directives['embedsignature'] = True


setup(version='1.1rc1',
      packages=find_packages(include=['minijson', 'minijson.*']),
      ext_modules=build([Multibuild('minijson', find_pyx('minijson'),
                                    dont_snakehouse=dont_snakehouse), ],
                        compiler_directives=directives, **build_kwargs),
      python_requires='!=2.7.*,!=3.0.*,!=3.1.*,!=3.2.*,!=3.3.*,!=3.4.*,!=3.5.*,!=3.6.*,!=3.7.*',
      zip_safe=False
      )
