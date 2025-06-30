module minivault::fake_coin {
    use std::signer;
    use aptos_framework::coin;
    use aptos_framework::managed_coin;

    struct FakeCoin has store {}

    public fun initialize_account_with_coin(
        admin: &signer,
        user: &signer,
        name: vector<u8>,
        symbol: vector<u8>,
        decimals: u8,
        supply: u64
    ) {
        // Step 1: Initialize the coin (with minting enabled)
        managed_coin::initialize<FakeCoin>(
            admin,
            name,
            symbol,
            decimals,
            true // minting_enabled
        );

        // Step 2: Register both admin and user
        coin::register<FakeCoin>(admin);
        coin::register<FakeCoin>(user);

        // Step 3: Mint the coins to user
        managed_coin::mint<FakeCoin>(admin, signer::address_of(user), supply);

        // Step 4: Optionally destroy mint/burn caps
        managed_coin::destroy_caps<FakeCoin>(admin);
    }
}

// fun initialize_account_with_coin(
//     admin: &signer,
//     user: &signer,
//     name: vector<u8>,
//     symbol: vector<u8>,
//     decimals: u8,
//     supply: u64
// ) {
//     use aptos_framework::coin;
//     use aptos_framework::managed_coin;


//     managed_coin::initialize<FakeCoin>(
//         admin,
//         name,
//         symbol,
//         decimals,
//         true
//     );
//     coin::register<FakeCoin>(admin);
//     coin::register<FakeCoin>(user);

//     managed_coin::mint<FakeCoin>(admin, signer::address_of(user), supply);
//     managed_coin::destroy_caps<FakeCoin>(admin);
// }