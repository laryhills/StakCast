#[derive(Drop, Serde, starknet::Store, Clone)]
pub struct PredictionMarket {
    pub title: ByteArray,
    pub market_id: u256,
    pub description: ByteArray,
    pub choices: (Choice, Choice),
    pub category: felt252,
    pub is_resolved: bool,
    pub is_open: bool,
    pub end_time: u64,
    pub winning_choice: Option<Choice>,
    pub total_shares_option_one: u256,
    pub total_shares_option_two: u256,
    pub total_pool: u256,
    pub prediction_market_type: u8, // 0 - normal predicion market, 1 - crypto prediction market, 2 - sports prediction, 3 - buisness market
    pub crypto_prediction: Option<
        (felt252, u128),
    >, // the crypto asset (e.g., BTC, ETH) | target_value:  Target price value for the prediction
    /// @dev depreciated
    pub sports_prediction: Option<(u64, bool)>,
}

// ================ Supporting Types ================

/// Represents a choice in a prediction market with its associated stake
#[derive(Copy, Serde, Drop, starknet::Store, PartialEq, Hash)]
pub struct Choice {
    pub label: felt252, // Text label for the choice
    pub staked_amount: u256 // Total amount staked on this choice
}

/// Represents a user's stake in a prediction market
#[derive(Drop, Serde, starknet::Store)]
pub struct UserStake {
    pub amount: u256, // Amount staked by the user
    pub claimed: bool // Whether the user has claimed their winnings
}

/// Represents a user's bet on a specific choice in a market
#[derive(Drop, Serde, starknet::Store)]
pub struct UserBet {
    pub choice: Choice, // The choice the user bet on
    pub stake: UserStake // The user's stake details
}
