#[cfg(test)]
mod tests {
    use stakcast::interface::{IMarketValidatorDispatcher, IMarketValidatorDispatcherTrait, ValidatorInfo};
    use starknet::testing::{set_caller_address, set_contract_address, set_block_timestamp};
    use starknet::contract_address_const;
    use starknet::syscalls::deploy_syscall;
    use starknet::ContractAddress;
    use stakcast::market::MarketValidator;

    // Helper to deploy MarketValidator
    fn deploy_market_validator(
        prediction_market: ContractAddress,
        min_stake: u256,
        resolution_timeout: u64,
        slash_percentage: u64
    ) -> IMarketValidatorDispatcher {
        let (address, _) = deploy_syscall(
            MarketValidator::TEST_CLASS_HASH.try_into().unwrap(),
            0,
            array![
                prediction_market.into(),
                min_stake.low.into(),  // Split u256
                min_stake.high.into(),
                resolution_timeout.into(),
                slash_percentage.into()
            ].span(),
            false
        ).unwrap();
        
        IMarketValidatorDispatcher { contract_address: address }
    }

    #[test]
    fn test_register_validator() {
        let prediction_market = contract_address_const::<'pm'>();
        let validator = contract_address_const::<'validator'>();
        
        // Deploy with 100 min stake
        let contract = deploy_market_validator(
            prediction_market,
            100_u256, 
            10, 
            10
        );

        // Set context
        set_contract_address(contract.contract_address);
        set_caller_address(validator);

        // Register with min stake
        contract.register_validator(100_u256);

        // Verify registration
        let info = contract.get_validator_info(validator);
        assert_eq!(info.stake, 100_u256, "Stake mismatch");
        assert!(info.active, "Validator not active");
        assert_eq!(info.markets_resolved, 0, "Initial resolved markets should be 0");

        // Verify index mapping
        assert_eq!(
            contract.get_validator_by_index(0),
            validator,
            "Index mapping incorrect"
        );
        assert_eq!(contract.get_validator_count(), 1, "Validator count mismatch");
    }

    #[test]
    fn test_resolve_market() {
        let prediction_market = contract_address_const::<'pm'>();
        let validator = contract_address_const::<'validator'>();
        let contract = deploy_market_validator(prediction_market, 100_u256, 10, 10);

        // Register validator
        set_caller_address(validator);
        contract.register_validator(100_u256);

        // Resolve market
        set_block_timestamp(1000);
        contract.resolve_market(1, 0, 'resolution_details');

        // Verify resolution
        let info = contract.get_validator_info(validator);
        assert_eq!(info.markets_resolved, 1, "Resolved count mismatch");
        assert_eq!(info.last_resolution_time, 1000, "Timestamp not updated");
    }

    #[test]
    fn test_slash_validator() {
        let prediction_market = contract_address_const::<'pm'>();
        let validator = contract_address_const::<'validator'>();
        let contract = deploy_market_validator(prediction_market, 100_u256, 10, 10);

        // Register with 150 stake
        set_caller_address(validator);
        contract.register_validator(150_u256);

        // Slash from prediction market
        set_caller_address(prediction_market);
        contract.slash_validator(validator, 0_u256, 'bad_resolution');

        // Verify slash
        let info = contract.get_validator_info(validator);
        assert_eq!(info.stake, 135_u256, "Stake after slash mismatch"); // 150 - 15 (10%)
        assert!(info.active, "Validator should remain active");
        assert_eq!(info.disputed_resolutions, 1, "Dispute count mismatch");
    }

    #[test]
    #[should_panic]
    fn test_slash_inactive_validator() {
        let prediction_market = contract_address_const::<'pm'>();
        let validator = contract_address_const::<'validator'>();
        let contract = deploy_market_validator(prediction_market, 100_u256, 10, 10);

        // Try to slash non-existent validator
        set_caller_address(prediction_market);
        contract.slash_validator(validator, 50_u256, 'no_stake');
    }
}