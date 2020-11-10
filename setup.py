from distutils.core import setup
from Cython.Build import cythonize

setup(
    ext_modules=cythonize(["solution.pyx", "sa_solver.pyx"]),
)

# run: python setup.py build_ext --inplace