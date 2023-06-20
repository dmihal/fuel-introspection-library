use std::fs::OpenOptions;
use std::io::{Seek, Write};
use std::vec;
use fuels::core::function_selector::resolve_fn_selector;
use serde::{Serialize};
use bincode::{serialize, Error};

const SPECIAL_BYTE: u8 = 42;

#[derive(Serialize)]
struct ContractMetadata {
    version: u8,
    contract_type: u8,
    num_functions: u8,

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

    let mut selectors = [
        &resolve_fn_selector("test_function", &[]),
        &resolve_fn_selector("test_function2", &[]),
        &resolve_fn_selector("test_function3", &[]),
    ];
    selectors.sort_by(|a, b| a.cmp(b));

    for selector in &selectors {
        let int = u64::from_be_bytes(*selector.clone());
        println!("selector: {:x} ({})", int, int);
    }

    println!("selectors: {:?}", selectors);
    // let flattened: Vec<u8> = selectors.iter().cloned().flatten().collect();
    let flattened_selectors: Vec<u8> = selectors
        .iter()
        .map(|&arr| &arr[4..])
        .flatten()
        .copied()
        .collect();
    println!("flattened: {:?}", flattened_selectors);

    // Create a 64-bit integer to append
    let metadata = ContractMetadata {
        version: 1,
        contract_type: 2,
        num_functions: selectors.len() as u8,
        b3: 4,
        b4: 5,
        b5: 6,
        b6: 7,
        b7: 8,
    };
    let encoded_header = serialize(&metadata).unwrap();
    let payload = [&encoded_header[..], &flattened_selectors[..]].concat();

    let mut extension_data: Vec<u8> = vec![SPECIAL_BYTE];
    extension_data.extend_from_slice(&payload);
    extension_data.extend_from_slice(&(payload.len() as u64).to_be_bytes());
    println!("extension_data: {:?}", extension_data);

    // Write the 64-bit integer to the file
    file.write_all(&extension_data)
        .expect("Failed to write to file");

    println!("Wrote {} bytes to file", payload.len());
}
