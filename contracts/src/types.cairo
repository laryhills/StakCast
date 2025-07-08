#[derive(Drop, Serde, starknet::Store, Clone)]
pub struct PredictionMarket {
    pub title: ByteArray, // Market title/question
    pub market_id: u256, // Unique identifier for the market
    pub description: ByteArray, // Detailed description of the prediction
    pub choices: (Choice, Choice), // Binary choices (typically Yes/No)
    pub category: felt252, // Category identifier for market classification
    pub image_url: ByteArray, // URL to market image/icon
    pub is_resolved: bool, // Whether the market has been resolved
    pub is_open: bool, // Whether the market is accepting new bets
    pub end_time: u64, // Timestamp when the market closes
    pub winning_choice: Option<Choice>, // The winning choice after resolution
    // logic - if total pool is 0 then its a normal prediction, and crpto prediction has to
    pub total_pool: u256, // Total amount staked in the market
    pub prediction_market_type: u8, // 0 - normal predicion market, 1 - crypto prediction market, 2 - sports prediction, 3 - buisness market
    //Some((asset_key target_value))
    //the crypto asset (e.g., BTC, ETH) | target_value:  Target price value for the prediction
    pub crypto_prediction: Option<(felt252, u128)>, // Optional crypto prediction details
    //Some((event_id,team_flag))
    // event_id: External API event ID for automatic resolution | team_flag: Flag indicating if this
    // is a team-based prediction
    pub sports_prediction: Option<(u64, bool)> // Optional sports prediction details
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
