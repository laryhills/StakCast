#[starknet::contract]
mod PredictionMarket {
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::get_block_timestamp;
    use core::array::ArrayTrait;
    use core::option::OptionTrait;
    use openzeppelin::token::erc20::interface::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry, Map,
    };

    // Data Structures
    #[derive(Drop, Serde, starknet::Store)]
    struct Market {
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

    #[derive(Copy, Serde, starknet::Store)]
    struct Position {
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
    struct MarketOutcome {
        pub winning_outcome: u32,
        pub resolution_details: felt252,
    }

    #[derive(Drop, Serde, starknet::Store)]
    struct MarketDetails {
        pub market: Market,
        pub status: MarketStatus,
        pub outcome: Option<MarketOutcome>,
    }

    // Storage
    #[storage]
    struct Storage {
        markets: Map<u32, Market>,
        market_count: u32,
        positions: Map<(u32, ContractAddress), Position>,
        market_outcomes: Map<(u32, u32), felt252>, // (market_id, outcome_index) -> outcome
        stakes_per_outcome: Map<(u32, u32), u256>, // (market_id, outcome_index) -> stake
        platform_fee: u256,
        fee_collector: ContractAddress,
        stake_token: ContractAddress,
        market_validator: ContractAddress,
        validator_index: u32,
        market_categories: Map<felt252, Array<u32>>,
        market_status: Map<u32, MarketStatus>,
    }

    // Events
    #[derive(Drop, starknet::Event)]
    struct MarketCreated {
        pub market_id: u32,
        pub creator: ContractAddress,
        pub title: felt252,
        pub start_time: u64,
        pub end_time: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct PositionTaken {
        pub market_id: u32,
        pub user: ContractAddress,
        pub outcome_index: u32,
        pub amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct MarketResolved {
        pub market_id: u32,
        pub outcome: u32,
        pub resolver: ContractAddress,
        pub resolution_details: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct WinningsClaimed {
        pub market_id: u32,
        pub user: ContractAddress,
        pub amount: u256,
    }

    #[derive(Drop, starknet::Event)]
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

    // Constructor
    #[constructor]
    fn constructor(
        ref self: ContractState,
        stake_token_address: ContractAddress,
        fee_collector: ContractAddress,
        platform_fee: u256,
        market_validator_address: ContractAddress,
    ) {
        self.stake_token.write(stake_token_address);
        self.fee_collector.write(fee_collector);
        self.platform_fee.write(platform_fee);
        self.market_validator.write(market_validator_address);
        self.validator_index.write(0);
    }

    // External Implementation
    #[external(v0)]
    #[abi(embed_v0)]
    impl PredictionMarketImp of IPredictionMarket<ContractState> {
        fn get_market_details(
            self: @ContractState,
            market_id: u32,
        ) -> MarketDetails {
            let market = self.markets.read(market_id);
            let status = self.market_status.read(market_id);
            let outcome = self.market_outcomes.read(market_id);

            MarketDetails {
                market,
                status,
                outcome,
            }
        }

        fn get_user_position(
            self: @ContractState,
            user: ContractAddress,
            market_id: u32,
        ) -> Position {
            self.positions.read((market_id, user))
        }

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

            // Input validation
            assert(start_time > current_time, 'Invalid start time');
            assert(end_time > start_time, 'Invalid end time');
            assert(outcomes.len() >= 2, 'Minimum 2 outcomes required');
            assert(min_stake > 0, 'Min stake must be > 0');
            assert(max_stake >= min_stake, 'Max stake < min stake');

            // Get and increment market count
            let market_id = self.market_count.read() + 1;
            self.market_count.write(market_id);

            // Store outcomes in Map
            let mut i = 0;
            while i < outcomes.len() {
                self.market_outcomes.write((market_id, i), *outcomes.at(i));
                self.stakes_per_outcome.write((market_id, i), 0); // Initialize stakes to 0
                i += 1;
            }

            // Create market
            let market = Market {
                creator: caller,
                title,
                description,
                category,
                start_time,
                end_time,
                resolution_time: end_time + 86400, // 24h resolution window
                total_stake: 0,
                min_stake,
                max_stake,
                validator: 0.into(), // Will be assigned by assign_validator
            };

            // Write to storage
            self.markets.write(market_id, market);
            self.market_status.write(market_id, MarketStatus::Active);

            // Assign a random validator
            self.assign_validator(market_id);

            // Update category index
            let mut category_markets = self.market_categories.read(category);
            category_markets.append(market_id);
            self.market_categories.write(category, category_markets);

            // Emit event
            self.emit(MarketCreated {
                market_id,
                creator: caller,
                title,
                start_time,
                end_time,
            });

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
            let current_time = get_block_timestamp();

            // Validation
            assert(amount >= market.min_stake, 'Below min stake');
            assert(amount <= market.max_stake, 'Above max stake');
            assert(outcome_index < outcomes.len(), 'Invalid outcome');
            assert(
                self.market_status.read(market_id) == MarketStatus::Active,
                'Market not active'
            );
            assert(current_time >= market.start_time, 'Market not started');
            assert(current_time < market.end_time, 'Market ended');

            // Transfer tokens
            let stake_token = IERC20Dispatcher { 
                contract_address: self.stake_token.read() 
            };
            stake_token.transfer_from(caller, self.contract_address(), amount);

            // Update position
            let mut position = self.positions.read((market_id, caller));
            position.amount += amount;
            position.outcome_index = outcome_index;
            self.positions.write((market_id, caller), position);

            // Update market
            let mut market = self.markets.read(market_id);
            market.total_stake += amount;
            market.stakes_per_outcome[outcome_index] += amount;
            self.markets.write(market_id, market);

            self.emit(PositionTaken {
                market_id,
                user: caller,
                outcome_index,
                amount,
            });
        }

        fn claim_winnings(ref self: ContractState, market_id: u32) {
            let caller = get_caller_address();
            let market = self.markets.read(market_id);
            let status = self.market_status.read(market_id);
            let outcome = self.market_outcomes.read(market_id);
            let mut position = self.positions.read((market_id, caller));

            // Validation
            assert(status == MarketStatus::Resolved, 'Market not resolved');
            assert(outcome.is_some(), 'No resolution recorded');
            assert(position.amount > 0, 'No position to claim');
            assert(!position.claimed, 'Already claimed');

            let winning_outcome = outcome.unwrap().winning_outcome;
            let mut winnings = 0;

            if position.outcome_index == winning_outcome {
                let total_winning_stake = market.stakes_per_outcome[winning_outcome];
                winnings = (position.amount * market.total_stake) / total_winning_stake;
                let fee = (winnings * self.platform_fee.read()) / 10000;

                let stake_token = IERC20Dispatcher { 
                    contract_address: self.stake_token.read() 
                };

                if winnings > fee {
                    stake_token.transfer(caller, winnings - fee);
                    stake_token.transfer(self.fee_collector.read(), fee);
                }
            }

            position.claimed = true;
            self.positions.write((market_id, caller), position);

            self.emit(WinningsClaimed {
                market_id,
                user: caller,
                amount: winnings,
            });
        }

        fn resolve_market(
            ref self: ContractState,
            market_id: u32,
            winning_outcome: u32,
            resolution_details: felt252,
        ) {
            let caller = get_caller_address();
            let market = self.markets.read(market_id);
            let current_time = get_block_timestamp();

            // Validation
            assert(
                caller == market.validator,
                'Only assigned validator can resolve'
            );
            assert(
                current_time >= market.end_time,
                'Market not yet ended'
            );
            assert(
                current_time <= market.resolution_time,
                'Resolution period expired'
            );
            assert(
                winning_outcome < market.outcomes.len(),
                'Invalid winning outcome'
            );

            self.market_outcomes.write(market_id, Option::Some(MarketOutcome {
                winning_outcome,
                resolution_details,
            }));

            self.market_status.write(market_id, MarketStatus::Resolved);

            self.emit(MarketResolved {
                market_id,
                winning_outcome,
                resolver: caller,
                resolution_details,
            });
        }

        fn get_market_stats(
            self: @ContractState,
            market_id: u32,
        ) -> (u256, Array<u256>) {
            let market = self.markets.read(market_id);
            (market.total_stake, market.stakes_per_outcome)
        }

        fn dispute_market(
            ref self: ContractState,
            market_id: u32,
            reason: felt252,
        ) {
            let caller = get_caller_address();
            assert(
                self.market_status.read(market_id) == MarketStatus::Resolved,
                'Market not resolved'
            );
            self.market_status.write(market_id, MarketStatus::Disputed);
            self.emit(MarketDisputed {
                market_id,
                disputer: caller,
                reason,
            });
        }

        fn cancel_market(
            ref self: ContractState,
            market_id: u32,
            reason: felt252,
        ) {
            let caller = get_caller_address();
            let market = self.markets.read(market_id);
            assert(
                caller == market.creator,
                'Only market creator can cancel'
            );
            assert(
                self.market_status.read(market_id) == MarketStatus::Active,
                'Market not active'
            );
            self.market_status.write(market_id, MarketStatus::Cancelled);
        }
    }

    // Internal Implementation
    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn get_random_validator(self: @TContractState) -> ContractAddress {
            let validator_contract = IMarketValidatorDispatcher {
                contract_address: self.market_validator.read()
            };
            let validators = validator_contract.get_validators_array();

            // Fallback to fee collector if no validators are registered
            if validators.len() == 0 { // Explicitly use ArrayTrait::len
                return self.fee_collector.read();
            }

            // Use validator_index to cycle through validators
            let index = self.validator_index.read() % validators.len(); // Explicitly use ArrayTrait::len
            self.validator_index.write(index + 1); // Increment for next assignment
            validators[index]
        }
    }
}