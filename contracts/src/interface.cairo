use starknet::ContractAddress;
use core::array::ArrayTrait;
use core::option::OptionTrait;
use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry, Map};

// Data Structures
#[derive(Drop, Serde, starknet::Store)]
pub struct Market {
    pub creator: ContractAddress,
    pub title: felt252,
    pub description: felt252,
    pub category: felt252,
    pub start_time: u64,
    pub end_time: u64,
    pub resolution_time: u64,
    pub total_stake: u256,
    pub min_stake: u256,
    pub max_stake: u256,
    pub validator: ContractAddress,
}

#[storage]
struct Storage {
    markets: Map<u32, Market>,
    market_outcomes: Map<(u32, u32), felt252>, // (market_id, outcome_index) -> outcome
    stakes_per_outcome: Map<(u32, u32), u256>, // (market_id, outcome_index) -> stake
    admin: ContractAddress, // Admin address for access control
    stake_token: ContractAddress, // Stake token address
}

#[derive(Copy, Serde, starknet::Store)]
pub struct Position {
    pub amount: u256,
    pub outcome_index: u32,
    pub claimed: bool,
}

#[derive(Drop, Copy, Serde, starknet::Store)]
#[allow(starknet::store_no_default_variant)]
pub enum MarketStatus {
    Active,
    Closed,
    Resolved,
    Disputed,
    Cancelled,
}

#[derive(Copy, Drop, Serde, starknet::Store)]
pub struct MarketOutcome {
    winning_outcome: u32,
    resolution_details: felt252,
}

#[derive(Copy, Drop, Serde, starknet::Store)]
pub struct ValidatorInfo {
    pub stake: u256,
    pub markets_resolved: u32,
    pub accuracy_score: u32,
    pub active: bool,
}

// New Struct for Market Details
#[derive(Drop, Serde, starknet::Store)]
pub struct MarketDetails {
    pub market: Market,
    pub status: MarketStatus,
    pub outcome: Option<MarketOutcome>,
}

// Interfaces
#[starknet::interface]
pub trait IPredictionMarket<TContractState> {
    // Market Operations
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

    fn take_position(
        ref self: TContractState,
        market_id: u32,
        outcome_index: u32,
        amount: u256,
    );

    fn claim_winnings(ref self: TContractState, market_id: u32);
    
    // Getters
    fn get_market_details(
        self: @TContractState,
        market_id: u32,
    ) -> MarketDetails;

    fn get_user_position(
        self: @TContractState,
        user: ContractAddress,
        market_id: u32,
    ) -> Position;

    fn get_market_stats(
        self: @TContractState,
        market_id: u32,
    ) -> (u256, Array<u256>);

    fn get_stake_token(
        self: @TContractState,
    ) -> ContractAddress; // New function to get stake token address

    // Administration
    fn assign_validator(
        ref self: TContractState,
        market_id: u32,
    );

    fn resolve_market(
        ref self: TContractState,
        market_id: u32,
        winning_outcome: u32,
        resolution_details: felt252,
    );

    fn dispute_market(
        ref self: TContractState,
        market_id: u32,
        reason: felt252,
    );

    fn cancel_market(
        ref self: TContractState,
        market_id: u32,
        reason: felt252,
    );
}

#[starknet::interface]
pub trait IMarketValidator<TContractState> {
    // Validator Operations
    fn register_validator(ref self: TContractState, stake: u256);
    
    fn resolve_market(
        ref self: TContractState,
        market_id: u32,
        winning_outcome: u32,
        resolution_details: felt252,
    );

    fn slash_validator(
        ref self: TContractState,
        validator: ContractAddress,
        amount: u256,
        reason: felt252,
    );

    // Getters
    fn get_validator_info(
        self: @TContractState,
        validator: ContractAddress,
    ) -> ValidatorInfo;

    fn is_active_validator(
        self: @TContractState,
        validator: ContractAddress,
    ) -> bool;

    fn get_validators_array(
        self: @TContractState,
    ) -> Array<ContractAddress>;
}

#[starknet::interface]
pub trait IERC20<TContractState> {
    // Token Operations
    fn transfer(
        ref self: TContractState,
        recipient: ContractAddress,
        amount: u256,
    ) -> bool;

    fn transfer_from(
        ref self: TContractState,
        sender: ContractAddress,
        recipient: ContractAddress,
        amount: u256,
    ) -> bool;

    // Getters
    fn balance_of(
        self: @TContractState,
        owner: ContractAddress,
    ) -> u256;

    fn allowance(
        self: @TContractState,
        owner: ContractAddress,
        spender: ContractAddress,
    ) -> u256;
}

// Events
#[derive(Drop, starknet::Event)]
pub struct MarketCreated {
    pub market_id: u32,
    pub creator: ContractAddress,
    pub title: felt252,
    pub start_time: u64,
    pub end_time: u64,
    pub min_stake: u256,
    pub max_stake: u256,
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

#[derive(Copy, Drop, starknet::Event)]
struct MarketDisputed {
    pub market_id: u32,
    pub disputer: ContractAddress,
    pub reason: felt252,
}

#[event]
#[derive(Drop, starknet::Event)]
enum Event {
    MarketCreated: MarketCreated,
    PositionTaken: PositionTaken,
    MarketResolved: MarketResolved,
    WinningsClaimed: WinningsClaimed,
    MarketDisputed: MarketDisputed,
}

