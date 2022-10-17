#[test_only]
module mcr::launchpad_tests {
    use std::signer;
    use std::unit_test;
    use std::vector;
    use mcr::launchpad;
    //use mcr::sun_coin;
    use mcr::sun_coin::SunCoin;

    fun get_account(): signer {
        vector::pop_back(&mut unit_test::create_signers_for_testing(1))
    }

    #[test(account=@0x9c329fda104a2a0bcfac8603c458ebde00faed4307cc1bfd388f202cef3a0034)]
    public entry fun test_deploy_coin(account: &signer ) {
        aptos_framework::managed_coin::initialize<SunCoin>(
            account,
            b"Sun Coin",
            b"Sun",
            6,
            false,
        );
    }

    #[test(account=@0x9c329fda104a2a0bcfac8603c458ebde00faed4307cc1bfd388f202cef3a0034)]
    public entry fun test_init_create(account: &signer ) {
        let addr = signer::address_of(account);
        aptos_framework::account::create_account_for_test(addr);

        aptos_framework::managed_coin::register<SunCoin>(account);
        let amount:u64 = 10000;
        aptos_framework::managed_coin::mint<SunCoin>(account,addr,amount);
        
        launchpad::init(account);
        launchpad::create<SunCoin>(account,1000,200,300,1665483530,1665583530,1,1000,1,0);

        let bob = get_account();
        launchpad::buy<SunCoin>(&bob,addr,1000)
    }

}
