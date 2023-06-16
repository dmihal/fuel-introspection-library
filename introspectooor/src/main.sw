contract;

use introspection_library::{get_metadata, ContractMetadata};

abi Introspectooor {
    fn read_metadata(target: ContractId) -> ContractMetadata;
}

impl Introspectooor for Contract {
    fn read_metadata(target: ContractId) -> ContractMetadata {
        let metadata = get_metadata(target);
        metadata.unwrap()
    }
}
