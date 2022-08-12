"""Cython declarations for EVMC standard."""

cimport libcpp
from libc.stdint cimport uint8_t, int32_t, uint32_t, int64_t
from libcpp cimport bool

cdef extern from "evmc/include/evmc/evmc.h":
    ctypedef struct evmc_bytes32:
        uint8_t bytes[32]

    ctypedef evmc_bytes32 evmc_uint256be

    ctypedef struct evmc_address:
        uint8_t bytes[20]

    cpdef enum evmc_call_kind:
        EVMC_CALL
        EVMC_DELEGATECALL
        EVMC_CALLCODE
        EVMC_CREATE
        EVMC_CREATE2

    cpdef enum evmc_flags:
        EVMC_STATIC

    ctypedef struct evmc_message:
        evmc_call_kind kind
        uint32_t flags
        int32_t depth
        int64_t gas
        evmc_address recipient
        evmc_address sender
        uint8_t* input_data
        size_t input_size
        evmc_uint256be value
        evmc_bytes32 create2_salt
        evmc_address code_address

    ctypedef struct evmc_tx_context:
        evmc_uint256be tx_gas_price
        evmc_address tx_origin
        evmc_address block_coinbase
        int64_t block_number
        int64_t block_timestamp
        int64_t block_gas_limit
        evmc_uint256be block_prev_randao
        evmc_uint256be chain_id
        evmc_uint256be block_base_fee

    ctypedef struct evmc_host_context:
        pass

    ctypedef evmc_tx_context (*evmc_get_tx_context_fn)(evmc_host_context* context)

    ctypedef evmc_bytes32 (*evmc_get_block_hash_fn)(evmc_host_context* context, int64_t number);

    cpdef enum evmc_status_code:
        EVMC_SUCCESS
        EVMC_FAILURE
        EVMC_REVERT
        EVMC_OUT_OF_GAS
        EVMC_INVALID_INSTRUCTION
        EVMC_UNDEFINED_INSTRUCTION
        EVMC_STACK_OVERFLOW
        EVMC_STACK_UNDERFLOW
        EVMC_BAD_JUMP_DESTINATION
        EVMC_INVALID_MEMORY_ACCESS
        EVMC_CALL_DEPTH_EXCEEDED 
        EVMC_STATIC_MODE_VIOLATION 
        EVMC_PRECOMPILE_FAILURE 
        EVMC_CONTRACT_VALIDATION_FAILURE 
        EVMC_ARGUMENT_OUT_OF_RANGE 
        EVMC_WASM_UNREACHABLE_INSTRUCTION 
        EVMC_WASM_TRAP 
        EVMC_INSUFFICIENT_BALANCE 
        EVMC_INTERNAL_ERROR 
        EVMC_REJECTED 
        EVMC_OUT_OF_MEMORY

    ctypedef void (*evmc_release_result_fn)(evmc_result* result)

    ctypedef struct evmc_result:
        evmc_status_code status_code
        int64_t gas_left
        uint8_t* output_data
        size_t output_size
        evmc_release_result_fn release
        evmc_address create_address

    ctypedef libcpp.bool (*evmc_account_exists_fn)(evmc_host_context* context,
                                             evmc_address* address)

    ctypedef evmc_bytes32 (*evmc_get_storage_fn)(evmc_host_context* context,
                                            evmc_address* address,
                                            evmc_bytes32* key)
    cpdef enum evmc_storage_status:
        EVMC_STORAGE_ASSIGNED
        EVMC_STORAGE_ADDED
        EVMC_STORAGE_DELETED
        EVMC_STORAGE_MODIFIED
        EVMC_STORAGE_DELETED_ADDED
        EVMC_STORAGE_MODIFIED_DELETED
        EVMC_STORAGE_ADDED_DELETED
        EVMC_STORAGE_MODIFIED_RESTORED


    ctypedef evmc_storage_status (*evmc_set_storage_fn)(evmc_host_context* context,
                                                       evmc_address* address,
                                                       evmc_bytes32* key,
                                                       evmc_bytes32* value)

    ctypedef evmc_uint256be (*evmc_get_balance_fn)(evmc_host_context* context,
                                                   evmc_address* address)

    ctypedef size_t (*evmc_get_code_size_fn)(evmc_host_context* context,
                                             evmc_address* address)

    ctypedef evmc_bytes32 (*evmc_get_code_hash_fn)(evmc_host_context* context,
                                                   evmc_address* address)

    ctypedef size_t (*evmc_copy_code_fn)(evmc_host_context* context,
                                         evmc_address* address,
                                         size_t code_offset,
                                         uint8_t* buffer_data,
                                         size_t buffer_size)

    ctypedef bool (*evmc_selfdestruct_fn)(evmc_host_context* context,
                                          evmc_address* address,
                                          evmc_address* beneficiary)

    ctypedef void (*evmc_emit_log_fn)(evmc_host_context* context,
                                 evmc_address* address,
                                 uint8_t* data,
                                 size_t data_size,
                                 evmc_bytes32 topics[],
                                 size_t topics_count)

    cpdef enum evmc_access_status:
        EVMC_ACCESS_COLD
        EVMC_ACCESS_WARM

    ctypedef evmc_access_status (*evmc_access_account_fn)(evmc_host_context* context,
                                                          evmc_address* address)

    ctypedef evmc_access_status (*evmc_access_storage_fn)(evmc_host_context* context,
                                                          evmc_address* address,
                                                          evmc_bytes32* key)

    ctypedef evmc_result (*evmc_call_fn)(evmc_host_context* context,
                                         evmc_message* msg)

    ctypedef struct evmc_host_interface:
        evmc_account_exists_fn account_exists
        evmc_get_storage_fn get_storage
        evmc_set_storage_fn set_storage
        evmc_get_balance_fn get_balance
        evmc_get_code_size_fn get_code_size
        evmc_get_code_hash_fn get_code_hash
        evmc_copy_code_fn copy_code
        evmc_selfdestruct_fn selfdestruct
        evmc_call_fn call
        evmc_get_tx_context_fn get_tx_context
        evmc_get_block_hash_fn get_block_hash
        evmc_emit_log_fn emit_log
        evmc_access_account_fn access_account
        evmc_access_storage_fn access_storage

    ctypedef void (*evmc_destroy_fn)(evmc_vm* vm)

    cpdef enum evmc_set_option_result:
        EVMC_SET_OPTION_SUCCESS
        EVMC_SET_OPTION_INVALID_NAME
        EVMC_SET_OPTION_INVALID_VALUE

    ctypedef evmc_set_option_result (*evmc_set_option_fn)(evmc_vm* vm,
                                                          char* name,
                                                          char* value);

    cpdef enum evmc_revision:
        EVMC_FRONTIER
        EVMC_HOMESTEAD
        EVMC_TANGERINE_WHISTLE
        EVMC_SPURIOUS_DRAGON
        EVMC_BYZANTIUM
        EVMC_CONSTANTINOPLE
        EVMC_PETERSBURG
        EVMC_ISTANBUL
        EVMC_BERLIN
        EVMC_MAX_REVISION

    ctypedef evmc_result (*evmc_execute_fn)(evmc_vm* vm,
                                            evmc_host_interface* host,
                                            evmc_host_context* context,
                                            evmc_revision rev,
                                            evmc_message* msg,
                                            uint8_t* code,
                                            size_t code_size) nogil

    cpdef enum evmc_capabilities:
        EVMC_CAPABILITY_EVM1
        EVMC_CAPABILITY_EWASM
        EVMC_CAPABILITY_PRECOMPILES

    ctypedef uint32_t evmc_capabilities_flagset

    ctypedef evmc_capabilities_flagset (*evmc_get_capabilities_fn)(evmc_vm* vm)

    ctypedef struct evmc_vm:
        int abi_version
        char *name
        char *version
        evmc_destroy_fn destroy
        evmc_execute_fn execute
        evmc_get_capabilities_fn get_capabilities
        evmc_set_option_fn set_option