use snforge_std::{declare, DeclareResultTrait};
use starknet::testing::{set_caller_address, set_contract_address};
use starknet::contract_address_const;
use starknet::syscalls::deploy_syscall;
use starknet::ContractAddress;
use stakcast::interface::{
    IPredictionMarketDispatcher, IPredictionMarketDispatcherTrait,
    IMarketValidatorDispatcher, IMarketValidatorDispatcherTrait,
    MarketStatus, MarketDetails, ValidatorInfo
};

// Helper function to deploy the PredictionMarket contract
fn deploy_prediction_market(
    stake_token: ContractAddress,
    fee_collector: ContractAddress,
    platform_fee: u256,
    market_validator: ContractAddress
) -> IPredictionMarketDispatcher {
    // Declare the contract class first
    let declare_result = declare("stakcast::prediction::PredictionMarket").unwrap();
    let contract_class = declare_result.contract_class();
    let class_hash = *contract_class.class_hash;
    println!("ClassHash for PredictionMarket: {:?}", class_hash);

    // Deploy the contract using the extracted ClassHash
    let (address, _) = deploy_syscall(
        class_hash,
        0,
        array![
            stake_token.into(),
            fee_collector.into(),
            platform_fee.low.into(),  // Split u256
            platform_fee.high.into(),
            market_validator.into()
        ].span(),
        false
    ).unwrap();

    IPredictionMarketDispatcher { contract_address: address }
}

// Helper function to deploy the MarketValidator contract
fn deploy_market_validator(
    prediction_market: ContractAddress,
    min_stake: u256,
    resolution_timeout: u64,
    slash_percentage: u64
) -> IMarketValidatorDispatcher {
    // Declare the contract class first
    let declare_result = declare("stakcast::market::MarketValidator").unwrap();
    let contract_class = declare_result.contract_class();
    let class_hash = *contract_class.class_hash;
    println!("ClassHash for MarketValidator: {:?}", class_hash);

    // Deploy the contract using the extracted ClassHash
    let (address, _) = deploy_syscall(
        class_hash,
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

#[cfg(test)]
mod tests_prediction {
    use super::*;

    #[test]
    fn test_create_market_and_get_details() {
        // Dummy addresses
        let stake_token = contract_address_const::<'stake_token'>();
        let fee_collector = contract_address_const::<'fee_collector'>();
        let market_validator = contract_address_const::<'market_validator'>();
        let market_creator = contract_address_const::<'creator'>();

        // Deploy contract
        let contract = deploy_prediction_market(
            stake_token,
            fee_collector,
            100_u256,
            market_validator
        );

        // Set context
        set_contract_address(contract.contract_address);
        set_caller_address(market_creator);

        // Create market
        let market_id = contract.create_market(
            'Market Title',  // felt252 literal
            'Market Desc',  // felt252 literal
            'Category',     // felt252 literal
            1100,           // start_time
            1300,           // end_time
            array!['Outcome 1', 'Outcome 2'],  // felt252 literals
            50_u256,
            500_u256
        );

        // Verify details
        let details: MarketDetails = contract.get_market_details(market_id);
        assert_eq!(details.status, MarketStatus::Active, "Incorrect status");
        assert_eq!(details.market.creator, market_creator, "Creator mismatch");
        assert_eq!(details.market.num_outcomes, 2, "Outcome count mismatch");
    }
}

#[cfg(test)]
mod tests_market {
    use super::*;

    #[test]
    fn test_register_validator() {
        let prediction_market = contract_address_const::<'prediction_market'>();
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
}