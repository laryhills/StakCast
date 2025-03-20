#[cfg(test)]
mod tests {
    use stakcast::interface::{
        IPredictionMarketDispatcher, IPredictionMarketDispatcherTrait, MarketStatus, MarketDetails,
    };
    use starknet::testing::{set_caller_address, set_contract_address, set_block_timestamp};
    use starknet::contract_address_const;
    use starknet::syscalls::deploy_syscall;
    use starknet::ContractAddress;
    use stakcast::prediction::PredictionMarket;

    // Helper function to deploy the PredictionMarket contract
    fn deploy_prediction_market(
        stake_token: ContractAddress,
        fee_collector: ContractAddress,
        platform_fee: u256,
        market_validator: ContractAddress,
    ) -> IPredictionMarketDispatcher {
        let (address, _) = deploy_syscall(
            PredictionMarket::TEST_CLASS_HASH.try_into().unwrap(),
            0,
            array![
                stake_token.into(),
                fee_collector.into(),
                platform_fee.low.into(), // Split u256
                platform_fee.high.into(),
                market_validator.into(),
            ]
                .span(),
            false,
        )
            .unwrap();

        IPredictionMarketDispatcher { contract_address: address }
    }

    #[test]
    fn test_create_market_and_get_details() {
        // Dummy addresses
        let stake_token = contract_address_const::<'stake_token'>();
        let fee_collector = contract_address_const::<'fee_collector'>();
        let market_validator = contract_address_const::<'market_validator'>();
        let market_creator = contract_address_const::<'creator'>();

        // Deploy contract
        let contract = deploy_prediction_market(
            stake_token, fee_collector, 100_u256, market_validator,
        );

        // Set context
        set_contract_address(contract.contract_address);
        set_caller_address(market_creator);
        set_block_timestamp(1000);

        // Create market
        let market_id = contract
            .create_market(
                'Market Title', // felt252 literal
                'Market Desc', // felt252 literal
                'Category', // felt252 literal
                1100, // start_time
                1300, // end_time
                array!['Outcome 1', 'Outcome 2'], // felt252 literals
                50_u256,
                500_u256,
            );

        // Verify details
        let details: MarketDetails = contract.get_market_details(market_id);
        assert_eq!(details.status, MarketStatus::Active, "Incorrect status");
        assert_eq!(details.market.creator, market_creator, "Creator mismatch");
        assert_eq!(details.market.num_outcomes, 2, "Outcome count mismatch");
    }

    #[test]
    #[should_panic(expected: "Market not ended")]
    fn test_early_resolution() {
        let contract = deploy_prediction_market(
            contract_address_const::<'stake_token'>(),
            contract_address_const::<'fee_collector'>(),
            100_u256,
            contract_address_const::<'validator'>(),
        );

        // Create market
        set_caller_address(contract_address_const::<'creator'>());
        let market_id = contract
            .create_market(
                'Test Market', // felt252 literal
                '', // felt252 literal
                '', // felt252 literal
                2000, // start_time
                3000, // end_time
                array!['A', 'B'], // felt252 literals
                10_u256,
                1000_u256,
            );

        // Attempt early resolution
        set_block_timestamp(1500);
        set_caller_address(contract_address_const::<'validator'>());
        contract.resolve_market(market_id, 0, 'Too early' // felt252 literal
        );
    }

    #[test]
    fn test_full_market_lifecycle() {
        let stake_token = contract_address_const::<'stake_token'>();
        let fee_collector = contract_address_const::<'fee_collector'>();
        let market_validator = contract_address_const::<'validator'>();
        let contract = deploy_prediction_market(
            stake_token, fee_collector, 100_u256, market_validator,
        );

        // Create market
        let creator = contract_address_const::<'creator'>();
        set_caller_address(creator);
        set_block_timestamp(1000);
        let market_id = contract
            .create_market(
                'BTC Price Prediction', // felt252 literal
                'BTC $100K by 2024?', // felt252 literal
                'Crypto', // felt252 literal
                1100, // start_time
                1300, // end_time
                array!['Yes', 'No'], // felt252 literals
                10_u256,
                1000_u256,
            );

        // Take position
        let user = contract_address_const::<'user'>();
        set_caller_address(user);
        contract.take_position(market_id, 0, 100_u256);

        // Verify position
        let position = contract.get_user_position(user, market_id);
        assert_eq!(position.amount, 100_u256, "Position amount mismatch");
        assert!(!position.claimed, "Position should be unclaimed");

        // Resolve market
        set_block_timestamp(1350);
        set_caller_address(market_validator);
        contract.resolve_market(market_id, 0, 'Consensus reached' // felt252 literal
        );

        // Verify resolution
        let details: MarketDetails = contract.get_market_details(market_id);
        assert_eq!(details.status, MarketStatus::Resolved, "Market not resolved");

        assert!(details.outcome.is_some(), "Missing outcome details");

        // Claim winnings
        set_caller_address(user);
        contract.claim_winnings(market_id);

        // Verify claim
        let updated_position = contract.get_user_position(user, market_id);
        assert!(updated_position.claimed, "Winnings not claimed");
    }
}
