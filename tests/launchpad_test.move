#[test_only]
module mcr::launchpad_tests {
    use std::signer;
    use std::unit_test;
    use std::vector;
    //use aptos_framework::coin::{withdraw, FakeMoney};

    // use mcr::launchpad;

    fun get_account(): signer {
        vector::pop_back(&mut unit_test::create_signers_for_testing(1))
    }

    use mcr::launchpad;

    #[test]
    public entry fun test_init_create() {
        let account = get_account();
        let addr = signer::address_of(&account);
        aptos_framework::account::create_account_for_test(addr);
        
        launchpad::init(&account);
        launchpad::create<0x1::aptos_coin::AptosCoin>(&account,1000,200,300,1665483530,1665583530);
    }

    // #[test]
    // public entry fun can_create_launchpad() {
    //     let account = get_account();
    //     let addr = signer::address_of(&account);
    //    create_fake_money(&account, &account, 1000000);
    //    let coin = withdraw<FakeMoney>(&account, 1000000);
    // }
}
