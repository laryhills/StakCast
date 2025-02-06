use super::interfaces::{IPredictionMarketDispatcher, IMarketValidatorDispatcher, IERC20Dispatcher};

#[derive(Drop, Copy, Serde, starknet::Store)]
pub struct ValidatorInfo {
    pub stake: u256,
    pub markets_resolved: u32,
    pub accuracy_score: u32,
    pub active: bool,
}

#[derive(Drop, Copy, Serde, starknet::Store)]
pub struct Market {
    pub creator: ContractAddress,
    pub title: felt252,
    pub description: felt252,
    pub category: felt252,
    pub start_time: u64,
    pub end_time: u64,
    pub resolution_time: u64,
    pub total_stake: u256,
    pub outcomes: Array<felt252>,
    pub stakes_per_outcome: Array<u256>,
    pub min_stake: u256,
    pub max_stake: u256,
    pub validator: ContractAddress,
}

#[derive(Drop, Copy, Serde, starknet::Store)]
pub struct Position {
    pub amount: u256,
    pub outcome_index: u32,
    pub claimed: bool,
}

#[derive(Drop, Copy, Serde, starknet::Store)]
pub struct MarketOutcome {
    pub winning_outcome: u32,
    pub resolution_details: felt252,
}

#[derive(Drop, Copy, Serde, starknet::Store)]
pub enum MarketStatus {
    Active,
    Closed,
    Resolved,
    Disputed,
    Cancelled
}

// Shared Events
#[derive(Drop, starknet::Event)]
pub struct ValidatorRegistered {
    pub validator: ContractAddress,
    pub stake: u256,
}

#[derive(Drop, starknet::Event)]
pub struct MarketResolved {
    pub market_id: u32,
    pub outcome: u32,
    pub resolver: ContractAddress,
    pub resolution_details: felt252,
}

#[derive(Drop, starknet::Event)]
pub struct ValidatorSlashed {
    pub validator: ContractAddress,
    pub amount: u256,
    pub reason: felt252,
}

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
pub struct WinningsClaimed {
    pub market_id: u32,
    pub user: ContractAddress,
    pub amount: u256,
}

// Utility functions
pub mod utils {
    use super::MarketStatus;
    use starknet::get_block_timestamp;
    
    pub fn is_market_active(start_time: u64, end_time: u64) -> bool {
        let current_time = get_block_timestamp();
        current_time >= start_time && current_time < end_time
    }

    pub fn calculate_fee(amount: u256, fee_bps: u256) -> u256 {
        (amount * fee_bps) / 10000_u256
    }
}

// Validation constants
pub mod constants {
    pub const MIN_OUTCOMES: u32 = 2;
    pub const RESOLUTION_WINDOW: u64 = 86400;  //24 hours
    pub const BASIS_POINTS: u256 = 10000_u256;
}