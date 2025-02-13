use starknet::ContractAddress;
use core::array::ArrayTrait;
use core::option::OptionTrait;

// Data Structures
#[derive(Copy, Drop, Serde, starknet::Store)]
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

#[derive(Copy, Serde, starknet::Store)]
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

#[derive(Copy, Serde, starknet::Store)]
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
    ) -> (Market, MarketStatus, Option<MarketOutcome>);

    fn get_user_position(
        self: @TContractState,
        user: ContractAddress,
        market_id: u32,
    ) -> Position;

    fn get_market_stats(
        self: @TContractState,
        market_id: u32,
    ) -> (u256, Array<u256>);

    // Administration
    fn assign_validator(
        ref self: TContractState,
        market_id: u32,
        validator: ContractAddress,
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