use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, spy_events, EventSpyAssertionsTrait,
    start_cheat_caller_address, stop_cheat_caller_address,
};
use starknet::testing::set_contract_address;
use starknet::contract_address_const;
use starknet::ContractAddress;
use stakcast::interface::{
    IMarketValidatorDispatcher, IMarketValidatorDispatcherTrait,
};

// Helper function to deploy the MarketValidator contract
fn deploy_market_validator(
    prediction_market: ContractAddress,
    min_stake: u256,
    resolution_timeout: u64,
    slash_percentage: u64,
) -> IMarketValidatorDispatcher {
    // Declare the contract
    let declare_result = declare("MarketValidator").unwrap();
    let contract_class = declare_result.contract_class();

    // Prepare constructor arguments
    let mut constructor_args = array![
        prediction_market.into(),
        min_stake.low.into(),
        min_stake.high.into(),
        resolution_timeout.into(),
        slash_percentage.into()
    ];

    // Deploy the contract
    let (address, _) = contract_class.deploy(@constructor_args).unwrap();

    IMarketValidatorDispatcher { contract_address: address }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_register_validator() {
        let prediction_market = contract_address_const::<'prediction_market'>();
        let validator = contract_address_const::<'validator'>();

        // Deploy the contract
        let contract = deploy_market_validator(prediction_market, 100_u256, 10, 10);

        // Set context
        set_contract_address(contract.contract_address);
        start_cheat_caller_address(contract.contract_address, validator);

        // Register the validator
        contract.register_validator(100_u256);

        // Stop cheating caller address
        stop_cheat_caller_address(contract.contract_address);

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
    fn test_slash_validator() {
        let prediction_market = contract_address_const::<'prediction_market'>();
        let validator = contract_address_const::<'validator'>();
        let contract = deploy_market_validator(prediction_market, 150_u256, 10, 10);

        // Register the validator
        set_contract_address(contract.contract_address);
        start_cheat_caller_address(contract.contract_address, validator);
        contract.register_validator(150_u256);
        stop_cheat_caller_address(contract.contract_address);

        // Slash the validator
        start_cheat_caller_address(contract.contract_address, prediction_market);
        contract.slash_validator(validator, 0_u256, 'bad_resolution');
        stop_cheat_caller_address(contract.contract_address);

        // Calculate slashed amount
        let slashed_amount = (150_u256 * 10_u256) / 100_u256; // 10% of 150

        // Verify slash
        let info = contract.get_validator_info(validator);
        assert_eq!(info.stake, 150_u256 - slashed_amount, "Stake after slash mismatch");
        assert!(info.active, "Validator should remain active");
        assert_eq!(info.disputed_resolutions, 1, "Dispute count mismatch");
    }

    #[test]
    #[should_panic(expected: "Validator not active")]
    fn test_slash_inactive_validator() {
        let prediction_market = contract_address_const::<'prediction_market'>();
        let validator = contract_address_const::<'validator'>();
        let contract = deploy_market_validator(prediction_market, 100_u256, 10, 10);

        // Try to slash a non-existent validator
        start_cheat_caller_address(contract.contract_address, prediction_market);
        contract.slash_validator(validator, 50_u256, 'no_stake');
        stop_cheat_caller_address(contract.contract_address);
    }
}