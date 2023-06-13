use std::fs::OpenOptions;
use std::io::{Seek, Write};

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
    let number: i64 = 1234567890;

    // Write the 64-bit integer to the file
    file.write_all(&number.to_le_bytes())
        .expect("Failed to write to file");

    println!("Wrote {} to file", number);
}
