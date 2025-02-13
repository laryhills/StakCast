use starknet::ContractAddress;

// Re-export data structures for external use
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
#[allow(starknet::store_no_default_variant)]
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

// Custom struct to replace the tuple (Market, MarketStatus, Option<MarketOutcome>)
#[derive(Serde, starknet::Store)]
pub struct MarketDetails {
    pub market: Market,
    pub status: MarketStatus,
    pub outcome: Option<MarketOutcome>,
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
    ) -> MarketDetails;

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