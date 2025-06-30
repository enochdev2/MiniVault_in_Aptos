module minivault::vault {
    use std::signer;
    use aptos_framework::coin::{Self, Coin};

    #[test_only]
    use aptos_framework::account;
    #[test_only]
    use minivault::fake_coin;
    #[test_only]
    use std::string;

    const ERR_NOT_ADMIN: u64 = 0;
    const ERR_FUSE_EXISTS: u64 = 1;
    const ERR_FUSE_NOT_EXISTS: u64 = 2;
    const ERR_VAULT_EXISTS: u64 = 3;
    const ERR_VAULT_NOT_EXISTS: u64 = 4;
    const ERR_INSUFFICIENT_ACCOUNT_BALANCE: u64 = 5;
    const ERR_INSUFFICIENT_VAULT_BALANCE: u64 = 6;
    const ERR_VAULT_PASUED: u64 = 7;

    struct Fuse<phantom CoinType> has key {
        paused: bool
    }

    struct Vault<phantom CoinType> has key {
        coin: Coin<CoinType>
    }

    public entry fun init_fuse<CoinType>(minivault: &signer) {
        assert!(signer::address_of(minivault) == @minivault, ERR_NOT_ADMIN);
        move_to(minivault, Fuse<CoinType> {
            paused: false,
        });
    }

    public fun pause<CoinType>(minivault: &signer) acquires Fuse {
        update_paused<CoinType>(minivault, true)
    }

    public fun unpause<CoinType>(minivault: &signer) acquires Fuse {
        update_paused<CoinType>(minivault, false)
    }

    fun update_paused<CoinType>(minivault: &signer, paused: bool) acquires Fuse {
        assert!(signer::address_of(minivault) == @minivault, ERR_NOT_ADMIN);
        assert!(exists_fuse<CoinType>(), ERR_FUSE_NOT_EXISTS);
        borrow_global_mut<Fuse<CoinType>>(@minivault).paused = paused;
    }

    fun pausd<CoinType>(): bool acquires Fuse {
        borrow_global<Fuse<CoinType>>(@minivault).paused
    }

    public fun exists_fuse<CoinType>(): bool {
        exists<Fuse<CoinType>>(@minivault)
    }

    public entry fun init_vault<CoinType>(account: &signer) {
        let account_addr = signer::address_of(account);
        if (!coin::is_account_registered<CoinType>(account_addr)) {
            coin::register<CoinType>(account);
        };
        assert!(!exists_vault<CoinType>(account_addr), ERR_VAULT_EXISTS);
        move_to(account, Vault<CoinType> {
            coin: coin::zero(),
        });
    }

    public entry fun deposit<CoinType>(account: &signer, vault_address: address,  amount: u64) acquires Vault, Fuse {
        assert!(exists_vault<CoinType>(vault_address), ERR_VAULT_NOT_EXISTS);
        let account_balance = coin::balance<CoinType>(signer::address_of(account));
        assert!(account_balance >= amount, ERR_INSUFFICIENT_ACCOUNT_BALANCE);
        let coin = coin::withdraw<CoinType>(account, amount);
        deposit_internal<CoinType>(vault_address, coin);
    }

    public entry fun withdraw<CoinType>(account: &signer, vault_address: address,  amount: u64) acquires Vault, Fuse {
        assert!(exists_vault<CoinType>(vault_address), ERR_VAULT_NOT_EXISTS);
        let coin = withdraw_internal<CoinType>(vault_address, amount);
        coin::deposit(signer::address_of(account), coin);
    }

    fun deposit_internal<CoinType>(vault_address: address, coin: Coin<CoinType>) acquires Vault, Fuse {
        assert!(!pausd<CoinType>(), ERR_VAULT_PASUED);
        assert!(exists_vault<CoinType>(vault_address), ERR_VAULT_NOT_EXISTS);
        coin::merge(&mut borrow_global_mut<Vault<CoinType>>(vault_address).coin, coin);
    }

    fun withdraw_internal<CoinType>(vault_address: address, amount: u64): Coin<CoinType> acquires Vault, Fuse {
        assert!(!pausd<CoinType>(), ERR_VAULT_PASUED);
        assert!(exists_vault<CoinType>(vault_address), ERR_VAULT_NOT_EXISTS);
        assert!(vault_balance<CoinType>(vault_address) >= amount, ERR_INSUFFICIENT_VAULT_BALANCE);
       return coin::extract(&mut borrow_global_mut<Vault<CoinType>>(vault_address).coin, amount)

    }

    public fun exists_vault<CoinType>(vault_address: address): bool {
        exists<Vault<CoinType>>(vault_address)
    }

    public fun vault_balance<CoinType>(vault_address: address): u64 acquires Vault {
        coin::value(&borrow_global<Vault<CoinType>>(vault_address).coin)
    }

    #[test_only]
    struct FakeCoin {}

    #[test(admin = @0x1, user = @0xa)]
    #[expected_failure(abort_code = 0)]
    public fun only_admin_can_pause(admin: &signer, user: &signer) acquires Fuse {
        setup_account(admin, user);
        init_fuse<FakeCoin>(admin);
        init_vault<FakeCoin>(user);

        pause<FakeCoin>(user);
    }

    // #[test(admin = @0x1, user = @0xa)]
    // #[expected_failure(abort_code = 7)]
    // public fun op_fail_when_paused(admin: &signer, user: &signer) acquires Vault, Fuse {
    //     setup_account(admin, user);
    //     init_fuse<FakeCoin>(admin);
    //     init_vault<FakeCoin>(user);

    //     pause<FakeCoin>(admin);
    //     deposit<FakeCoin>(user, signer::address_of(user), 10000);

    // }

    // #[test(admin = @0x1, user = @0xa)]
    // public fun end_to_end(admin: &signer, user: &signer) acquires Vault, Fuse {
    //     // init
    //     setup_account(admin, user);
    //     let vault_address = signer::address_of(user);  // Using user's address as vault address for this test
    //     init_fuse<FakeCoin>(admin);
    //     init_vault<FakeCoin>(user);

    //     // deposit
    //     deposit<FakeCoin>(user, vault_address, 6000);
    //     deposit<FakeCoin>(user, signer::address_of(user), 10000);

    //     assert!(vault_balance<FakeCoin>(vault_address) == 6000, 0);
    //     assert!(coin::balance<FakeCoin>(vault_address) == 4000, 0);

    //     // withdraw
    //     withdraw<FakeCoin>(user, signer::address_of(user), 5000);

    //     assert!(vault_balance<FakeCoin>(vault_address) == 1000, 0);
    //     assert!(coin::balance<FakeCoin>(vault_address) == 9000, 0);
    // }

    #[test_only]
    fun setup_account(admin: &signer, user: &signer) {
        // init accounts and issue 10000 FakeCoin to user
        account::create_account_for_test(signer::address_of(admin));
        account::create_account_for_test(signer::address_of(user));
        fake_coin::initialize_account_with_coin(admin, user, b"Fake Coin", b"FC", 8, 10000);
fake_coin::initialize_account_with_coin(admin, user, b"Fake Coin", b"FC", 8, 10000);

        // fake_coin::initialize_account_with_coin(admin, user, string::utf8(b"Fake Coin"), string::utf8(b"FC"), 8, 10000);
    }
}
