module mcr::launchpad {
    use std::signer;
    use std::error;

    use aptos_framework::account;
    use aptos_framework::coin::{Self, Coin, zero};
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::timestamp;
    use aptos_std::event::{Self, EventHandle};
    use aptos_std::type_info;

    const ELAUNCHPAD_NOT_JOIN: u64 = 3;
    const EBUYED: u64 = 4;

    /// Account hasn't registered `CoinStore` for `CoinType`
    const ELAUNCHPAD_STORE_ALREADY_PUBLISHED: u64 = 6;

    /// Account hasn't registered `CoinStore` for `CoinType`
    const ELAUNCHPAD_NOT_PUBLISHED: u64 = 5;

    /// Account hasn't registered `CoinStore` for `CoinType`
    const ELAUNCHPAD_ALREADY_PUBLISHED: u64 = 6;

    const ELAUNCHPAD_NOT_START: u64 = 7;
    const ELAUNCHPAD_ALREADY_END: u64 = 8;

    // Resource representing a shared account   
    struct StoreAccount has key {
        signer_capability: account::SignerCapability,
    }

    struct StoreAccountEvent has key {
        resource_addr: address,
    }

    struct LaunchpadStore<phantom CoinType> has key {
        create_events: EventHandle<CreateEvent>,
    }

    struct CreateEvent has drop, store {
        addr: address,
    }

    struct Launchpad<phantom CoinType> has key {
        coin: Coin<CoinType>,
        raised_aptos: Coin<AptosCoin>,
        raised_amount: u64,
        soft_cap: u64,
        hard_cap: u64,
        start_timestamp_secs: u64,
        end_timestamp_secs: u64,
    }

    struct Buy<phantom CoinType> has key {
        launchpad_owner: address,
        amount: u64,
    }

    fun init_store_account(account: &signer) {
        let account_addr = signer::address_of(account);
        let type_info = type_info::type_of<StoreAccount>();
        assert!(account_addr == type_info::account_address(&type_info), 0);
        let (resource_signer, resource_signer_cap) = account::create_resource_account(account, x"01");

        move_to(
            &resource_signer,
            StoreAccount {
                signer_capability: resource_signer_cap,
            }
        );

        move_to(account, StoreAccountEvent {
            resource_addr: signer::address_of(&resource_signer)
        });
    }

    fun init_store_if_not_exist<CoinType>(account: &signer) {
        let account_addr = signer::address_of(account);
        if (!exists<LaunchpadStore<CoinType>>(account_addr)) {
            move_to(account, LaunchpadStore<CoinType> {
                create_events: account::new_event_handle<CreateEvent>(account),
            });
        }
    }

    public entry fun create<CoinType>(account: &signer, amount: u64, soft_cap: u64, hard_cap:u64, start_timestamp_secs: u64, end_timestamp_secs: u64)
    acquires LaunchpadStore, StoreAccount, StoreAccountEvent {
        let account_addr = signer::address_of(account);
        assert!(
            !is_registered<CoinType>(account_addr),
            error::not_found(ELAUNCHPAD_ALREADY_PUBLISHED),
        );

        let type_info = type_info::type_of<StoreAccount>();
        let sae = borrow_global<StoreAccountEvent>(type_info::account_address(&type_info));
        let shared_account = borrow_global<StoreAccount>(sae.resource_addr);
        let resource_signer = account::create_signer_with_capability(&shared_account.signer_capability);

        init_store_if_not_exist<CoinType>(&resource_signer);

        let launchpad_store = borrow_global_mut<LaunchpadStore<CoinType>>(sae.resource_addr);

        event::emit_event<CreateEvent>(
            &mut launchpad_store.create_events,
            CreateEvent { addr: account_addr },
        );

        let coin = coin::withdraw<CoinType>(account, amount);

        move_to(account, Launchpad<CoinType>{
                    coin,
                    raised_aptos: zero<AptosCoin>(),
                    raised_amount: 0,
                    soft_cap,
                    hard_cap,
                    start_timestamp_secs,
                    end_timestamp_secs
                });
    }

    public entry fun buy<CoinType>(account: &signer, owner: address, amount: u64) acquires Launchpad {
        assert!(
            !exists<Launchpad<CoinType>>(owner),
            error::not_found(ELAUNCHPAD_NOT_PUBLISHED),
        );
        let account_addr = signer::address_of(account);
        assert!(
            exists<Buy<CoinType>>(account_addr),
            error::not_found(EBUYED),
        );
        let launchpad = borrow_global_mut<Launchpad<CoinType>>(owner);

        assert!(
            launchpad.start_timestamp_secs > timestamp::now_seconds(),
            error::not_found(ELAUNCHPAD_NOT_START),
        );
        assert!(
            launchpad.end_timestamp_secs < timestamp::now_seconds(),
            error::not_found(ELAUNCHPAD_ALREADY_END),
        );

        launchpad.raised_amount = launchpad.raised_amount + amount;

        let deposit_coin = coin::withdraw<AptosCoin>(account, amount);
        coin::merge(&mut launchpad.raised_aptos, deposit_coin);

        move_to(account, Buy<CoinType>{
                    launchpad_owner: owner,
                    amount,
                });

    }

    public entry fun settle<CoinType>(account: &signer, owner: address) acquires Launchpad, Buy {
        assert!(
            !exists<Launchpad<CoinType>>(owner),
            error::not_found(ELAUNCHPAD_NOT_PUBLISHED),
        );
        let account_addr = signer::address_of(account);
        assert!(
            !exists<Buy<CoinType>>(account_addr),
            error::not_found(ELAUNCHPAD_NOT_JOIN),
        );
        let launchpad = borrow_global_mut<Launchpad<CoinType>>(owner);

        let ticket = borrow_global_mut<Buy<CoinType>>(account_addr);

        if (launchpad.raised_amount > launchpad.soft_cap) {
            let claiming = coin::extract(&mut launchpad.coin, 100); //change the value of claiming token
            coin::deposit(account_addr, claiming);
        }

    }

    public fun is_registered<CoinType>(owner: address): bool {
         exists<Launchpad<CoinType>>(owner)
    }

    public entry fun get_launchpad<CoinType>(addr: address): u64 acquires Launchpad {
        borrow_global<Launchpad<CoinType>>(addr).hard_cap
    }

}
