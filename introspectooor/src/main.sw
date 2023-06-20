contract;

use introspection_library::{get_metadata, ContractMetadataHeader};

abi Introspectooor {
    fn read_metadata(target: ContractId) -> ContractMetadataHeader;
}

enum Errors {
    TestFailed: (),
}

impl Introspectooor for Contract {
    fn read_metadata(target: ContractId) -> ContractMetadataHeader {
        let metadata = get_metadata(target).unwrap();
        require(metadata.has_function(0x2151bd4bu32) == true, Errors::TestFailed);
        require(metadata.has_function(0xb3e6aa95u32) == true, Errors::TestFailed);
        require(metadata.has_function(0x1151bd11u32) == false, Errors::TestFailed);
        metadata.header
    }
}
