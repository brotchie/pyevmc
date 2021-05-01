"""Tests for EVMC Python bindings.

Note, these tests rely on a valid EVMC implementation. Set the EVMC_MODULE
environment variable to your EMVC shared library. For example, if using
evmone compiled in the parent directory:

   $ EVMC_MODULE=../evmone/build/lib/libevmone.so python3 test.py

"""
import os
import unittest
from typing import Dict, Optional

import evmc

EVMC_MODULE = os.environ.get("EVMC_MODULE")
if EVMC_MODULE is None:
    raise Exception(
        f"Please set EVMC_MODULE to the filename of a valid EVMC implementation.")

ZERO256 = (0).to_bytes(32, "big")
ALICE = bytes.fromhex("4be9d79ab0685d9c24ec801e26d1233b61832733")
BOB = bytes.fromhex("65f9e07ccb818f9258ed4b9bc2a8613c04f5db75")


def to_uint256(value: int) -> bytes:
    """Encodes an unsigned integer as a big endian uint256.""" 
    return value.to_bytes(32, "big")


def from_uint256(value: bytes) -> int:
    """Decodes a big endian uint256 into a Python int."""
    return int.from_bytes(value, "big")


def build_simple_message(destination: bytes, sender: bytes):
    return evmc.Message.build(evmc.EVMC_CREATE, 0, int(1e9), destination, sender, ZERO256)


class HostInterface(evmc.HostInterface):

    def __init__(self, storage: Optional[Dict[bytes, bytes]] = None):
        if storage is None:
            storage = {}
        self.storage = storage

    def access_storage(self, address: bytes, key: bytes) -> evmc.evmc_access_status:
        return evmc.EVMC_ACCESS_COLD

    def get_storage(self, address: bytes, key: bytes):
        return self.storage.get(key, ZERO256)

    def set_storage(self, address: bytes, key: bytes, value: bytes) -> evmc.evmc_storage_status:
        self.storage[key] = value
        return evmc.EVMC_STORAGE_MODIFIED


class VMTest(unittest.TestCase):

    def setUp(self):
        super().setUp()
        self.vm = evmc.VM.from_filename(EVMC_MODULE)

    def test_get_storage(self):
        host_interface = HostInterface({
            to_uint256(32): to_uint256(15)
        })
        code = bytes.fromhex(
            # Load from storage location offset 32.
            "6020"  # PUSH 32
            "54"   # SLOAD
            # Store the loaded value in memory and return it.
            "6000"  # PUSH 0
            "52"   # MSTORE
            "6020"  # PUSH 32
            "6000"  # PUSH 0
            "f3"   # RETURN
        )

        result = self.vm.execute(
            host_interface,
            build_simple_message(ALICE, BOB),
            code,
        )

        self.assertEqual(from_uint256(result.output_data), 15)

    def test_set_storage(self):
        host_interface = HostInterface()
        code = bytes.fromhex(
            # Push and store 15 to storage location 32.
            "600f"  # PUSH 15
            "6020"  # PUSH 32
            "55"   # SSTORE
        )

        result = self.vm.execute(
            host_interface,
            build_simple_message(ALICE, BOB),
            code,
        )

        self.assertEqual(host_interface.storage, {
                         to_uint256(32): to_uint256(15)})


if __name__ == "__main__":
    unittest.main()
