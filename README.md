# PyEVMC

> Python bindings for the Ethereum Client-VM Connector API.

From Python, use any Ethereum VM implementation that implements [EVMC](https://github.com/ethereum/evmc).

# Installation

Make sure Cython is installed:

```sh
pip install cython
```

Sync the `evmc` submodule:

```sh
git submodule init && git submodule update
```

Build pyevmc:

```sh
python3 setup.py build_ext -i
```

# Tests

First build [evmone](https://github.com/ethereum/evmone), and then run the unit testing suite:

```sh
EVMC_MODULE=../evmone/build/lib/libevmone.so python3 test.py
```

Set the `EVMC_MODULE` environment variable to the location of your combine evmone module.

# Credits
Thanks for the authors of [evmc](https://github.com/ethereum/evmc/blob/master/AUTHORS.md) and [evmone](https://github.com/ethereum/evmone/blob/master/AUTHORS).

# License
MIT License
