use starknet::ContractAddress;
use starknet::get_caller_address;
use starknet::testing::{set_contract_address, set_caller_address, set_block_timestamp};

use contracts::src::interface::{IPredictionMarket, IERC20};
use contracts::src::prediction_market::PredictionMarket;

#[test]
fn test_create_market() {
    // Deploy the PredictionMarket contract
    let prediction_market = PredictionMarket::deploy(
        stake_token_address: ContractAddress { value: 123 },
        fee_collector: ContractAddress { value: 456 },
        platform_fee: 100,
    );

    // Set the caller address
    set_caller_address(ContractAddress { value: 789 });

    // Set the block timestamp
    set_block_timestamp(500);

    // Create a new market
    let market_id = prediction_market.create_market(
        title: 'Test Market',
        description: 'This is a test market',
        category: 'Test',
        start_time: 1000,
        end_time: 2000,
        outcomes: ['Yes', 'No'],
        min_stake: 100,
        max_stake: 1000,
    );

    // Verify the market was created
    let (market, status, outcome) = prediction_market.get_market_details(market_id);
    assert(market.creator == get_caller_address(), 'Incorrect creator');
    assert(market.title == 'Test Market', 'Incorrect title');
    assert(status == MarketStatus::Active, 'Market should be active');
}

#[test]
fn test_take_position() {
    // Deploy the PredictionMarket contract
    let prediction_market = PredictionMarket::deploy(
        stake_token_address: ContractAddress { value: 123 },
        fee_collector: ContractAddress { value: 456 },
        platform_fee: 100,
    );

    // Set the caller address
    set_caller_address(ContractAddress { value: 789 });

    // Set the block timestamp
    set_block_timestamp(500);

    // Create a new market
    let market_id = prediction_market.create_market(
        title: 'Test Market',
        description: 'This is a test market',
        category: 'Test',
        start_time: 1000,
        end_time: 2000,
        outcomes: ['Yes', 'No'],
        min_stake: 100,
        max_stake: 1000,
    );

    // Take a position in the market
    set_caller_address(ContractAddress { value: 999 });
    prediction_market.take_position(market_id, 0, 500);

    // Verify the position was taken
    let position = prediction_market.get_user_position(get_caller_address(), market_id);
    assert(position.amount == 500, 'Incorrect position amount');
    assert(position.outcome_index == 0, 'Incorrect outcome index');
}

#[test]
fn test_claim_winnings() {
    // Deploy the PredictionMarket contract
    let prediction_market = PredictionMarket::deploy(
        stake_token_address: ContractAddress { value: 123 },
        fee_collector: ContractAddress { value: 456 },
        platform_fee: 100,
    );

    // Set the caller address
    set_caller_address(ContractAddress { value: 789 });

    // Set the block timestamp
    set_block_timestamp(500);

    // Create a new market
    let market_id = prediction_market.create_market(
        title: 'Test Market',
        description: 'This is a test market',
        category: 'Test',
        start_time: 1000,
        end_time: 2000,
        outcomes: ['Yes', 'No'],
        min_stake: 100,
        max_stake: 1000,
    );

    // Take a position in the market
    set_caller_address(ContractAddress { value: 999 });
    prediction_market.take_position(market_id, 0, 500);

    // Resolve the market
    set_caller_address(ContractAddress { value: 789 }); // Validator address
    prediction_market.resolve_market(market_id, 0, 'Test resolution');

    // Claim winnings
    set_caller_address(ContractAddress { value: 999 });
    prediction_market.claim_winnings(market_id);

    // Verify the position was claimed
    let position = prediction_market.get_user_position(get_caller_address(), market_id);
    assert(position.claimed, 'Winnings not claimed');
}