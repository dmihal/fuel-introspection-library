contract;

use introspection_library::{get_metadata, ContractMetadata};

abi Introspectooor {
    fn read_metadata(target: ContractId) -> ContractMetadata;
}

impl Introspectooor for Contract {
    fn read_metadata(target: ContractId) -> ContractMetadata {
        get_metadata(target)
    }
}
