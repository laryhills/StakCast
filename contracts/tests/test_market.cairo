use starknet::ContractAddress;
use starknet::get_caller_address;
use starknet::testing::{set_contract_address, set_caller_address, set_block_timestamp};

use contracts::src::interface::{IMarketValidator, IPredictionMarket};
use contracts::src::market_validator::MarketValidator;

#[test]
fn test_register_validator() {
    // Deploy the MarketValidator contract
    let market_validator = MarketValidator::deploy(
        prediction_market: ContractAddress { value: 123 },
        min_stake: 1000,
        resolution_timeout: 86400,
    );

    // Set the caller address
    set_caller_address(ContractAddress { value: 456 });

    // Register a validator
    market_validator.register_validator(1000);

    // Verify the validator was registered
    let validator_info = market_validator.get_validator_info(get_caller_address());
    assert(validator_info.stake == 1000, 'Incorrect stake');
    assert(validator_info.active, 'Validator should be active');
}

#[test]
fn test_resolve_market() {
    // Deploy the MarketValidator contract
    let market_validator = MarketValidator::deploy(
        prediction_market: ContractAddress { value: 123 },
        min_stake: 1000,
        resolution_timeout: 86400,
    );

    // Register a validator
    set_caller_address(ContractAddress { value: 456 });
    market_validator.register_validator(1000);

    // Resolve a market
    set_block_timestamp(2000); // Simulate time after market end
    market_validator.resolve_market(1, 0, 'Test resolution');

    // Verify the market was resolved
    let (market, status, outcome) = market_validator.get_market_details(1);
    assert(status == MarketStatus::Resolved, 'Market should be resolved');
    assert(outcome.unwrap().winning_outcome == 0, 'Incorrect winning outcome');
}

#[test]
fn test_slash_validator() {
    // Deploy the MarketValidator contract
    let market_validator = MarketValidator::deploy(
        prediction_market: ContractAddress { value: 123 },
        min_stake: 1000,
        resolution_timeout: 86400,
    );

    // Register a validator
    set_caller_address(ContractAddress { value: 456 });
    market_validator.register_validator(1000);

    // Slash the validator
    set_caller_address(ContractAddress { value: 123 }); // Prediction market address
    market_validator.slash_validator(ContractAddress { value: 456 }, 500, 'Test reason');

    // Verify the validator was slashed
    let validator_info = market_validator.get_validator_info(ContractAddress { value: 456 });
    assert(validator_info.stake == 500, 'Incorrect stake after slashing');
    assert(!validator_info.active, 'Validator should be inactive');
}