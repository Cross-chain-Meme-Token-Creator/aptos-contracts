module token::token {
    //libraries
    use aptos_framework::managed_coin::{
        initialize,
        mint,
        register
    };
    use std::account::{SignerCapability,create_signer_with_capability};
    use std::signer::{address_of};
    use aptos_framework::resource_account::{retrieve_resource_account_cap};
    
    #[test_only]
    use aptos_framework::account::{create_account_for_test};
    #[test_only]
    use aptos_framework::resource_account::{create_resource_account};
    #[test_only]
    use aptos_framework::coin::{balance};

    //structs
    struct Token {}
    struct Capabilities has key {
        signer_cap: SignerCapability,
    }
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
    const ECONFIGURE_HAS_DONE : u64 = 1;

    fun init_module(resource_sender: &signer) {
        let signer_cap = retrieve_resource_account_cap(resource_sender, @deployer);
        initialize<Token>(
            resource_sender,
            TEMPLATE_NAME,
            TEMPLATE_SYMBOL,
            TEMPLATE_DECIMALS,
            true
        );

        move_to(resource_sender, Capabilities { signer_cap });
        move_to(resource_sender, Setup { has_done: false });
    }

    public entry fun configure(sender: &signer) acquires Capabilities, Setup {
        let signer_cap =&borrow_global<Capabilities>(@token).signer_cap;
        let has_done = &mut borrow_global_mut<Setup>(@token).has_done;

        let signer = create_signer_with_capability(signer_cap);
        
        if (address_of(sender) != @deployer) abort ESENDER_NOT_DEPLOYER;
        if (*has_done) abort ECONFIGURE_HAS_DONE;

        register<Token>(sender);
        mint<Token>(&signer, address_of(sender), TEMPLATE_TOTAL_SUPPLY);

        *has_done = true;
    }

    //tests
    #[test_only]
    public entry fun set_up_test(deployer: &signer, resource_account: &signer) {
        create_account_for_test(address_of(deployer));
        create_resource_account(deployer, b"", b"");
        init_module(resource_account);
    }

    #[test(deployer = @deployer, resource_account=@token)]
    public fun test_configure(deployer: signer, resource_account: signer) acquires Capabilities, Setup {
        set_up_test(&deployer, &resource_account);
        configure(&deployer);
        assert!(balance<Token>(address_of(&deployer)) == TEMPLATE_TOTAL_SUPPLY, 1);
    }

    #[test(deployer = @deployer, resource_account=@token)]
    #[expected_failure(abort_code = ECONFIGURE_HAS_DONE, location = Self)]
    public fun test_configure_fail_due_recall_configure(deployer: signer, resource_account: signer) acquires Capabilities, Setup {
        set_up_test(&deployer, &resource_account);
        configure(&deployer);
        configure(&deployer);
    }

    #[test(deployer = @deployer, resource_account=@token, caller = @0x69)]
    #[expected_failure(abort_code = ESENDER_NOT_DEPLOYER, location = Self)]
    public fun test_configure_fail_due_sender_not_deployer(deployer: signer, resource_account: signer, caller: signer) acquires Capabilities, Setup {
        set_up_test(&deployer, &resource_account);
        configure(&caller);
    }
}