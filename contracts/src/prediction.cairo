#[starknet::contract]
mod PredictionMarket {
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::get_block_timestamp;
    use core::option::OptionTrait;

    // Import shared components from lib.cairo and interface.cairo
    use super::interfaces::{Market, Position, MarketOutcome, MarketStatus, IPredictionMarketDispatcher, IMarketValidatorDispatcher, IERC20Dispatcher};
    use super::lib::{
        constants::{MIN_OUTCOMES, RESOLUTION_WINDOW, BASIS_POINTS},
        events::{MarketCreated, PositionTaken, WinningsClaimed},
        utils::{is_market_active, calculate_fee},
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
        market_validators: Map<ContractAddress, bool>,
        market_categories: Map<u32, felt252>,
        market_status: Map<u32, MarketStatus>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        MarketCreated: MarketCreated,
        PositionTaken: PositionTaken,
        MarketResolved: MarketResolved,
        WinningsClaimed: WinningsClaimed,
    }

    #[constructor]
    fn constructor(
        ref self: Storage,
        stake_token_address: ContractAddress,
        fee_collector: ContractAddress,
        platform_fee: u256,
    ) {
        self.stake_token.write(stake_token_address);
        self.fee_collector.write(fee_collector);
        self.platform_fee.write(platform_fee);
    }

    #[external]
    fn create_market(
        ref self: Storage,
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

        assert(start_time > current_time, 'Invalid start time');
        assert(end_time > start_time, 'Invalid end time');
        assert(outcomes.len() >= MIN_OUTCOMES, 'Min 2 outcomes required');

        let market_id = self.market_count.read() + 1;
        let mut stakes = ArrayTrait::new();
        outcomes.len().times(|| stakes.append(0_u256));

        let new_market = Market {
            creator: caller,
            title,
            description,
            category,
            start_time,
            end_time,
            resolution_time: end_time + RESOLUTION_WINDOW,
            total_stake: 0_u256,
            outcomes,
            stakes_per_outcome: stakes,
            min_stake,
            max_stake,
            validator: self.get_random_validator(),
        };

        self.markets.write(market_id, new_market);
        self.market_count.write(market_id);
        self.market_status.write(market_id, MarketStatus::Active);

        self.emit(MarketCreated {
            market_id,
            creator: caller,
            title,
            start_time,
            end_time,
        });

        market_id
    }

    #[external]
    fn take_position(
        ref self: Storage,
        market_id: u32,
        outcome_index: u32,
        amount: u256,
    ) {
        let caller = get_caller_address();
        let market = self.markets.read(market_id);
        let status = self.market_status.read(market_id);

        assert(status == MarketStatus::Active, 'Market not active');
        assert(is_market_active(market.start_time, market.end_time), 'Market inactive');
        assert(amount >= market.min_stake, 'Below min stake');
        assert(amount <= market.max_stake, 'Above max stake');

        let stake_token = IERC20Dispatcher { contract_address: self.stake_token.read() };
        stake_token.transfer_from(caller, self.address, amount);
        let mut position = self.positions.read((market_id, caller));
        position.amount += amount;
        position.outcome_index = outcome_index;
        self.positions.write((market_id, caller), position);

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

    #[external]
    fn claim_winnings(ref self: Storage, market_id: u32) {
        let caller = get_caller_address();
        let position = self.positions.read((market_id, caller));
        let outcome = self.market_outcomes.read(market_id);

        assert(outcome.is_some(), 'Market not resolved');
        assert(position.amount > 0, 'No position found');
        assert(!position.claimed, 'Already claimed');

        let market = self.markets.read(market_id);
        let winning_outcome = outcome.unwrap().winning_outcome;
        let mut winnings = 0_u256;

        if position.outcome_index == winning_outcome {
            let total_stake = market.total_stake;
            let winning_pool = market.stakes_per_outcome[winning_outcome];
            winnings = (position.amount * total_stake) / winning_pool;

            let fee = calculate_fee(winnings, self.platform_fee.read());
            winnings -= fee;

            let stake_token = IERC20Dispatcher { contract_address: self.stake_token.read() };
            stake_token.transfer(caller, winnings);
            stake_token.transfer(self.fee_collector.read(), fee);
        }

        let mut position = self.positions.read((market_id, caller));
        position.claimed = true;
        self.positions.write((market_id, caller), position);

        self.emit(WinningsClaimed {
            market_id,
            user: caller,
            amount: winnings,
        });
    }

    #[external]
    fn resolve_market(
        ref self: Storage,
        market_id: u32,
        winning_outcome: u32,
        resolution_details: felt252,
    ) {
        let validator = self.markets.read(market_id).validator;
        let market_validator = IMarketValidatorDispatcher { contract_address: validator };
        market_validator.resolve_market(market_id, winning_outcome, resolution_details);
        self.market_status.write(market_id, MarketStatus::Resolved);
    }

    // Internal helper functions
    fn get_random_validator(self: @Storage) -> ContractAddress {
        let mut i = 0;
        loop {
            if i >= self.validator_count.read() {
                break self.fee_collector.read();
            }
            let validator = self.market_validators.read(ContractAddress::from(i));
            if validator {
                break ContractAddress::from(i);
            }
            i += 1;
        }
    }

    // View functions (external but read-only)
    #[external]
    fn get_market_details(
        self: @Storage,
        market_id: u32,
    ) -> (Market, MarketStatus, Option<MarketOutcome>) {
        (
            self.markets.read(market_id),
            self.market_status.read(market_id),
            self.market_outcomes.read(market_id),
        )
    }

    #[external]
    fn get_user_position(
        self: @Storage,
        user: ContractAddress,
        market_id: u32,
    ) -> Position {
        self.positions.read((market_id, user))
    }

    #[external]
    fn get_market_stats(
        self: @Storage,
        market_id: u32,
    ) -> (u256, Array<u256>) {
        let market = self.markets.read(market_id);
        (market.total_stake, market.stakes_per_outcome)
    }
}