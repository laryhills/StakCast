// Expose the `constants` module for shared constants
pub mod constants {
    pub const MIN_OUTCOMES: u32 = 2;
    pub const RESOLUTION_WINDOW: u64 = 86400; // 24 hours in seconds
    pub const BASIS_POINTS: u256 = 10000_u256;
    pub const MIN_STAKE: u256 = 100_u256;
    pub const RESOLUTION_TIMEOUT: u64 = 86400; // 24 hours in seconds
}

// Expose the `events` module for shared events
pub mod events {
    use starknet::ContractAddress;

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
}

// Expose the `utils` module for shared utility functions
pub mod utils {
    use super::constants;

    use starknet::get_block_timestamp;

    // Check if a market is active
    pub fn is_market_active(start_time: u64, end_time: u64) -> bool {
        let current_time = get_block_timestamp();
        current_time >= start_time && current_time < end_time
    }

    // Calculate platform fee
    pub fn calculate_fee(amount: u256, fee_bps: u256) -> u256 {
        (amount * fee_bps) / constants::BASIS_POINTS
    }
}