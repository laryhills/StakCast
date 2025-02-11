#[starknet::contract]
mod PredictionMarket {
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::get_block_timestamp;
    use core::option::OptionTrait;
    use openzeppelin::token::erc20::dual20::{DualCaseERC20, DualCaseERC20Trait};

    // Import the IPredictionMarket and IERC20 interfaces
    use super::interface::{IPredictionMarket, IERC20};

    #[storage]
    struct Storage {
        markets: Map<u32, Market>,
        market_count: u32,
        positions: Map<(u32, ContractAddress), Position>,
        market_outcomes: Map<u32, Option<MarketOutcome>>,
        platform_fee: u256, // Fee in basis points (e.g., 100 = 1%)
        fee_collector: ContractAddress,
        stake_token: ContractAddress,
        market_validators: Map<ContractAddress, bool>,
        market_categories: Map<u32, felt252>,
        market_status: Map<u32, MarketStatus>,
    }

    #[derive(Drop, Copy, Serde, starknet::Store)]
    struct Market {
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
    struct Position {
        amount: u256,
        outcome_index: u32,
        claimed: bool,
    }

    #[derive(Drop, Copy, Serde, starknet::Store)]
    enum MarketStatus {
        Active,
        Closed,
        Resolved,
        Disputed,
        Cancelled,
    }

    #[derive(Drop, Copy, Serde, starknet::Store)]
    struct MarketOutcome {
        winning_outcome: u32,
        resolution_details: felt252,
    }

    // Events
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        MarketCreated: MarketCreated,
        PositionTaken: PositionTaken,
        MarketResolved: MarketResolved,
        WinningsClaimed: WinningsClaimed,
        MarketDisputed: MarketDisputed,
        ValidatorAdded: ValidatorAdded,
        ValidatorRemoved: ValidatorRemoved,
    }

    #[derive(Drop, starknet::Event)]
    struct MarketCreated {
        market_id: u32,
        creator: ContractAddress,
        title: felt252,
        start_time: u64,
        end_time: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct PositionTaken {
        market_id: u32,
        user: ContractAddress,
        outcome_index: u32,
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct MarketResolved {
        market_id: u32,
        outcome: u32,
        resolver: ContractAddress,
        resolution_details: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct WinningsClaimed {
        market_id: u32,
        user: ContractAddress,
        amount: u256,
    }

    // Constructor
    #[constructor]
    fn constructor(
        ref self: ContractState,
        stake_token_address: ContractAddress,
        fee_collector: ContractAddress,
        platform_fee: u256,
    ) {
        self.stake_token.write(stake_token_address);
        self.fee_collector.write(fee_collector);
        self.platform_fee.write(platform_fee);
    }

    // Implement the IPredictionMarket interface
    #[external(v0)]
    #[abi (embed_v0)]
    impl PredictionMarketImpl of IPredictionMarket<ContractState> {
        fn create_market(
            ref self: ContractState,
            title: felt252,
            description: felt252,
            category: felt252,
            start_time: u64,
            end_time: u64,
            outcomes: Array<felt252>,
            min_stake: u256,
            max_stake: u256,
        ) -> u32 {
            let caller = get_caller_address();
            let current_time = get_block_timestamp();

            // Validations
            assert(start_time > current_time, 'Invalid start time');
            assert(end_time > start_time, 'Invalid end time');
            assert(outcomes.len() >= 2, 'Min 2 outcomes required');

            let market_id = self.market_count.read() + 1;

            // Initialize stakes array with zeros
            let mut stakes = ArrayTrait::new();
            let mut i = 0;
            loop {
                if i >= outcomes.len() {
                    break;
                }
                stakes.append(0);
                i += 1;
            };

            self
                .markets
                .write(
                    market_id,
                    Market {
                        creator: caller,
                        title: title,
                        description: description,
                        category: category,
                        start_time: start_time,
                        end_time: end_time,
                        resolution_time: end_time + 86400, // 24 hours after end time
                        total_stake: 0,
                        outcomes: outcomes,
                        stakes_per_outcome: stakes,
                        min_stake: min_stake,
                        max_stake: max_stake,
                        validator: self.get_random_validator(),
                    }
                );

            self.market_count.write(market_id);
            self.market_status.write(market_id, MarketStatus::Active);

            self
                .emit(
                    MarketCreated {
                        market_id: market_id,
                        creator: caller,
                        title: title,
                        start_time: start_time,
                        end_time: end_time,
                    }
                );

            market_id
        }

        fn take_position(
            ref self: ContractState,
            market_id: u32,
            outcome_index: u32,
            amount: u256,
        ) {
            let caller = get_caller_address();
            let market = self.markets.read(market_id);

            // Validations
            assert(self.market_status.read(market_id) == MarketStatus::Active, 'Market not active');
            assert(market.start_time <= get_block_timestamp(), 'Market not started');
            assert(market.end_time > get_block_timestamp(), 'Market ended');
            assert(amount >= market.min_stake, 'Below min stake');
            assert(amount <= market.max_stake, 'Above max stake');

            // Transfer tokens using the IERC20 interface
            let stake_token = IERC20Dispatcher { contract_address: self.stake_token.read() };
            stake_token.transfer_from(caller, starknet::get_contract_address(), amount);

            // Update position
            let mut position = self.positions.read((market_id, caller));
            position.amount += amount;
            position.outcome_index = outcome_index;
            self.positions.write((market_id, caller), position);

            // Update market stakes
            let mut market = self.markets.read(market_id);
            market.total_stake += amount;
            market.stakes_per_outcome[outcome_index] += amount;
            self.markets.write(market_id, market);

            self
                .emit(
                    PositionTaken {
                        market_id: market_id,
                        user: caller,
                        outcome_index: outcome_index,
                        amount: amount,
                    }
                );
        }

        fn claim_winnings(ref self: ContractState, market_id: u32) {
            let caller = get_caller_address();
            let market = self.markets.read(market_id);
            let position = self.positions.read((market_id, caller));
            let outcome = self.market_outcomes.read(market_id);

            assert(outcome.is_some(), 'Market not resolved');
            assert(position.amount > 0, 'No position found');
            assert(!position.claimed, 'Already claimed');

            let winning_outcome = outcome.unwrap().winning_outcome;
            let mut winnings = 0_u256;

            if position.outcome_index == winning_outcome {
                // Calculate winnings based on share of winning pool
                let winning_pool = market.stakes_per_outcome[winning_outcome];
                let total_stake = market.total_stake;
                winnings = (position.amount * total_stake) / winning_pool;

                // Apply platform fee
                let fee = (winnings * self.platform_fee.read()) / 10000;
                winnings -= fee;

                // Transfer winnings using the IERC20 interface
                let stake_token = IERC20Dispatcher { contract_address: self.stake_token.read() };
                stake_token.transfer(caller, winnings);

                // Transfer fee to fee collector
                stake_token.transfer(self.fee_collector.read(), fee);
            }

            // Mark position as claimed
            let mut position = self.positions.read((market_id, caller));
            position.claimed = true;
            self.positions.write((market_id, caller), position);

            self.emit(WinningsClaimed { market_id: market_id, user: caller, amount: winnings });
        }

        fn get_market_details(
            self: @ContractState,
            market_id: u32,
        ) -> (Market, MarketStatus, Option<MarketOutcome>) {
            let market = self.markets.read(market_id);
            let status = self.market_status.read(market_id);
            let outcome = self.market_outcomes.read(market_id);
            (market, status, outcome)
        }

        fn get_user_position(
            self: @ContractState,
            user: ContractAddress,
            market_id: u32,
        ) -> Position {
            self.positions.read((market_id, user))
        }

        fn get_market_stats(
            self: @ContractState,
            market_id: u32,
        ) -> (u256, Array<u256>) {
            let market = self.markets.read(market_id);
            (market.total_stake, market.stakes_per_outcome)
        }
    }

    // Helper functions
    fn get_random_validator(self: @ContractState) -> ContractAddress {
        // For now, return the first active validator
        // TODO: Implement proper random selection using VRF
        let mut i = 0;
        loop {
            if i >= self.validator_count.read() {
                break self.fee_collector.read(); // Fallback
            }
            let validator = self.market_validators.read(ContractAddress { value: i });
            if validator {
                break ContractAddress { value: i };
            }
            i += 1;
        }
    }
}