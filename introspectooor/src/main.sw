contract;

use introspection_library::{get_metadata, ContractMetadata};

abi Introspectooor {
    fn read_metadata(target: ContractId) -> ContractMetadata;
}

impl Introspectooor for Contract {
    fn read_metadata(target: ContractId) -> ContractMetadata {
        let metadata = get_metadata(target).unwrap();
        log(metadata.has_function(0x2151bd4bu32));
        log(metadata.has_function(0xb3e6aa95u32));
        log(metadata.has_function(0x1151bd11u32));
        metadata
    }
}
