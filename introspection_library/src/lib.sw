library;

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

pub fn get_metadata(id: ContractId) -> ContractMetadata {
  let size = code_size(id);
  
  ContractMetadata {
    version: 0,
    contract_type: 0,
    size: size,
  }
}
