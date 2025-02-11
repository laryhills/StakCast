use starknet::ContractAddress;
use starknet::get_caller_address;
use starknet::get_block_timestamp;
use core::option::OptionTrait;

// Re-export data structures for external use
#[derive(Drop, Copy, Serde, starknet::Store)]
pub struct Market {
    creator: ContractAddress,
    title: felt252,
    description: felt252,
    category: felt252,
    start_time: u64,
    end_time: u64,
    resolution_time: u64,
    total_stake: u256,
    outcomes: Array<felt252>,
    stakes_per_outcome: Array<u256>,
    min_stake: u256,
    max_stake: u256,
    validator: ContractAddress,
}

#[derive(Drop, Copy, Serde, starknet::Store)]
pub struct Position {
    amount: u256,
    outcome_index: u32,
    claimed: bool,
}

#[derive(Drop, Copy, Serde, starknet::Store)]
pub enum MarketStatus {
    Active,
    Closed,
    Resolved,
    Disputed,
    Cancelled,
}

#[derive(Drop, Copy, Serde, starknet::Store)]
pub struct MarketOutcome {
    winning_outcome: u32,
    resolution_details: felt252,
}

#[derive(Drop, Copy, Serde, starknet::Store)]
pub struct ValidatorInfo {
    stake: u256,
    markets_resolved: u32,
    accuracy_score: u32,
    active: bool,
}

// Interface for Prediction Market operations
#[starknet::interface]
pub trait IPredictionMarket<TContractState> {
    // Creates a new prediction market
    fn create_market(
        ref self: TContractState,
        title: felt252,
        description: felt252,
        category: felt252,
        start_time: u64,
        end_time: u64,
        outcomes: Array<felt252>,
        min_stake: u256,
        max_stake: u256,
    ) -> u32;

    // Takes a position in a market
    fn take_position(
        ref self: TContractState,
        market_id: u32,
        outcome_index: u32,
        amount: u256,
    );

    // Claims winnings from a resolved market
    fn claim_winnings(ref self: TContractState, market_id: u32);

    // Gets details of a specific market
    fn get_market_details(
        self: @TContractState,
        market_id: u32,
    ) -> (Market, MarketStatus, Option<MarketOutcome>);

    // Gets a user's position in a specific market
    fn get_user_position(
        self: @TContractState,
        user: ContractAddress,
        market_id: u32,
    ) -> Position;

    // Gets statistics for a specific market
    fn get_market_stats(
        self: @TContractState,
        market_id: u32,
    ) -> (u256, Array<u256>);
}

// Interface for Market Validator operations
#[starknet::interface]
pub trait IMarketValidator<TContractState> {
    // Registers a new validator
    fn register_validator(ref self: TContractState, stake: u256);

    // Resolves a market
    fn resolve_market(
        ref self: TContractState,
        market_id: u32,
        winning_outcome: u32,
        resolution_details: felt252,
    );

    // Slashes a validator for misbehavior
    fn slash_validator(
        ref self: TContractState,
        validator: ContractAddress,
        amount: u256,
        reason: felt252,
    );

    // Gets information about a validator
    fn get_validator_info(
        self: @TContractState,
        validator: ContractAddress,
    ) -> ValidatorInfo;

    // Checks if a validator is active
    fn is_active_validator(
        self: @TContractState,
        validator: ContractAddress,
    ) -> bool;
}

// Interface for ERC20 token operations
#[starknet::interface]
pub trait IERC20<TContractState> {
    // Transfers tokens from the caller to another address
    fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256);

    // Transfers tokens from one address to another on behalf of the caller
    fn transfer_from(
        ref self: TContractState,
        sender: ContractAddress,
        recipient: ContractAddress,
        amount: u256,
    );

    // Gets the balance of an address
    fn balance_of(self: @TContractState, owner: ContractAddress) -> u256;
}

// Events
#[derive(Drop, starknet::Event)]
pub struct MarketCreated {
    pub market_id: u32,
    pub creator: ContractAddress,
    pub title: felt252,
    pub start_time: u64,
    pub end_time: u64,
}

#[derive(Drop, starknet::Event)]
pub struct PositionTaken {
    pub market_id: u32,
    pub user: ContractAddress,
    pub outcome_index: u32,
    pub amount: u256,
}

#[derive(Drop, starknet::Event)]
pub struct MarketResolved {
    pub market_id: u32,
    pub outcome: u32,
    pub resolver: ContractAddress,
    pub resolution_details: felt252,
}

#[derive(Drop, starknet::Event)]
pub struct WinningsClaimed {
    pub market_id: u32,
    pub user: ContractAddress,
    pub amount: u256,
}

#[derive(Drop, starknet::Event)]
pub struct ValidatorRegistered {
    pub validator: ContractAddress,
    pub stake: u256,
}

#[derive(Drop, starknet::Event)]
pub struct ValidatorSlashed {
    pub validator: ContractAddress,
    pub amount: u256,
    pub reason: felt252,
}