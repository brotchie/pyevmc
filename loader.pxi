cdef extern from "evmc/include/evmc/loader.h":
    cpdef enum evmc_loader_error_code:
        EVMC_LOADER_SUCCESS
        EVMC_LOADER_CANNOT_OPEN
        EVMC_LOADER_SYMBOL_NOT_FOUND
        EVMC_LOADER_INVALID_ARGUMENT
        EVMC_LOADER_VM_CREATION_FAILURE
        EVMC_LOADER_ABI_VERSION_MISMATCH
        EVMC_LOADER_INVALID_OPTION_NAME
        EVMC_LOADER_INVALID_OPTION_VALUE

    cdef evmc_vm* evmc_load_and_create(
            const char* filename,
            evmc_loader_error_code* error_code)

    cdef evmc_vm* evmc_load_and_configure(
            const char* config,
            evmc_loader_error_code* error_code)

    cdef char* evmc_last_error_msg()