# distutils: language = c++

include 'loader.pxi'
include 'evmc.pxi'

from cpython.bytes cimport PyBytes_FromStringAndSize
from libc.stdlib cimport malloc, free
from libc.string cimport memcpy

cdef size_t ADDRESS_SIZE = 20
cdef size_t BYTES32_SIZE = 32

class EvmcError(Exception):
    pass

class HostInterface:

    def account_exists(self, address: bytes) -> bool:
        raise NotImplementedError()

    def get_storage(self, address: bytes, key: bytes) -> bytes:
        raise NotImplementedError()

    def set_storage(self, address: bytes, key: bytes, value: bytes) -> evmc_storage_status:
        raise NotImplementedError()

    def get_balance(self, address: bytes) -> bytes:
        raise NotImplementedError()

    def get_code_size(self, address: bytes) -> int:
        raise NotImplementedError()

    def get_code_hash(self, address: bytes) -> bytes:
        raise NotImplementedError()

    def copy_code(self, address: bytes, code_offset: int) -> bytes:
        raise NotImplementedError()

    def selfdestruct(self, address: bytes, beneficiary: bytes) -> None:
        raise NotImplementedError()

    def call(self, message: "Message") -> "Result":
        raise NotImplementedError()

    def get_tx_context(self) -> TxContext:
        raise NotImplementedError()

    def get_block_hash(self, number: int) -> bytes:
        raise NotImplementedError()

    # TODO(brotchie): Implement log delegation.
    #evmc_emit_log_fn emit_log

    def access_account(self, address: bytes) -> evmc_access_status:
        raise NotImplementedError()

    def access_storage(self, address: bytes, key: bytes) -> evmc_access_status:
        raise NotImplementedError()


cdef bytes evmc_bytes32_to_bytes(const evmc_bytes32* value):
    return PyBytes_FromStringAndSize(<char*>value.bytes, BYTES32_SIZE)

cdef bytes evmc_address_to_bytes(const evmc_address* value):
    return PyBytes_FromStringAndSize(<char*>value.bytes, ADDRESS_SIZE)

cdef evmc_bytes32 bytes_to_evmc_bytes32(value: bytes):
    cdef evmc_bytes32 result
    result.bytes = value
    return result

cdef evmc_uint256be bytes_to_evmc_uint256be(value: bytes):
    cdef evmc_uint256be result
    result.bytes = value
    return result

cdef evmc_address bytes_to_evmc_address(value: bytes):
    cdef evmc_address result
    result.bytes = value
    return result

cdef libcpp.bool evmc_account_exists_proxy(evmc_host_context* context,
                                           const evmc_address* address) with gil:
    return (<object>context).account_exists(evmc_address_to_bytes(address))

cdef evmc_bytes32 evmc_get_storage_proxy(evmc_host_context* context,
                                         const evmc_address* address,
                                         const evmc_bytes32* key) with gil:
    return bytes_to_evmc_bytes32(
        (<object>context).get_storage(evmc_address_to_bytes(address),
                                      evmc_bytes32_to_bytes(key)))

cdef evmc_storage_status evmc_set_storage_proxy(evmc_host_context* context,
                                                const evmc_address* address,
                                                const evmc_bytes32* key,
                                                const evmc_bytes32* value) with gil:
    return (<object>context).set_storage(evmc_address_to_bytes(address),
                                         evmc_bytes32_to_bytes(key),
                                         evmc_bytes32_to_bytes(value))

cdef evmc_uint256be evmc_get_balance_proxy(evmc_host_context* context,
                                           const evmc_address* address) with gil:
    return bytes_to_evmc_bytes32((<object>context).get_balance(evmc_address_to_bytes(address)))

cdef size_t evmc_get_code_size_proxy(evmc_host_context* context,
                                     const evmc_address* address) with gil:
    return (<object>context).get_code_size(address.bytes)

cdef evmc_bytes32 evmc_get_code_hash_proxy(evmc_host_context* context,
                                           const evmc_address* address) with gil:
    return bytes_to_evmc_bytes32((<object>context).get_code_hash(evmc_address_to_bytes(address)))

cdef void evmc_selfdestruct_proxy(evmc_host_context* context,
                                  const evmc_address* address,
                                  const evmc_address* beneficiary) with gil:
    (<object>context).selfdestruct(evmc_address_to_bytes(address),
                                   evmc_address_to_bytes(beneficiary))

cdef size_t evmc_copy_code_proxy(evmc_host_context* context,
                                 const evmc_address* address,
                                 size_t code_offset,
                                 uint8_t* buffer_data,
                                 size_t buffer_size) with gil:
    code = (<object>context).copy_code(evmc_address_to_bytes(address), code_offset)
    copy_size = min(<size_t>len(code), buffer_size)
    cdef char* c_code = code
    memcpy(buffer_data, c_code, copy_size)

    return copy_size

cdef evmc_result evmc_call_proxy(evmc_host_context* context,
                                 const evmc_message* msg) with gil:
    message = Message.from_message(<evmc_message*>msg)
    return (<Result?>(<object>context).call(message)).to_result()

cdef evmc_tx_context evmc_get_tx_context_proxy(evmc_host_context* context) with gil:
    return (<TxContext?>(<object>context).get_tx_context()).to_context()

cdef evmc_bytes32 evmc_get_block_hash_proxy(evmc_host_context* context,
                                            int64_t number) with gil:
    return bytes_to_evmc_bytes32((<object>context).get_block_hash(number))

cdef void evmc_emit_log_proxy(evmc_host_context* context,
                              const evmc_address* address,
                              const uint8_t* data,
                              size_t data_size,
                              const evmc_bytes32 topics[],
                              size_t topics_count) with gil:
    # TODO(brotchie): Implement log delegation.
    pass

cdef evmc_access_status evmc_access_account_proxy(evmc_host_context* context,
                                                  const evmc_address* address) with gil:
    return (<object>context).access_account(address.bytes)

cdef evmc_access_status evmc_access_storage_proxy(evmc_host_context* context,
                                                  const evmc_address* address,
                                                  const evmc_bytes32* key) with gil:
    return (<object>context).access_storage(evmc_address_to_bytes(address), evmc_bytes32_to_bytes(key))


cdef evmc_host_interface PROXY_HOST_INTERFACE = evmc_host_interface(
    evmc_account_exists_proxy,
    evmc_get_storage_proxy,
    evmc_set_storage_proxy,
    evmc_get_balance_proxy,
    evmc_get_code_size_proxy,
    evmc_get_code_hash_proxy,
    evmc_copy_code_proxy,
    evmc_selfdestruct_proxy,
    evmc_call_proxy,
    evmc_get_tx_context_proxy,
    evmc_get_block_hash_proxy,
    evmc_emit_log_proxy,
    evmc_access_account_proxy,
    evmc_access_storage_proxy,
)


cdef class Result:
    cdef evmc_result c_result

    cdef evmc_result to_result(self):
        return self.c_result

    def __dealloc__(self):
        # Result objects have a release method that must be called to
        # release any resources associated with the result.
        if self.c_result.release:
            self.c_result.release(&self.c_result)

    @property
    def status_code(self) -> evmc_status_code:
        return self.c_result.status_code

    @property
    def status_code_name(self) -> str:
        return evmc_status_code(self.status_code).name

    @property
    def output_data(self) -> bytes:
        return PyBytes_FromStringAndSize(<char*>self.c_result.output_data, self.c_result.output_size)

    @staticmethod
    cdef Result from_result(evmc_result c_result):
        cdef Result result = Result.__new__(Result)
        result.c_result = c_result
        return result


cdef class TxContext:
    def __init__(
        self,
        tx_gas_price: bytes,
        tx_origin: bytes,
        block_coinbase: bytes,
        block_number: int,
        block_timestamp: int,
        block_gas_limit: int,
        block_difficulty: bytes,
        chain_id: bytes):

        self.tx_gas_price = tx_gas_price
        self.tx_origin = tx_origin
        self.block_coinbase = block_coinbase
        self.block_number = block_number
        self.block_timestamp = block_timestamp
        self.block_gas_limit = block_gas_limit
        self.block_difficulty = block_difficulty
        self.chain_id = chain_id

    cdef evmc_tx_context to_context(self):
        return evmc_tx_context(
            bytes_to_evmc_uint256be(self.tax_gas_price),
            bytes_to_evmc_address(self.tx_origin),
            bytes_to_evmc_address(self.block_coinbase),
            self.block_number,
            self.block_timestamp,
            self.block_gas_limit,
            bytes_to_evmc_uint256be(self.block_difficulty),
            bytes_to_evmc_uint256be(self.chain_id),
        )


cdef class Message:
    cdef evmc_message* c_message
    cdef libcpp.bool owns_ptr

    cdef evmc_message* to_message(self):
        return self.c_message

    @staticmethod
    cdef Message from_message(evmc_message* c_message, libcpp.bool owns_ptr = False):
        cdef Message message = Message.__new__(Message)
        message.c_message = c_message
        message.owns_ptr = owns_ptr
        return message

    @staticmethod
    cdef Message _build(
        evmc_call_kind kind,
        uint32_t flags,
        int32_t depth,
        int64_t gas,
        evmc_address destination,
        evmc_address sender,
        uint8_t* input_data,
        size_t input_size,
        evmc_uint256be value,
        evmc_bytes32 create2_salt):
        cdef evmc_message* message = <evmc_message*>malloc(sizeof(evmc_message))
        message.kind = kind
        message.flags = flags
        message.depth = depth
        message.gas = gas
        message.destination = destination
        message.sender = sender
        message.input_data = input_data
        message.input_size = input_size
        message.value = value
        message.create2_salt = create2_salt
        return Message.from_message(message, True)

    @staticmethod
    def build(kind: evmc_call_kind,
              depth: int,
              gas: int,
              destination_address: bytes,
              sender_address: bytes,
              value: bytes,
              input_data: bytes = None,
              create2_salt: bytes = None,
              flags: int = 0) -> Message:

        cdef uint8_t* c_input_data
        cdef evmc_bytes32 c_create2_salt

        if input_data is not None:
            c_input_data = input_data
            input_size = len(input_data)
        else:
            c_input_data = NULL
            input_size = 0

        if create2_salt is not None:
            c_create2_salt.bytes = create2_salt

        return Message._build(
            kind,
            flags,
            depth,
            gas,
            bytes_to_evmc_address(destination_address),
            bytes_to_evmc_address(sender_address),
            c_input_data,
            input_size,
            bytes_to_evmc_uint256be(value),
            c_create2_salt)

    def __dealloc__(self):
        if self.c_message is not NULL and self.owns_ptr:
            free(self.c_message)
            self.c_message = NULL


cdef class VM:
    """An instance of an EVMC virtual machine."""
    cdef evmc_vm* c_evm

    def __dealloc__(self):
        if self.c_evm is not NULL and self.c_evm.destroy is not NULL:
            self.c_evm.destroy(self.c_evm)

    @property
    def name(self) -> str:
        return bytes(self.c_evm.name).decode("utf-8") if self.c_evm is not NULL else None

    @property
    def version(self) -> str:
        return bytes(self.c_evm.version).decode("utf-8") if self.c_evm is not NULL else None

    @staticmethod
    cdef VM _from_vm(evmc_vm* evm):
        cdef VM vm = VM.__new__(VM)
        vm.c_evm = evm
        return vm

    @staticmethod
    cdef VM _load_and_create(char *filename):
        cdef evmc_loader_error_code ec
        vm = evmc_load_and_create(filename, &ec)
        if ec == EVMC_LOADER_SUCCESS:
            return VM._from_vm(vm)
        else:
            raise EvmcError(
                f"Failed to create EVM from filename {filename.decode('utf-8')}. "
                f"Error Code: {evmc_loader_error_code(ec)}. "
                f"Error Message: {evmc_last_error_msg()}."
            )


    @staticmethod
    cdef VM _load_and_configure(char *config):
        cdef evmc_loader_error_code ec
        vm = evmc_load_and_configure(config, &ec)
        if ec == EVMC_LOADER_SUCCESS:
            return VM._from_vm(vm)
        else:
            raise EvmcError(
                f"Failed to create EVM from config {config.decode('utf-8')}. "
                f"Error Code: {evmc_loader_error_code(ec)}. "
                f"Error Message: {evmc_last_error_msg()}."
            )

    @staticmethod
    def from_filename(filename: str) -> "VM":
        return VM._load_and_create(filename.encode("utf-8"))

    @staticmethod
    def from_config(config: str) -> "VM":
        return VM._load_and_configure(config.encode("utf-8"))

    def execute(self,
                host_interface: HostInterface,
                message: Message,
                code: bytes,
                revision: evmc_revision = EVMC_MAX_REVISION) -> Result:
        """Executes EVM code."""
        cdef uint8_t* c_code = code
        cdef size_t c_code_size = len(code)
        cdef evmc_message* c_message = message.to_message()

        # Release the GIL while the VM is running, GIL wil be acquired when the VM
        # makes HostInterface calls.
        with nogil:
            result = self.c_evm.execute(
                self.c_evm,
                &PROXY_HOST_INTERFACE,
                <evmc_host_context*>host_interface,
                revision,
                c_message,
                c_code,
                c_code_size,
            )
        return Result.from_result(result)