use std::fs::OpenOptions;
use std::io::{Seek, Write};
use std::vec;
use serde::{Serialize};
use bincode::{serialize, Error};

const SPECIAL_BYTE: u8 = 42;

#[derive(Serialize)]
struct ContractMetadata {
    version: u8,
    contract_type: u8,

    b2: u8,
    b3: u8,
    b4: u8,
    b5: u8,
    b6: u8,
    b7: u8,
}

#[tokio::main]
async fn main() {
    // Open the file in append mode
    let mut file = OpenOptions::new()
        .write(true)
        .append(true)
        .open("../example_contract/out/debug/example_contract.bin")
        .expect("Failed to open file");

    // Seek to the end of the file
    file.seek(std::io::SeekFrom::End(0))
        .expect("Failed to seek to the end of the file");

    // Create a 64-bit integer to append
    let metadata = ContractMetadata {
        version: 1,
        contract_type: 2,
        b2: 3,
        b3: 4,
        b4: 5,
        b5: 6,
        b6: 7,
        b7: 8,
    };
    let encoded = serialize(&metadata).unwrap();

    let mut extension_data: Vec<u8> = vec![SPECIAL_BYTE];
    extension_data.extend_from_slice(&encoded);
    extension_data.extend_from_slice(&(encoded.len() as u64).to_be_bytes());
    println!("extension_data: {:?}", extension_data);

    // Write the 64-bit integer to the file
    file.write_all(&extension_data)
        .expect("Failed to write to file");

    println!("Wrote {} bytes to file", encoded.len());
}
