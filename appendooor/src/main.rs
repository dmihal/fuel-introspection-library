use std::io::{Seek, Write};
use std::{fs, vec};
use std::collections::HashMap;
use fuels::core::function_selector::resolve_fn_selector;
use fuels::prelude::Error;
use fuels::types::ByteArray;
use fuels::types::param_types::ParamType;
use serde::{Serialize};
use fuel_abi_types::program_abi::{ProgramABI, ABIFunction, TypeDeclaration};
use bincode::{serialize};

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
    let mut file = fs::OpenOptions::new()
        .write(true)
        .append(true)
        .open("../example_contract/out/debug/example_contract.bin")
        .expect("Failed to open file");

    // Seek to the end of the file
    file.seek(std::io::SeekFrom::End(0))
        .expect("Failed to seek to the end of the file");

    let abi_path = "../example_contract/out/debug/example_contract-abi.json";
    println!("Reading ABI from {}", abi_path);
    let mut selectors = get_selectors(abi_path).unwrap();
    selectors.sort_by(|a, b| a.cmp(b));

    for selector in &selectors {
        let int = u64::from_be_bytes(selector.clone());
        println!("selector: {:x} ({})", int, int);
    }

    println!("selectors: {:?}", selectors);

    let flattened_selectors: Vec<u8> = selectors
        .iter()
        .flat_map(|array| array[4..].iter())
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

fn get_selectors(abi_path: &str) -> Result<Vec<ByteArray>, Error> {
    let abi_file_contents = fs::read_to_string(&abi_path)?;

    let abi: ProgramABI = serde_json::from_str(&abi_file_contents)?;

    let type_lookup = abi
        .types
        .into_iter()
        .map(|a_type| (a_type.type_id, a_type))
        .collect::<HashMap<_, _>>();

    let selectors = abi
        .functions
        .into_iter()
        .map(|fun| get_selector(&fun, &type_lookup))
        .collect::<Result<Vec<_>, _>>()?;

    Ok(selectors)
}

fn get_selector(
    a_fun: &ABIFunction,
    type_lookup: &HashMap<usize, TypeDeclaration>,
) -> Result<ByteArray, Error> {
    let name = a_fun.name.clone();
    let inputs = a_fun.clone()
        .inputs
        .into_iter()
        .map(|type_appl| ParamType::try_from_type_application(&type_appl, &type_lookup))
        .collect::<Result<Vec<_>, _>>()?;

    let selector = resolve_fn_selector(&name, &inputs);

    Ok(selector)
}
