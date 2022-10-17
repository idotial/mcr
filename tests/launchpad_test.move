#[test_only]
module mcr::launchpad_tests {
    use std::signer;
    use std::unit_test;
    use std::vector;
    use mcr::launchpad;
    //use mcr::moon_coin;
    use mcr::moon_coin::MoonCoin;
    use aptos_framework::coin;

    fun get_account(): signer {
        vector::pop_back(&mut unit_test::create_signers_for_testing(1))
    }

    #[test(account=@0x9c329fda104a2a0bcfac8603c458ebde00faed4307cc1bfd388f202cef3a0034)]
    public entry fun test_init_create(account: &signer ) {
        let addr = signer::address_of(account);
        aptos_framework::account::create_account_for_test(addr);
        
        launchpad::init(account);
        //moon_coin::init_module(account);
        coin::register<MoonCoin>(account);
        let amount:u64 = 10000;
        aptos_framework::managed_coin::mint<MoonCoin>(addr,amount);
        launchpad::create<MoonCoin>(account,1000,200,300,1665483530,1665583530,1,1000,1,0);
    }

}
