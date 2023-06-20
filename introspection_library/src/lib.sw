library;

use std::{
  alloc::alloc_bytes,
  bytes::Bytes,
};

pub struct ContractMetadata {
    ptr: raw_ptr,
    header: ContractMetadataHeader,
}

impl ContractMetadata {
    fn get_offset_ptr(self, offset: u64) -> raw_ptr {
        self.ptr.add_uint_offset(8 + offset)
    }
}

impl ContractMetadata {
    pub fn from_pointer(ptr: raw_ptr) -> Self {
        let first_8_bytes = ptr.read::<u64>();
        let header = ContractMetadataHeader {
            version: (first_8_bytes >> 56) & 0xff,
            contract_type: (first_8_bytes >> 48) & 0xff,
            num_functions: (first_8_bytes >> 40) & 0xff,
            b3: (first_8_bytes >> 32) & 0xff,
            b4: (first_8_bytes >> 24) & 0xff,
            b5: (first_8_bytes >> 16) & 0xff,
            b6: (first_8_bytes >> 8) & 0xff,
            b7: first_8_bytes & 0xff,
        };
        ContractMetadata {
            ptr,
            header,
        }
    }

    pub fn has_function(self, function_id: u32) -> bool {
        let self_ptr = self.get_offset_ptr(0);

        // Binary search
        let mut low = 0;
        let mut high: u64 = self.header.num_functions;

        while low < high {
            let mid: u64 = (low + high) / 2;
            let current_selector = read_u32(self_ptr.add_uint_offset(mid * 4));

            if current_selector == function_id {
                return true;
            } else if current_selector < function_id {
                low = mid + 1;
            } else {
                high = mid;
            }
        }
        false
    }
}

pub struct ContractMetadataHeader {
  version: u8,
  contract_type: u8,
  num_functions: u8,
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

fn read_u32(ptr: raw_ptr) -> u64 {
    let result = asm(res, ptr: ptr) {
        lw res ptr i0;
        res: u32
    };
    (result >> 32) & 0xffffffffu32
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

const SPECIAL_BYTE: u8 = 42;

pub fn get_metadata(id: ContractId) -> Option<ContractMetadata> {
    let size = code_size(id);
    let bytes = code_copy(id, 0, size);
    log_bytes(bytes);

    let len = read_u64(bytes.buf.ptr().add_uint_offset(size - 8));

    let special_word = read_u8(bytes.buf.ptr().add_uint_offset(size - 9 - len));
    if special_word != SPECIAL_BYTE {
        return None;
    }

    let payload_pointer = bytes.buf.ptr().add_uint_offset(size - 8 - len);

    let metadata = ContractMetadata::from_pointer(payload_pointer);
  
    Some(metadata)
}
