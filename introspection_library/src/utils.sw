library;

use std::{
  alloc::alloc_bytes,
  bytes::Bytes,
};

pub fn code_size(target: ContractId) -> u64 {
    asm(size, id: target.value) {
        csiz size id;
        size: u64
    }
}

pub fn code_copy(target: ContractId, start: u64, length: u64) -> Bytes {
    let dst = alloc_bytes(length);
    let slice = asm(dst: dst, start: start, len: length, id: target.value, ptr: (dst, length)) {
        ccp dst id start len;
        ptr: raw_slice
    };
    Bytes::from_raw_slice(slice)
}

pub fn log_bytes(bytes: Bytes) {
    asm(ptr: bytes.buf.ptr(), bytes: bytes.len()) {
        logd zero zero ptr bytes; // Log the next `bytes` number of bytes starting from `ptr`
    };
}

pub fn log_memory(ptr: raw_ptr, size: u64) {
    asm(ptr: ptr, bytes: size) {
        logd zero zero ptr bytes; // Log the next `bytes` number of bytes starting from `ptr`
    };
}

pub fn read_u32(ptr: raw_ptr) -> u64 {
    let result = asm(res, ptr: ptr) {
        lw res ptr i0;
        res: u32
    };
    (result >> 32) & 0xffffffffu32
}

pub fn read_u64(ptr: raw_ptr) -> u64 {
    asm(res, ptr: ptr) {
        lw res ptr i0;
        res: u64
    }
}

pub fn read_u8(ptr: raw_ptr) -> u8 {
    asm(res, ptr: ptr) {
        lb res ptr i0;
        res: u8
    }
}