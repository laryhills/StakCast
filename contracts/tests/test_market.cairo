use snforge_std::{
    declare, ContractClassTrait, DeclareResultTrait, spy_events, EventSpyAssertionsTrait,
    start_cheat_caller_address, test_address, start_cheat_block_timestamp,
};

use starknet::ContractAddress;
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use stakcast::interface::{
    IPredictionMarketDispatcher, IPredictionMarketDispatcherTrait, IMarketValidatorDispatcher,
    IMarketValidatorDispatcherTrait, ValidatorInfo,
};
use stakcast::market::MarketValidator::{Event, MarketResolved, ValidatorSlashed,  };
use stakcast::interface::MarketStatus;
use stakcast::market::MarketValidator;
// Helper to deploy ERC20Upgradeable
fn deploy_erc20_upgradeable(
    name: ByteArray,
    symbol: ByteArray,
    decimals: u8,
    owner: ContractAddress,
) -> IERC20Dispatcher {
    let declare_result = declare("ERC20Upgradeable").unwrap();
    let contract_class = declare_result.contract_class();

    // Create the constructor arguments array
    let mut constructor_args = array![
        decimals.into(), // Decimals (u8 -> felt252)
        owner.into(),    // Owner (ContractAddress -> felt252)
    ];

    // Serialize the `name` ByteArray
    name.serialize(ref constructor_args);

    // Serialize the `symbol` ByteArray
    symbol.serialize(ref constructor_args);

    // Deploy the contract
    let (address, _) = contract_class.deploy(@constructor_args).unwrap();

    // Return the standard ERC20 dispatcher
    IERC20Dispatcher { contract_address: address }
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
        platform_fee.low.into(),
        platform_fee.high.into(),
        market_validator.into(),
    ];
    let (address, _) = contract_class.deploy(@constructor_args).unwrap();
    IPredictionMarketDispatcher { contract_address: address }
}

// Helper to deploy MarketValidator
fn deploy_market_validator(
    prediction_market: ContractAddress,
    stake_token_address: ContractAddress,
    min_stake: u128,
    resolution_timeout: u64,
    slash_percentage: u64,
    owner: ContractAddress,
) -> IMarketValidatorDispatcher {
    let declare_result = declare("MarketValidator").unwrap();
    let contract_class = declare_result.contract_class();
    let constructor_args = array![
        prediction_market.into(),
        stake_token_address.into(),
        min_stake.into(),
        resolution_timeout.into(),
        slash_percentage.into(),
        owner.into(),
    ];
    let (address, _) = contract_class.deploy(@constructor_args).unwrap();
    IMarketValidatorDispatcher { contract_address: address }
}

// Test: Register Validator
#[test]
fn test_register_validator() {
    // Deploy ERC20 token
    let erc20_owner = test_address();
    let erc20 = deploy_erc20_upgradeable("MyToken", "MTK", 18, erc20_owner);
    let stake_token_address = erc20.contract_address;

    // Deploy PredictionMarket
    let pm_owner = test_address();
    let pm_contract = deploy_prediction_market(
        stake_token_address,
        pm_owner,
        500_u256, // 5% fee
        test_address(), // Placeholder for validator
    );

    // Deploy MarketValidator with REAL PredictionMarket address
    let mv_owner = test_address();
    let validator_contract = deploy_market_validator(
        pm_contract.contract_address,
        stake_token_address,
        100_u128, // min_stake
        86400,    // resolution_timeout
        10,       // slash_percentage
        mv_owner,
    );

    // Update PredictionMarket with MarketValidator address
    pm_contract.set_market_validator(validator_contract.contract_address);

    // Fund validator and approve MarketValidator
    let validator = test_address();
    start_cheat_caller_address(erc20.contract_address, erc20_owner);
    erc20.mint(validator, 1000_u256); // Mint tokens
    start_cheat_caller_address(erc20.contract_address, validator);
    erc20.approve(validator_contract.contract_address, 1000_u256); // Approve

    // Register validator (no mocks needed)
    start_cheat_caller_address(validator_contract.contract_address, validator);
    let mut spy = spy_events();
    validator_contract.register_validator(200_u256);

    // Verify registration
    let info = validator_contract.get_validator_info(validator);
    assert_eq!(info.stake, 200_u256, "Incorrect stake");
    assert!(info.active, "Validator should be active");

    // Verify emitted event
    spy.assert_emitted(
        @array![
            (
                validator_contract.contract_address,
                MarketValidator::Event::ValidatorRegistered(
                    MarketValidator::ValidatorRegistered {
                        validator: validator,
                        stake: 200_u256,
                    },
                ),
            ),
        ],
    );
}
// Test: Resolve Market
#[test]
fn test_resolve_market() {
    // Deploy ERC20 token
    let erc20_owner = test_address();
    let erc20 = deploy_erc20_upgradeable("MyToken", "MTK", 18, erc20_owner);
    let stake_token_address = erc20.contract_address;

    // Deploy PredictionMarket
    let pm_owner = test_address();
    let pm_contract = deploy_prediction_market(
        stake_token_address,
        pm_owner,
        500_u256, // 5% fee
        test_address(), // Placeholder for validator
    );

    // Deploy MarketValidator with REAL PredictionMarket address
    let mv_owner = test_address();
    let validator_contract = deploy_market_validator(
        pm_contract.contract_address,
        stake_token_address,
        100_u128, // min_stake
        86400,    // resolution_timeout
        10,       // slash_percentage
        mv_owner,
    );

    // Update PredictionMarket with MarketValidator address
    pm_contract.set_market_validator(validator_contract.contract_address);

    // Register validator
    let validator = test_address();
    start_cheat_caller_address(erc20.contract_address, erc20_owner);
    erc20.mint(validator, 1000_u256);
    start_cheat_caller_address(erc20.contract_address, validator);
    erc20.approve(validator_contract.contract_address, 1000_u256);
    start_cheat_caller_address(validator_contract.contract_address, validator);
    validator_contract.register_validator(200_u256);

    // Create a market via PredictionMarket
    start_cheat_caller_address(pm_contract.contract_address, pm_owner);
    let outcomes = array!['Yes', 'No'];
    let market_id = pm_contract.create_market(
        "Test Market",
        "",
        "Category",
        2000,
        3000,
        outcomes,
        100_u256,
        1000_u256,
    );

    // Resolve market (no mocks)
    start_cheat_block_timestamp(validator_contract.contract_address, 3500);
    start_cheat_caller_address(validator_contract.contract_address, validator);
    let mut spy = spy_events();
    validator_contract.resolve_market(market_id, 0, 'Resolution details');

    // Verify via PredictionMarket's state
    let details = pm_contract.get_market_details(market_id);
    assert_eq!(details.status, MarketStatus::Resolved);
    spy.assert_emitted(
        @array![
            (
                validator_contract.contract_address,
                Event::MarketResolved(
                    MarketResolved  {
                        market_id,
                        resolver: validator,
                        resolution_time: 3500,
                    },
                )
               
            ),
        ],
    );
}

// Test: Slash Validator
#[test]
fn test_slash_validator() {
    // Deploy ERC20 token
    let erc20_owner = test_address();
    let erc20 = deploy_erc20_upgradeable("MyToken", "MTK", 18, erc20_owner);
    let stake_token_address = erc20.contract_address;

    // Deploy PredictionMarket
    let pm_owner = test_address();
    let pm_contract = deploy_prediction_market(
        stake_token_address,
        pm_owner,
        500_u256, // 5% fee
        test_address(), // Placeholder for validator
    );

    // Deploy MarketValidator with REAL PredictionMarket address
    let mv_owner = test_address();
    let validator_contract = deploy_market_validator(
        pm_contract.contract_address,
        stake_token_address,
        100_u128, // min_stake
        86400,    // resolution_timeout
        10,       // slash_percentage
        mv_owner,
    );

    // Update PredictionMarket with MarketValidator address
    pm_contract.set_market_validator(validator_contract.contract_address);

    // Register validator
    let validator = test_address();
    start_cheat_caller_address(erc20.contract_address, erc20_owner);
    erc20.mint(validator, 1000_u256);
    start_cheat_caller_address(erc20.contract_address, validator);
    erc20.approve(validator_contract.contract_address, 1000_u256);
    start_cheat_caller_address(validator_contract.contract_address, validator);
    validator_contract.register_validator(200_u256);

    // Slash validator
    start_cheat_caller_address(validator_contract.contract_address, pm_owner);
    let mut spy = spy_events();
    validator_contract.slash_validator(validator, 0_u256, 'Test slash');

    // Verify
    let info = validator_contract.get_validator_info(validator);
    let slashed_amount = (200_u256 * 10_u256) / 100_u256;
    assert_eq!(info.stake, 200_u256 - slashed_amount);
    spy.assert_emitted(
        @array![
            (
                validator_contract.contract_address,
                Event::ValidatorSlashed(
                    ValidatorSlashed{
                        validator,
                        amount: slashed_amount,
                        reason: 'Test slash',
                    },
                ) 
            ),
        ],
    );
}