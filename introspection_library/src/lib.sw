library;

use std::{
  alloc::alloc_bytes,
  bytes::Bytes,
};

pub struct ContractMetadata {
  version: u8,
  contract_type: u8,
  size: u64,
}

fn code_size(target: ContractId) -> u64 {
    asm(size, id: target.value) {
        csiz size id;
        size: u64
    }
}

fn code_copy(target: ContractId, start: u64, length: u64) -> Bytes {
    let dst = alloc_bytes(length);
    let slice = asm(dst: dst, start: start, len: length, id: target.value, ptr: (dst, length)) {
        ccp dst id start len;
        ptr: raw_slice
    };
    Bytes::from_raw_slice(slice)
}

fn log_bytes(bytes: Bytes) {
    asm(ptr: bytes.buf.ptr(), bytes: bytes.len()) {
        logd zero zero ptr bytes; // Log the next `bytes` number of bytes starting from `ptr`
    };
}


pub fn get_metadata(id: ContractId) -> ContractMetadata {
    let size = code_size(id);
    let bytes = code_copy(id, 0, size);
    log_bytes(bytes);

    let len = asm(res, ptr: bytes.buf.ptr().add_uint_offset(size - 8)) {
        lw res ptr i0;
        res: u64
    };
    log(len);
  
    ContractMetadata {
        version: 0u8,
        contract_type: 0u8,
        size: len,
    }
}
