library;

use std::{
  alloc::alloc_bytes,
  bytes::Bytes,
};

pub struct ContractMetadataCompressed {
  first_8_bytes: u64,
}

impl ContractMetadataCompressed {
    pub fn decompress(self) -> ContractMetadata {
        ContractMetadata {
            version: (self.first_8_bytes >> 56) & 0xff,
            contract_type: (self.first_8_bytes >> 48) & 0xff,
            b2: (self.first_8_bytes >> 40) & 0xff,
            b3: (self.first_8_bytes >> 32) & 0xff,
            b4: (self.first_8_bytes >> 24) & 0xff,
            b5: (self.first_8_bytes >> 16) & 0xff,
            b6: (self.first_8_bytes >> 8) & 0xff,
            b7: self.first_8_bytes & 0xff,
        }
    }
}

pub struct ContractMetadata {
  version: u8,
  contract_type: u8,
  b2: u8,
  b3: u8,
  b4: u8,
  b5: u8,
  b6: u8,
  b7: u8,
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

fn log_memory(ptr: raw_ptr, size: u64) {
    asm(ptr: ptr, bytes: size) {
        logd zero zero ptr bytes; // Log the next `bytes` number of bytes starting from `ptr`
    };
}

fn read_u64(ptr: raw_ptr) -> u64 {
    asm(res, ptr: ptr) {
        lw res ptr i0;
        res: u64
    }
}

fn read_u8(ptr: raw_ptr) -> u8 {
    asm(res, ptr: ptr) {
        lb res ptr i0;
        res: u8
    }
}

fn cast_memory<T>(ptr: raw_ptr) -> T {
    asm(ptr: ptr) {
        ptr: T
    }
}

const SPECIAL_BYTE: u8 = 42;

enum Error {
    InvalidLength: (),
}

pub fn get_metadata(id: ContractId) -> Option<ContractMetadata> {
    let size = code_size(id);
    let bytes = code_copy(id, 0, size);
    log_bytes(bytes);

    let len = read_u64(bytes.buf.ptr().add_uint_offset(size - 8));
    log(len);

    let special_word = read_u8(bytes.buf.ptr().add_uint_offset(size - 9 - len));
    if special_word != SPECIAL_BYTE {
        return None;
    }

    require(len == __size_of::<ContractMetadataCompressed>(), Error::InvalidLength);

    let payload_pointer = bytes.buf.ptr().add_uint_offset(size - 8 - len);
    log_memory(payload_pointer, __size_of::<ContractMetadataCompressed>());
    let compressed_metadata = cast_memory::<ContractMetadataCompressed>(payload_pointer);

    log(compressed_metadata);
    log(compressed_metadata.decompress());

    let metadata = compressed_metadata.decompress();
  
    Some(metadata)
}
