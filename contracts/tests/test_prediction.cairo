use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, spy_events, EventSpyAssertionsTrait,
    start_cheat_caller_address, test_address, stop_cheat_caller_address,
};
use starknet::testing::set_block_timestamp;
use starknet::ContractAddress;
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
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
    stake_token: ContractAddress,
    fee_collector: ContractAddress,
    platform_fee: u256,
    market_validator: ContractAddress,
) -> IPredictionMarketDispatcher {
    let declare_result = declare("PredictionMarket").unwrap();
    let contract_class = declare_result.contract_class();
    let constructor_args = array![
        stake_token.into(),
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
    let erc20 = deploy_mock_erc20();
    let fee_collector = test_address();
    let owner = test_address();
    let mv_contract = deploy_market_validator(
        test_address(), // PredictionMarket address (mock for now)
        100_u256, 86400, 10, owner,
    );
    let pm_contract = deploy_prediction_market(
        erc20.contract_address, fee_collector, 500_u256, // 5% fee
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
    // Deploy dependencies
    let erc20 = deploy_mock_erc20();
    let owner = test_address();
    let user = test_address();
    let mv_contract = deploy_market_validator(
        test_address(), // PredictionMarket address (mock for now)
        100_u256, 86400, 10, owner,
    );
    let pm_contract = deploy_prediction_market(
        erc20.contract_address, owner, 500_u256, mv_contract.contract_address,
    );

    // Create market
    start_cheat_caller_address(pm_contract.contract_address, owner);
    let outcomes = array!['Yes', 'No'];
    let market_id = pm_contract
        .create_market("Test Market", "", "Category", 2000, 3000, outcomes, 100_u256, 1000_u256);

    // Mock user's ERC20 transfer
    start_cheat_caller_address(pm_contract.contract_address, user);
    erc20.transfer(pm_contract.contract_address, 500_u256); // Fund user

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
    let erc20 = deploy_mock_erc20();
    let owner = test_address();
    let mv_contract = deploy_market_validator(test_address(), 100_u256, 86400, 10, owner);
    let pm_contract = deploy_prediction_market(
        erc20.contract_address, owner, 500_u256, mv_contract.contract_address,
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
    let erc20 = deploy_mock_erc20();
    let owner = test_address();
    let disputer = test_address();
    let mv_contract = deploy_market_validator(test_address(), 100_u256, 86400, 10, owner);
    let pm_contract = deploy_prediction_market(
        erc20.contract_address, owner, 500_u256, mv_contract.contract_address,
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
    let erc20 = deploy_mock_erc20();
    let creator = test_address();
    let mv_contract = deploy_market_validator(
        test_address(), // PredictionMarket address (mock for now)
        100_u256, 86400, 10, creator,
    );
    let pm_contract = deploy_prediction_market(
        erc20.contract_address, creator, 500_u256, mv_contract.contract_address,
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
    let erc20 = deploy_mock_erc20();
    let owner = test_address();
    let user = test_address();
    let mv_contract = deploy_market_validator(
        test_address(), // PredictionMarket address (mock for now)
        100_u256, 86400, 10, owner,
    );
    let pm_contract = deploy_prediction_market(
        erc20.contract_address, owner, 500_u256, mv_contract.contract_address,
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
    erc20.transfer(pm_contract.contract_address, 500_u256); // Fund user
    pm_contract.take_position(market_id, 0, 500_u256);

    // Resolve market
    set_block_timestamp(3500);
    start_cheat_caller_address(pm_contract.contract_address, owner); // Switch to resolver
    pm_contract.resolve_market(market_id, 0, 'Resolution details');

    // Claim winnings
    start_cheat_caller_address(pm_contract.contract_address, user); // Switch back to user
    pm_contract.claim_winnings(market_id);

    // Verify claim
    let position = pm_contract.get_user_position(user, market_id);
    assert!(position.claimed, "Position should be claimed");
}

// Edge Case Test: Invalid Market ID
#[test]
#[should_panic(
    expected: "Hint Error: \n        0x496e70757420746f6f206c6f6e6720666f7220617267756d656e7473 ('Input too long for arguments')\n    ",
)]
fn test_invalid_market_id() {
    let mv_contract = deploy_market_validator(test_address(), 100_u256, 86400, 10, test_address());
    let pm_contract = deploy_prediction_market(
        test_address(), test_address(), 500_u256, mv_contract.contract_address,
    );
    pm_contract.resolve_market(9999, 0, 'Invalid'); // Non-existent market
}

#[test]
fn test_set_role() {
    let mock_erc20 = test_address();
    let fee_collector = test_address();
    let owner = test_address();
    let admin = test_address();
    let mv_contract = deploy_market_validator(
        test_address(), // PredictionMarket address (mock for now)
        100_u256, 86400, 10, owner,
    );
    let pm_contract = deploy_prediction_market(
        mock_erc20, fee_collector, 500_u256, mv_contract.contract_address,
    );

    // set the role of the admin contract address to an admin
    mv_contract.set_role(admin, ADMIN_ROLE, true);

    // get admin status to check weather his role changed to an admin
    let admin_status = mv_contract.is_admin(ADMIN_ROLE, admin);
    assert!(admin_status, "Admin status should be true");
}


#[test]
fn test_remove_role() {
    let mock_erc20 = test_address();
    let fee_collector = test_address();
    let owner = test_address();
    let admin = test_address();
    let mv_contract = deploy_market_validator(
        test_address(), // PredictionMarket address (mock for now)
        100_u256, 86400, 10, owner,
    );
    let pm_contract = deploy_prediction_market(
        mock_erc20, fee_collector, 500_u256, mv_contract.contract_address,
    );

    // set the role of the admin contract address to an admin
    mv_contract.set_role(admin, ADMIN_ROLE, true);

    // get admin status to check weather his role changed to an admin
    let admin_status = mv_contract.is_admin(ADMIN_ROLE, admin);
    assert!(admin_status, "Admin status should be true");

    // remove the role
    mv_contract.set_role(admin, ADMIN_ROLE, false);

    // assert that it is false now
    let admin_status = mv_contract.is_admin(ADMIN_ROLE, admin);
    assert!(!admin_status, "Admin status should be true");
}

#[test]
#[should_panic]
fn test_set_role_should_panic_when_invalid_role_is_passed() {
    let mock_erc20 = test_address();
    let fee_collector = test_address();
    let owner = test_address();
    let admin = test_address();
    let mv_contract = deploy_market_validator(
        test_address(), // PredictionMarket address (mock for now)
        100_u256, 86400, 10, owner,
    );
    let pm_contract = deploy_prediction_market(
        mock_erc20, fee_collector, 500_u256, mv_contract.contract_address,
    );

    mv_contract.set_role(admin, INVALID_ROLE, false);
}

#[test]
#[should_panic(expected: ('Caller is missing role',))]
fn test_set_role_should_panic_when_called_by_non_owner() {
    let mock_erc20 = test_address();
    let fee_collector = test_address();
    let owner = test_address();
    let admin = test_address();
    let mv_contract = deploy_market_validator(
        test_address(), // PredictionMarket address (mock for now)
        100_u256, 86400, 10, owner,
    );
    let pm_contract = deploy_prediction_market(
        mock_erc20, fee_collector, 500_u256, mv_contract.contract_address,
    );

    start_cheat_caller_address(mv_contract.contract_address, RANDOM_ADDRESS());
    mv_contract.set_role(admin, ADMIN_ROLE, true);
    stop_cheat_caller_address(mv_contract.contract_address);

    start_cheat_caller_address(mv_contract.contract_address, RANDOM_ADDRESS());
    mv_contract.set_role(admin, ADMIN_ROLE, true);
    stop_cheat_caller_address(mv_contract.contract_address);
}

#[test]
fn test_set_prediction_market() {
    let mock_erc20 = test_address();
    let fee_collector = test_address();
    let owner = test_address();
    let admin = test_address();
    let mock_prediction_market = test_address();
    let mv_contract = deploy_market_validator(
        test_address(), // PredictionMarket address (mock for now)
        100_u256, 86400, 10, owner,
    );
    let pm_contract = deploy_prediction_market(
        mock_erc20, fee_collector, 500_u256, mv_contract.contract_address,
    );
    mv_contract.set_role(admin, ADMIN_ROLE, true);
    mv_contract.set_prediction_market(mock_prediction_market);
    let prediction_market = mv_contract.get_prediction_market();
    assert!(prediction_market == mock_prediction_market, "Market not set correctly");
}


#[test]
#[should_panic(expected: ('Caller is missing role',))]
fn test_set_prediction_should_panic_when_called_by_non_owner() {
    let mock_erc20 = test_address();
    let fee_collector = test_address();
    let owner = test_address();
    let admin = test_address();
    let mock_prediction_market = test_address();
    let mv_contract = deploy_market_validator(
        test_address(), // PredictionMarket address (mock for now)
        100_u256, 86400, 10, owner,
    );
    let pm_contract = deploy_prediction_market(
        mock_erc20, fee_collector, 500_u256, mv_contract.contract_address,
    );

    start_cheat_caller_address(mv_contract.contract_address, RANDOM_ADDRESS());
    mv_contract.set_prediction_market(mock_prediction_market);
    stop_cheat_caller_address(mv_contract.contract_address);
}
