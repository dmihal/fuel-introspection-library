contract;

abi MyContract {
    fn test_function() -> bool;
    fn test_function2() -> bool;
}

impl MyContract for Contract {
    fn test_function() -> bool {
        true
    }

    fn test_function2() -> bool {
        true
    }
}
