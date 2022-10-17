//:!:>moon
module mcr::sun_coin {
    struct SunCoin {}

    fun init_module(sender: &signer) {
        aptos_framework::managed_coin::initialize<SunCoin>(
            sender,
            b"Sun Coin",
            b"Sun",
            6,
            false,
        );
    }
}
//<:!:moon
