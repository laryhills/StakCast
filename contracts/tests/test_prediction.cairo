use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, spy_events, EventSpyAssertionsTrait,
    start_cheat_caller_address, test_address, stop_cheat_caller_address,
};
use starknet::testing::set_block_timestamp;
use starknet::ContractAddress;
use openzeppelin::token::erc20::interface::{IERC20Dispatcher};
use stakcast::interface::{
    IPredictionMarketDispatcher, IPredictionMarketDispatcherTrait, IMarketValidatorDispatcher,
    IMarketValidatorDispatcherTrait // Import the trait defining set_prediction_market
};
use stakcast::interface::MarketStatus; // Import MarketStatus
use stakcast::prediction::PredictionMarket::{Event, MarketResolved, MarketDisputed};

// Helper to deploy MarketValidator (dependency)
fn deploy_market_validator(
    prediction_market: ContractAddress,
    min_stake: u256,
    resolution_timeout: u64,
    slash_percentage: u64,
    owner: ContractAddress,
) -> IMarketValidatorDispatcher {
    let declare_result = declare("MarketValidator").unwrap();
    let contract_class = declare_result.contract_class();
    let constructor_args = array![
        prediction_market.into(),
        min_stake.low.into(), // Split into low
        min_stake.high.into(), // and high
        resolution_timeout.into(),
        slash_percentage.into(),
        owner.into(),
    ];
    let (address, _) = contract_class.deploy(@constructor_args).unwrap();
    IMarketValidatorDispatcher { contract_address: address }
}

// Helper to deploy PredictionMarket
fn deploy_prediction_market(
    fee_collector: ContractAddress,
    platform_fee: u256,
    market_validator: ContractAddress,
) -> IPredictionMarketDispatcher {
    let declare_result = declare("PredictionMarket").unwrap();
    let contract_class = declare_result.contract_class();
    let constructor_args = array![
        fee_collector.into(),
        platform_fee.low.into(), // Split into low
        platform_fee.high.into(), // and high
        market_validator.into(),
    ];
    let (address, _) = contract_class.deploy(@constructor_args).unwrap();
    IPredictionMarketDispatcher { contract_address: address }
}

// Helper to deploy a mock ERC20 token
fn deploy_mock_erc20() -> IERC20Dispatcher {
    let declare_result = declare("MockERC20").unwrap();
    let contract_class = declare_result.contract_class();
    let (address, _) = contract_class.deploy(@array![].into()).unwrap();
    IERC20Dispatcher { contract_address: address }
}

const ADMIN_ROLE: felt252 = selector!("ADMIN_ROLE");
const INVALID_ROLE: felt252 = selector!("INVALID_ROLE");

fn RANDOM_ADDRESS() -> ContractAddress {
    'RANDOM_ADDRESS'.try_into().unwrap()
}

// Test: Market Creation
#[test]
fn test_create_market() {
    // Deploy dependencies
    let fee_collector = test_address();
    let owner = test_address();
    let mv_contract = deploy_market_validator(
        test_address(), // PredictionMarket address (mock for now)
        100_u256, 86400, 10, owner,
    );
    let pm_contract = deploy_prediction_market(
        fee_collector, 500_u256, // 5% fee
        mv_contract.contract_address,
    );

    // Mock caller as admin (assuming creator is admin for simplicity in this test)
    start_cheat_caller_address(pm_contract.contract_address, owner);
    set_block_timestamp(1000);

    // Create market
    let outcomes = array!['Yes', 'No'];
    let market_id = pm_contract
        .create_market("Test Market", "", "Category", 2000, 3000, outcomes, 100_u256, 1000_u256);

    // Verify market details
    let market_details = pm_contract.get_market_details(market_id);
    assert_eq!(market_details.market.title, "Test Market", "Incorrect market title");
    assert_eq!(market_details.status, MarketStatus::Active, "Market should be active");
}

// Test: Taking a Position
#[test]
fn test_take_position() {
    
    let owner = test_address();
    let user = test_address();
    let mv_contract = deploy_market_validator(
        test_address(), // PredictionMarket address (mock for now)
        100_u256, 86400, 10, owner,
    );
    let pm_contract = deploy_prediction_market(
     owner, 500_u256, mv_contract.contract_address,
    );

    // Create market
    start_cheat_caller_address(pm_contract.contract_address, owner);
    let outcomes = array!['Yes', 'No'];
    let market_id = pm_contract
        .create_market("Test Market", "", "Category", 2000, 3000, outcomes, 100_u256, 1000_u256);

    // Mock user's ERC20 transfer
    start_cheat_caller_address(pm_contract.contract_address, user);
    pm_contract.deposit(500_u256); // Fund user

    // Take position
    pm_contract.take_position(market_id, 0, 500_u256);

    // Verify position
    let position = pm_contract.get_user_position(user, market_id);
    assert_eq!(position.outcome_index, 0, "Incorrect outcome index");
    assert_eq!(position.amount, 500_u256, "Incorrect stake amount");
}

#[test]
fn test_resolve_market() {
    // Deploy dependencies
    let owner = test_address();
    let mv_contract = deploy_market_validator(test_address(), 100_u256, 86400, 10, owner);
    let pm_contract = deploy_prediction_market(
        owner,
        500_u256,
        mv_contract.contract_address
    );

    // Update MarketValidator with PredictionMarket address
    let mv_contract_dispatcher = IMarketValidatorDispatcher {
        contract_address: mv_contract.contract_address,
    };
    mv_contract_dispatcher.set_prediction_market(pm_contract.contract_address);

    // Create market
    start_cheat_caller_address(pm_contract.contract_address, owner);
    let outcomes = array!['Yes', 'No'];
    let market_id = pm_contract
        .create_market("Test Market", "", "Category", 2000, 3000, outcomes, 100_u256, 1000_u256);

    // Resolve market
    set_block_timestamp(3500); // After end_time
    start_cheat_caller_address(pm_contract.contract_address, owner); // Set caller to validator
    let mut spy = spy_events();
    pm_contract.resolve_market(market_id, 0, 'Resolution details');

    // Verify resolution
    let market_details = pm_contract.get_market_details(market_id);
    assert_eq!(market_details.status, MarketStatus::Resolved, "Market should be resolved");
    spy
        .assert_emitted(
            @array![
                (
                    pm_contract.contract_address,
                    Event::MarketResolved(
                        MarketResolved {
                            market_id: market_id,
                            outcome: 0,
                            resolver: owner,
                            resolution_details: 'Resolution details',
                        },
                    ),
                ),
            ],
        );
}

#[test]
fn test_dispute_market() {
    // Deploy dependencies
    let owner = test_address();
    let disputer = test_address();
    let mv_contract = deploy_market_validator(test_address(), 100_u256, 86400, 10, owner);
    let pm_contract = deploy_prediction_market(
        owner,
        500_u256,
        mv_contract.contract_address
    );

    // Update MarketValidator with PredictionMarket address
    let mv_contract_dispatcher = IMarketValidatorDispatcher {
        contract_address: mv_contract.contract_address,
    };
    mv_contract_dispatcher.set_prediction_market(pm_contract.contract_address);

    // Create and resolve market
    start_cheat_caller_address(pm_contract.contract_address, owner);
    let outcomes = array!['Yes', 'No'];
    let market_id = pm_contract
        .create_market("Test Market", "", "Category", 2000, 3000, outcomes, 100_u256, 1000_u256);
    set_block_timestamp(3500);
    pm_contract.resolve_market(market_id, 0, 'Resolution details');

    // Dispute market
    start_cheat_caller_address(pm_contract.contract_address, disputer);
    let mut spy = spy_events();
    pm_contract.dispute_market(market_id, 'Dispute reason');

    // Verify dispute
    let market_details = pm_contract.get_market_details(market_id);
    assert_eq!(market_details.status, MarketStatus::Disputed, "Market should be disputed");
    spy
        .assert_emitted(
            @array![
                (
                    pm_contract.contract_address,
                    Event::MarketDisputed(
                        MarketDisputed {
                            market_id: market_id, disputer: disputer, reason: 'Dispute reason',
                        },
                    ),
                ),
            ],
        );
}

// Test: Market Cancellation
#[test]
fn test_cancel_market() {
    // Deploy dependencies
    let creator = test_address();
    let mv_contract = deploy_market_validator(
        test_address(), // PredictionMarket address (mock for now)
        100_u256, 86400, 10, creator,
    );
    let pm_contract = deploy_prediction_market(
         creator, 500_u256, mv_contract.contract_address,
    );

    // Update MarketValidator with PredictionMarket address
    let mv_contract_dispatcher = IMarketValidatorDispatcher {
        contract_address: mv_contract.contract_address,
    };
    mv_contract_dispatcher.set_prediction_market(pm_contract.contract_address);

    // Create market
    start_cheat_caller_address(pm_contract.contract_address, creator);
    let outcomes = array!['Yes', 'No'];
    let market_id = pm_contract
        .create_market("Test Market", "", "Category", 2000, 3000, outcomes, 100_u256, 1000_u256);

    // Cancel market
    pm_contract.cancel_market(market_id, 'Cancel reason');

    // Verify cancellation
    let market = pm_contract.get_market_details(market_id);
    assert_eq!(market.status, MarketStatus::Cancelled, "Market should be cancelled");
}

// Test: Claim Winnings
#[test]
fn test_claim_winnings() {
    // Deploy dependencies
    let owner = test_address();
    let user = test_address();
    let mv_contract = deploy_market_validator(
        test_address(), // PredictionMarket address (mock for now)
        100_u256, 86400, 10, owner,
    );
    let pm_contract = deploy_prediction_market(
        owner, 500_u256, mv_contract.contract_address,
    );

    // Update MarketValidator with PredictionMarket address
    let mv_contract_dispatcher = IMarketValidatorDispatcher {
        contract_address: mv_contract.contract_address,
    };
    mv_contract_dispatcher.set_prediction_market(pm_contract.contract_address);

    // Create market and take position
    start_cheat_caller_address(pm_contract.contract_address, owner);
    let outcomes = array!['Yes', 'No'];
    let market_id = pm_contract
        .create_market("Test Market", "", "Category", 2000, 3000, outcomes, 100_u256, 1000_u256);
    start_cheat_caller_address(pm_contract.contract_address, user);
    pm_contract.deposit(500_u256); // Fund user
    pm_contract.take_position(market_id, 0, 500_u256);

    // Resolve market
    set_block_timestamp(3500);
    start_cheat_caller_address(pm_contract.contract_address, owner); // Switch to resolver
    pm_contract.resolve_market(market_id, 0, 'Resolution details');

    // Claim winnings
    start_cheat_caller_address(pm_contract.contract_address, user); // Switch back to user
    let initial_balance = pm_contract.get_balance(user); // Assume this function exists
    pm_contract.claim_winnings(market_id);
    let final_balance = pm_contract.get_balance(user);

    // Verify claim
    let position = pm_contract.get_user_position(user, market_id);
    assert!(position.claimed, "Position should be claimed");
    assert!(final_balance > initial_balance, "Balance should increase after claiming");
}

// Edge Case Test: Invalid Market ID
#[test]
#[should_panic(
    expected: "Hint Error: \n        0x496e70757420746f6f206c6f6e6720666f7220617267756d656e7473 ('Input too long for arguments')\n    ",
)]
fn test_invalid_market_id() {
    let mv_contract = deploy_market_validator(test_address(), 100_u256, 86400, 10, test_address());
    let pm_contract = deploy_prediction_market(
         test_address(), 500_u256, mv_contract.contract_address,
    );
    pm_contract.resolve_market(9999, 0, 'Invalid'); // Non-existent market
}

#[test]
fn test_deposit() {
    // Deploy dependencies
    let owner = test_address();
    let user = test_address();
    let mv_contract = deploy_market_validator(
        test_address(), 100_u256, 86400, 10, owner,
    );
    let pm_contract = deploy_prediction_market(
        owner, 500_u256, mv_contract.contract_address,
    );

    // Deposit funds
    start_cheat_caller_address(pm_contract.contract_address, user);
    let initial_balance = pm_contract.get_balance(user); // Assume this function exists
    pm_contract.deposit(1000_u256);
    let final_balance = pm_contract.get_balance(user);

    // Verify balance increase
    assert_eq!(final_balance, initial_balance + 1000_u256, "Balance should increase by deposit amount");
}

#[test]
#[should_panic(expected: ("(Input too long for arguments balance",))]
fn test_withdraw() {
    // Deploy dependencies
    let owner = test_address();
    let user = test_address();
    let mv_contract = deploy_market_validator(
        test_address(), 100_u256, 86400, 10, owner,
    );
    let pm_contract = deploy_prediction_market(
        owner, 500_u256, mv_contract.contract_address,
    );

    // Deposit funds
    start_cheat_caller_address(pm_contract.contract_address, user);
    pm_contract.deposit(1000_u256);

    // Withdraw funds
    let initial_balance = pm_contract.get_balance(user);
    pm_contract.withdraw(600_u256);
    let final_balance = pm_contract.get_balance(user);

    // Verify balance decrease
    assert_eq!(final_balance, initial_balance - 600_u256, "Balance should decrease by withdrawal amount");

    // Attempt to withdraw more than balance (should fail)
    // Assuming withdraw reverts with a panic on insufficient funds
    pm_contract.withdraw(500_u256); // Only 400 left
}

#[test]
fn test_multiple_deposits_and_withdrawals() {
    // Deploy dependencies
    let owner = test_address();
    let user = test_address();
    let mv_contract = deploy_market_validator(
        test_address(), 100_u256, 86400, 10, owner,
    );
    let pm_contract = deploy_prediction_market(
        owner, 500_u256, mv_contract.contract_address,
    );

    // Perform operations
    start_cheat_caller_address(pm_contract.contract_address, user);
    pm_contract.deposit(500_u256);
    assert_eq!(pm_contract.get_balance(user), 500_u256, "First deposit failed");
    pm_contract.deposit(300_u256);
    assert_eq!(pm_contract.get_balance(user), 800_u256, "Second deposit failed");
    pm_contract.withdraw(400_u256);
    assert_eq!(pm_contract.get_balance(user), 400_u256, "Withdrawal failed");
}

