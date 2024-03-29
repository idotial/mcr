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

    const ELAUNCHPAD_STORE_ALREADY_PUBLISHED: u64 = 5;
    const ELAUNCHPAD_NOT_PUBLISHED: u64 = 6;
    const ELAUNCHPAD_ALREADY_PUBLISHED: u64 = 7;
    const ELAUNCHPAD_NOT_START: u64 = 8;
    const ELAUNCHPAD_ALREADY_END: u64 = 9;
    const ELAUNCHPAD_NOT_END: u64 = 10;
    const EBUY_AMOUNT_TOO_SMALL: u64 = 11;
    const ELAUNCHPAD_SOFT_CAP_TOO_LOW: u64 = 12;
    const ELAUNCHPAD_FULL: u64 = 13;

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
        total: u64,
        raised_aptos: Coin<AptosCoin>,
        raised_amount: u64,
        soft_cap: u64,
        hard_cap: u64,
        start_timestamp_secs: u64,
        end_timestamp_secs: u64,
        
        usr_minum_amount: u64,
        usr_hard_cap: u64,
        token_sell_rate: u64,
        fee_type: u8,
    }

    struct Buy<phantom CoinType> has key, drop {
        launchpad_owner: address,
        amount: u64,
    }

    // init resource account to store launchpad events, must call once before using other feature
    public entry fun init(account: &signer) {
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

    /**
    * function discription
    *
    * @param account: lauchpad creator
    * @param amount: ido token amount, will distribute to paticipants
    * @param soft_cap: soft cap for this launchpad, must exceed this limit to make this launchpad succeess
    * @param hard_cap: hard cap for this launchpad, will not accept new fund when met this limit
    * @param start_timestamp_secs: the time when this launchpad start to accept fund
    * @param end_timestamp_secs: the time when this launchpad end, will not accept new fund after this
    * @param usr_minum_amount: minimum aptos required to paticipate in this launchpad for a user
    * @param usr_hard_cap: maximum aptos accepted in this launchpad for a user
    * @param token_sell_rate: launchpad price, aptos / token
    * @param fee_type: fee type
    */
    public entry fun create<CoinType>(account: &signer, amount: u64, soft_cap: u64, hard_cap:u64, start_timestamp_secs: u64, end_timestamp_secs: u64,usr_minum_amount: u64,usr_hard_cap: u64,token_sell_rate: u64,fee_type: u8 )
    acquires LaunchpadStore, StoreAccount, StoreAccountEvent {
        let account_addr = signer::address_of(account);
        assert!(
            !is_registered<CoinType>(account_addr),
            error::invalid_state(ELAUNCHPAD_ALREADY_PUBLISHED),
        );

        assert!(
            soft_cap * token_sell_rate >= amount,
            error::invalid_state(ELAUNCHPAD_SOFT_CAP_TOO_LOW),
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
                    total: amount,
                    raised_aptos: zero<AptosCoin>(),
                    raised_amount: 0,
                    soft_cap,
                    hard_cap,
                    start_timestamp_secs,
                    end_timestamp_secs,
                    usr_minum_amount,
                    usr_hard_cap,
                    token_sell_rate,
                    fee_type
                });
    }

    public entry fun buy<CoinType>(account: &signer, owner: address, amount: u64) acquires Launchpad {
        assert!(
            exists<Launchpad<CoinType>>(owner),
            error::not_found(ELAUNCHPAD_NOT_PUBLISHED),
        );
        let account_addr = signer::address_of(account);
        assert!(
            !exists<Buy<CoinType>>(account_addr),
            error::not_found(EBUYED),
        );
        let launchpad = borrow_global_mut<Launchpad<CoinType>>(owner);

        assert!(
            launchpad.start_timestamp_secs < timestamp::now_seconds(),
            error::invalid_state(ELAUNCHPAD_NOT_START),
        );
        assert!(
            launchpad.end_timestamp_secs > timestamp::now_seconds(),
            error::invalid_state(ELAUNCHPAD_ALREADY_END),
        );

        assert!(
            launchpad.raised_amount < launchpad.hard_cap,
            error::invalid_state(ELAUNCHPAD_FULL),
        );

        //usr hard cap check
        assert!(amount >= launchpad.usr_minum_amount,error::invalid_state(EBUY_AMOUNT_TOO_SMALL));
        let actual_amount:u64 = amount;
        if (amount > launchpad.usr_hard_cap) {
            actual_amount = launchpad.usr_hard_cap;
        };

        if (launchpad.raised_amount + actual_amount > launchpad.hard_cap) {
            actual_amount = launchpad.hard_cap - launchpad.raised_amount;
        };

        launchpad.raised_amount = launchpad.raised_amount + actual_amount;

        let deposit_coin = coin::withdraw<AptosCoin>(account, actual_amount);
        coin::merge(&mut launchpad.raised_aptos, deposit_coin);

        move_to(account, Buy<CoinType>{
                    launchpad_owner: owner,
                    amount: actual_amount,
                });

    }

    // user claim after ido end, if success user should get the ido token, otherwise user get back his aptos
    public entry fun claim<CoinType>(account: &signer, owner: address) acquires Launchpad, Buy {
        assert!(
            exists<Launchpad<CoinType>>(owner),
            error::not_found(ELAUNCHPAD_NOT_PUBLISHED),
        );
        let account_addr = signer::address_of(account);
        assert!(
            exists<Buy<CoinType>>(account_addr),
            error::not_found(ELAUNCHPAD_NOT_JOIN),
        );
        
        let launchpad = borrow_global_mut<Launchpad<CoinType>>(owner);
        assert!(
            launchpad.end_timestamp_secs < timestamp::now_seconds(),
            error::invalid_state(ELAUNCHPAD_NOT_END),
        );

        let ticket = move_from<Buy<CoinType>>(account_addr);

        if (launchpad.raised_amount > launchpad.soft_cap && launchpad.raised_amount <= launchpad.hard_cap) {
            //calculate token amount claimed when not excess funds 
            let claimed_amount:u64 = ticket.amount * launchpad.total / launchpad.raised_amount;
            let claiming = coin::extract(&mut launchpad.coin, claimed_amount); //change the value of claiming token
            coin::deposit(account_addr, claiming);
            // refund
            if (claimed_amount / launchpad.token_sell_rate < ticket.amount) {
                let refund_aptos = ticket.amount - claimed_amount / launchpad.token_sell_rate;
                let refund =coin::extract(&mut launchpad.raised_aptos,refund_aptos);  
                coin::deposit(account_addr, refund); 
            };
            let Buy {launchpad_owner: _launchpad_owner, amount: _amount} = ticket;
        } else {
            let claiming = coin::extract(&mut launchpad.raised_aptos, ticket.amount); //change the value of claiming token
            coin::deposit(account_addr, claiming);
            let Buy {launchpad_owner: _launchpad_owner, amount: _amount} = ticket;
        };
        
    }

    // launchpad creator settle luanchpad, if success he should get the raised fund(aptos)
    public entry fun settle<CoinType>(account: &signer) acquires Launchpad {
        let account_addr = signer::address_of(account);
        assert!(
            exists<Launchpad<CoinType>>(account_addr),
            error::not_found(ELAUNCHPAD_NOT_PUBLISHED),
        );
        let launchpad = borrow_global_mut<Launchpad<CoinType>>(account_addr);
        assert!(
            launchpad.end_timestamp_secs < timestamp::now_seconds(),
            error::invalid_state(ELAUNCHPAD_NOT_END),
        );

        if (launchpad.raised_amount > launchpad.soft_cap) {
            let claiming = coin::extract_all(&mut launchpad.raised_aptos); //extract all aptos token
            coin::deposit(account_addr, claiming);
        } else {
            let claiming = coin::extract_all(&mut launchpad.coin); //change the value of claiming token
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
