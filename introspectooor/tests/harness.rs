use fuels::{prelude::*};
use fuels::tx::Receipt;

// Load abi from json
abigen!(
    Contract(
        name = "Introspectooor",
        abi = "introspectooor/out/debug/introspectooor-abi.json"
    ),
    Contract(
        name = "ExampleContract",
        abi = "example_contract/out/debug/example_contract-abi.json"
    )
);

async fn get_wallet() -> WalletUnlocked {
    // Launch a local network and deploy the contract
    let mut wallets = launch_custom_provider_and_get_wallets(
        WalletsConfig::new(
            Some(1),             /* Single wallet */
            Some(1),             /* Single coin (UTXO) */
            Some(1_000_000_000), /* Amount per coin */
        ),
        None,
        None,
    )
    .await;
    let wallet = wallets.pop().unwrap();
    wallet
}

async fn deploy_contract(wallet: &WalletUnlocked) -> Introspectooor<WalletUnlocked> {
    let id = Contract::load_from(
        "./out/debug/introspectooor.bin",
        LoadConfiguration::default(),
    )
    .unwrap()
    .deploy(wallet, TxParameters::default())
    .await
    .unwrap();

    let instance = Introspectooor::new(id.clone(), wallet.clone());

    instance
}

async fn deploy_target(wallet: &WalletUnlocked) -> ExampleContract<WalletUnlocked> {
    let id = Contract::load_from(
        "../example_contract/out/debug/example_contract.bin",
        LoadConfiguration::default(),
    )
    .unwrap()
    .deploy(wallet, TxParameters::default())
    .await
    .unwrap();

    let instance = ExampleContract::new(id.clone(), wallet.clone());

    instance
}

#[tokio::test]
async fn can_get_contract_id() {
    let wallet = get_wallet().await;
    
    let target = deploy_target(&wallet).await;
    let introspectooor = deploy_contract(&wallet).await;

    let metadata = introspectooor
        .methods()
        .read_metadata(target.id().into())
        .set_contracts(&[&target])
        .call()
        .await
        .unwrap();

    let contract = wallet.provider()
        .unwrap()
        .client
        .contract(target.id().hash().to_string().as_str())
        .await
        .unwrap()
        .unwrap();
    let bytecode = contract.bytecode.0.0;

    println!("bytecode: {:?} ({})", bytecode, bytecode.len());

    for receipt in metadata.receipts {
        // println!("receipt: {:?}", receipt);
        match receipt {
            Receipt::Log { ra, .. } => println!("{} ({:x})", ra, ra),
            Receipt::LogData { data, .. } => println!("{:?}", data),
            _ => (),
        };
    }
    println!("metadata: {:?}", metadata.value);
}
