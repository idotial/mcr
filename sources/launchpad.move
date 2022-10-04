module mcr::launchpad {
    use std::signer;
    use std::error;

    use aptos_framework::account;
    use aptos_framework::coin::{Coin, zero};
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_std::event::{Self, EventHandle};

    /// Account hasn't registered `CoinStore` for `CoinType`
    const ELAUNCHPAD_STORE_ALREADY_PUBLISHED: u64 = 6;

    /// Account hasn't registered `CoinStore` for `CoinType`
    const ELAUNCHPAD_NOT_PUBLISHED: u64 = 5;

    /// Account hasn't registered `CoinStore` for `CoinType`
    const ELAUNCHPAD_ALREADY_PUBLISHED: u64 = 6;

    struct LaunchpadStore has key {
        create_events: EventHandle<CreateEvent>,
    }

    struct CreateEvent has drop, store {
        addr: address,
    }

    struct Launchpad<phantom CoinType> has key {
        coin: Coin<CoinType>,
        raised_aptos: Coin<AptosCoin>,
        soft_cap: u64,
        hard_cap: u64,
        start_timestamp_secs: u64,
        end_timestamp_secs: u64,
    }

     public entry fun init(account: &signer) {
        let account_addr = signer::address_of(account);
        assert!(
            !exists<LaunchpadStore>(account_addr),
            error::not_found(ELAUNCHPAD_STORE_ALREADY_PUBLISHED),
        );
        move_to(account, LaunchpadStore{
                    create_events: account::new_event_handle<CreateEvent>(account),
                });
    }

    public entry fun create<CoinType>(account: &signer, coin: Coin<CoinType>, soft_cap: u64, hard_cap:u64, start_timestamp_secs: u64, end_timestamp_secs: u64)
    acquires LaunchpadStore {
        let account_addr = signer::address_of(account);
        assert!(
            !is_registered<CoinType>(account_addr),
            error::not_found(ELAUNCHPAD_ALREADY_PUBLISHED),
        );

        let launchpad_store = borrow_global_mut<LaunchpadStore>(account_addr);

        event::emit_event<CreateEvent>(
            &mut launchpad_store.create_events,
            CreateEvent { addr: account_addr },
        );

        move_to(account, Launchpad<CoinType>{
                    coin,
                    raised_aptos: zero<AptosCoin>(),
                    soft_cap,
                    hard_cap,
                    start_timestamp_secs,
                    end_timestamp_secs
                });
    }

    public fun is_registered<CoinType>(owner: address): bool {
         exists<Launchpad<CoinType>>(owner)
    }

    public entry fun get_launchpad<CoinType>(addr: address): u64 acquires Launchpad {
        borrow_global<Launchpad<CoinType>>(addr).hard_cap
    }

}
