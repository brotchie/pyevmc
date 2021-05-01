import os

from Cython.Build import cythonize
from setuptools import setup, Extension

VERSION = "0.1.0"

extension = Extension(
    "evmc",
    sources=["evmc.pyx", "evmc/lib/loader/loader.c"],
    include_dirs=["evmc/include"],
)

with open("README.md", "rb") as f:
    long_description = f.read().decode("utf-8")

setup(
    name="pyevmc",
    ext_modules=cythonize(
        extension,
        compiler_directives={"language_level": "3"}
    ),
    version=VERSION,
    description=("Python bindings for EVMC, the low-level ABI between Ethereum "
                 "Virtual Machines (EVMs) and Ethereum Clients"),
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/brotchie/pyevmc",
    author="James Brotchie",
    author_email="brotchie@gmail.com",
    license="MIT",
    classifiers=[
        "Intended Audience :: Developers",
        "License :: OSI Approved :: MIT License",
        "Operating System :: POSIX :: Linux",
        "Programming Language :: Python :: 3",
    ],
    python_requires=">=3.6",
)
