module token::token {
    //uses
    use aptos_framework::managed_coin::{ Self };
    use std::signer::{ Self };
    use token::package_manager::{ Self };

    //structs
    struct Token {}
    struct Setup has key {
        has_done: bool
    }

    //templates
    const TEMPLATE_NAME: vector<u8> = b"USD Tether";
    const TEMPLATE_SYMBOL: vector<u8> = b"USDT";
    const TEMPLATE_DECIMALS: u8 = 6;
    const TEMPLATE_TOTAL_SUPPLY: u64 = 10000000000000000;

    //errors
    const ESENDER_NOT_DEPLOYER : u64 = 0;
    const ESETUP_HAS_DONE : u64 = 1;

    //functions
    fun init_module(resource_sender: &signer) {
        managed_coin::initialize<Token>(
            resource_sender,
            TEMPLATE_NAME,
            TEMPLATE_SYMBOL,
            TEMPLATE_DECIMALS,
            true
        );

        move_to(resource_sender, Setup { has_done: false });
    }

    public(friend) entry fun setup(sender: &signer) acquires Setup {
        let signer = package_manager::get_signer();
        let has_done = &mut borrow_global_mut<Setup>(@token).has_done;

        if (signer::address_of(sender) != @deployer) abort ESENDER_NOT_DEPLOYER;
        if (*has_done) abort ESETUP_HAS_DONE;

        managed_coin::register<Token>(sender);
        managed_coin::mint<Token>(&signer, signer::address_of(sender), TEMPLATE_TOTAL_SUPPLY);

        *has_done = true;
    }

    //tests
    #[test_only]
    public fun initialize_for_test(deployer: &signer, resource_signer: &signer) {
        package_manager::initialize_for_test(deployer, resource_signer);
        init_module(resource_signer);
    }

    #[test_only]
    friend token::token_tests;
}