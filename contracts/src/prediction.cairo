#[starknet::contract]
mod PredictionMarket {
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::get_block_timestamp;
    use core::array::ArrayTrait;
    use core::option::OptionTrait;
    use openzeppelin::token::erc20::IERC20Dispatcher;
    use super::{IMarketValidatorDispatcher, MarketStatus, Market, Position, MarketOutcome};
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry, Map,
    };

    #[storage]
    struct Storage {
        markets: Map<u32, Market>,
        market_count: u32,
        positions: Map<(u32, ContractAddress), Position>,
        market_outcomes: Map<u32, Option<MarketOutcome>>,
        platform_fee: u256,
        fee_collector: ContractAddress,
        stake_token: ContractAddress,
        market_validator: ContractAddress,
        market_status: Map<u32, MarketStatus>,
        validator_index: u32,
        market_categories: Map<felt252, Array<u32>>,
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

    #[derive(Drop, starknet::Event)]
    struct MarketCreated {
        market_id: u32,
        creator: ContractAddress,
        title: felt252,
        category: felt252,
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
        winning_outcome: u32,
        resolver: ContractAddress,
        resolution_details: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct WinningsClaimed {
        market_id: u32,
        user: ContractAddress,
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct MarketDisputed {
        market_id: u32,
        disputer: ContractAddress,
        reason: felt252,
    }

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

    #[external(v0)]
    #[abi(embed_v0)]
    impl PredictionMarketImpl of sta::IPredictionMarket<ContractState> {
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

            let market_id = self.market_count.read() + 1;
            let mut stakes = ArrayTrait::new();
            let mut i = 0;
            while i < outcomes.len() {
                stakes.append(0);
                i += 1;
            }

            let validator = self.get_random_validator();

            let market = Market {
                creator: caller,
                title: title,
                description: description,
                category: category,
                start_time: start_time,
                end_time: end_time,
                resolution_time: end_time + 86400, // 24h resolution window
                total_stake: 0,
                outcomes: outcomes,
                stakes_per_outcome: stakes,
                min_stake: min_stake,
                max_stake: max_stake,
                validator: validator,
            };

            self.markets.write(market_id, market);
            self.market_status.write(market_id, MarketStatus::Active);
            self.market_count.write(market_id);

            // Update category index
            let mut category_markets = self.market_categories.read(category);
            category_markets.append(market_id);
            self.market_categories.write(category, category_markets);

            self.emit(MarketCreated {
                market_id: market_id,
                creator: caller,
                title: title,
                category: category,
                start_time: start_time,
                end_time: end_time,
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
            assert(outcome_index < market.outcomes.len(), 'Invalid outcome');
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
                market_id: market_id,
                user: caller,
                outcome_index: outcome_index,
                amount: amount,
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
                market_id: market_id,
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
                winning_outcome: winning_outcome,
                resolution_details: resolution_details,
            }));

            self.market_status.write(market_id, MarketStatus::Resolved);

            self.emit(MarketResolved {
                market_id: market_id,
                winning_outcome: winning_outcome,
                resolver: caller,
                resolution_details: resolution_details,
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
                market_id: market_id,
                disputer: caller,
                reason: reason,
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

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn get_random_validator(self: @ContractState) -> ContractAddress {
            let validator_contract = IMarketValidatorDispatcher {
                contract_address: self.market_validator.read()
            };
            let validators = validator_contract.get_validators_array();
            
            if validators.len() == 0 {
                return self.fee_collector.read();
            }
            
            let index = self.validator_index.read() % validators.len();
            self.validator_index.write(index + 1);
            validators[index]
        }
    }
}