#[starknet::contract]
mod PredictionMarket {
    use core::array::ArrayTrait;
    use core::option::OptionTrait;
    use openzeppelin::access::accesscontrol::AccessControlComponent::InternalTrait;

    // OpenZeppelin imports
    use openzeppelin::access::accesscontrol::{AccessControlComponent, DEFAULT_ADMIN_ROLE};
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use stakcast::interfaces::IMarket::IPredictionMarket; // use stakcast::interfaces::IToken::IERC20;
    use starknet::contract_address::ContractAddress;
    use starknet::storage::{
        Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess,
        StoragePointerWriteAccess,
    };
    use starknet::{get_block_timestamp, get_caller_address, get_contract_address};
    use crate::config::types::Market;


    // ====== STORAGE ======
    #[storage]
    struct Storage {
        markets: Map<u64, Market>,
        market_count: u64,
        market_outcomes: Map<(u64, u32), felt252>,
        outcome_counts: Map<u64, u32>,
        user_positions: Map<(u64, ContractAddress, u32), u128>,
        outcome_totals: Map<(u64, u32), u128>,
        validators: Map<ContractAddress, bool>,
        token_address: ContractAddress,
        #[substorage(v0)]
        accesscontrol: AccessControlComponent::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
    }

    // ====== EVENTS ======
    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        MarketCreated: MarketCreated,
        UnitsPurchased: UnitsPurchased,
        MarketResolved: MarketResolved,
        RewardsClaimed: RewardsClaimed,
        ValidatorAdded: ValidatorAdded,
        ValidatorRemoved: ValidatorRemoved,
        #[flat]
        AccessControlEvent: AccessControlComponent::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
    }

    #[derive(Drop, starknet::Event)]
    struct MarketCreated {
        market_id: u64,
        question: felt252,
        end_time: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct UnitsPurchased {
        user: ContractAddress,
        market_id: u64,
        outcome_id: u32,
        amount: u128,
    }

    #[derive(Drop, starknet::Event)]
    struct MarketResolved {
        market_id: u64,
        winning_outcome_id: u32,
    }

    #[derive(Drop, starknet::Event)]
    struct RewardsClaimed {
        user: ContractAddress,
        amount: u128,
    }

    #[derive(Drop, starknet::Event)]
    struct ValidatorAdded {
        account: ContractAddress,
        caller: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct ValidatorRemoved {
        account: ContractAddress,
        caller: ContractAddress,
    }

    // ====== COMPONENTS ======
    component!(path: AccessControlComponent, storage: accesscontrol, event: AccessControlEvent);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);

    // AccessControl impl
    #[abi(embed_v0)]
    impl AccessControlImpl =
        AccessControlComponent::AccessControlImpl<ContractState>;

    // SRC5 impl
    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;

    // ====== CONSTRUCTOR ======
    #[constructor]
    fn constructor(ref self: ContractState, admin: ContractAddress, token: ContractAddress) {
        self.accesscontrol._grant_role(DEFAULT_ADMIN_ROLE, admin);
        self.validators.write(admin, true); // Admin is default validator
        self.token_address.write(token);
    }

    // ====== CONTRACT IMPLEMENTATION ======
    #[abi(embed_v0)]
    impl MarketImpl of IPredictionMarket<ContractState> {
        /// Creates a new prediction market
        ///
        /// Best Practices for Market Creation:
        /// 1. Question should be:
        ///    - Clear and unambiguous
        ///    - Specific enough for validators to resolve
        ///    - Time-bound with a clear resolution date
        ///    - Verifiable through objective sources
        ///
        /// 2. Outcomes should be:
        ///    - Mutually exclusive (only one can win)
        ///    - Collectively exhaustive (cover all possibilities)
        ///    - Clearly defined
        ///    - Measurable/verifiable
        ///
        /// 3. Time parameters:
        ///    - start_time: When the market opens for participation
        ///    - end_time: When the market closes and awaits resolution
        ///    - Should allow enough time for:
        ///      * Market participation
        ///      * Event to occur
        ///      * Validators to verify and resolve
        ///
        /// Example of a good market:
        /// Question: "Who will win the 2024 US Presidential Election?"
        /// Outcomes: ["Candidate A", "Candidate B", "Other"]
        ///
        /// Example of a bad market:
        /// Question: "Will the stock market go up?"
        /// Outcomes: ["Yes", "No"]
        /// (Too vague, no specific timeframe, unclear what "up" means)
        ///
        /// @param question The market question (should be clear and specific)
        /// @param outcomes Array of possible outcomes (must be mutually exclusive)
        /// @param start_time When the market opens for participation
        /// @param end_time When the market closes for participation
        /// @return market_id The unique identifier for the created market
        fn create_market(
            ref self: ContractState,
            question: ByteArray,
            mut outcomes: Array<felt252>,
            start_time: u64,
            end_time: u64,
        ) -> u64 {
            let creator = get_caller_address();
            let current_time = get_block_timestamp();
            assert(end_time > current_time, 'End time must be in future');
            assert(outcomes.len() > 1, 'Market must have at least 2 outcomes');

            let market_id = self.market_count.read();

            // Store market
            let market = Market {
                question,
                creator,
                start_time: current_time,
                end_time,
                is_resolved: false,
                winning_outcome_id: 0_u32,
            };
            self.markets.write(market_id, market);

            // Store outcomes
            let mut i = 0_u32;
            let len = outcomes.len().try_into().unwrap();
            while i != len {
                self.market_outcomes.write((market_id, i), *outcomes.at(i));
                i += 1;
            }
            self.outcome_counts.write(market_id, outcomes.len().try_into().unwrap());

            self.market_count.write(market_id + 1);

            self.emit(Event::MarketCreated(MarketCreated { market_id, question, end_time }));

            return market_id;
        }

        /// Purchases units for a specific outcome in a market
        ///
        /// Token Deposit Flow:
        /// 1. User must first approve the contract to spend their SK tokens (off-chain)
        /// 2. When this function is called:
        ///    - Tokens are transferred from user's wallet to the contract
        ///    - Contract acts as an escrow, holding tokens until market resolution
        ///    - User's position is tracked in user_positions mapping
        ///    - Outcome's total volume is updated in outcome_totals
        ///
        /// Escrow Mechanism:
        /// - All purchased tokens are held by the contract
        /// - Tokens remain locked until market resolution
        /// - Winners can claim their rewards (original stake + share of losing pool)
        /// - Losers' tokens are distributed to winners
        ///
        /// Example:
        /// If user purchases 100 SK tokens for outcome A:
        /// 1. 100 SK tokens are transferred from user's wallet to contract
        /// 2. user_positions[market_id][user][outcome_id] = 100
        /// 3. outcome_totals[market_id][outcome_id] += 100
        /// 4. Tokens stay in contract until market resolution
        ///
        /// @param market_id The ID of the market to purchase units in
        /// @param outcome_id The ID of the outcome to purchase units for
        /// @param amount The amount of SK tokens to purchase
        fn purchase_units(ref self: ContractState, market_id: u64, outcome_id: u32, amount: u128) {
            let user = get_caller_address();
            let token = self.token_address.read();

            // Transfer tokens from user to contract (escrow)
            // This requires prior approval from the user
            let dispatcher = IERC20Dispatcher { contract_address: token };
            dispatcher.transfer_from(user, get_contract_address(), amount.into());

            let market = self.markets.read(market_id);
            assert(!market.is_resolved, 'Market resolved');
            let now = get_block_timestamp();
            assert(now <= market.end_time, 'Market closed');

            assert(outcome_id < self.outcome_counts.read(market_id), 'Invalid outcome');

            // Track user's position in this outcome
            let key = (market_id, user, outcome_id);
            self.user_positions.write(key, amount);

            // Update total volume for this outcome
            let total_key = (market_id, outcome_id);
            self.outcome_totals.write(total_key, self.outcome_totals.read(total_key) + amount);

            self
                .emit(
                    Event::UnitsPurchased(UnitsPurchased { user, market_id, outcome_id, amount }),
                );
        }

        fn resolve_market(ref self: ContractState, market_id: u64, winning_outcome_id: u32) {
            let caller = get_caller_address();
            assert(self.is_validator(caller), 'Caller not authorized');

            let mut market = self.markets.read(market_id);
            let now = get_block_timestamp();
            assert(now > market.end_time, 'Market not ended');
            assert(!market.is_resolved, 'Already resolved');

            assert(winning_outcome_id < self.outcome_counts.read(market_id), 'Invalid outcome');

            market.is_resolved = true;
            market.winning_outcome_id = winning_outcome_id;
            self.markets.write(market_id, market);

            self.emit(Event::MarketResolved(MarketResolved { market_id, winning_outcome_id }));
        }

        /// Calculates the total amount staked on losing outcomes
        /// Formula: losing_pool = total_pool - winning_pool
        /// where:
        /// - total_pool = sum of all stakes across all outcomes
        /// - winning_pool = total stakes on the winning outcome
        fn get_losing_pool(self: @ContractState, market_id: u64, winning_outcome_id: u32) -> u128 {
            let total_pool = self.get_market_total_volume(market_id);
            let winning_pool = self.outcome_totals.read((market_id, winning_outcome_id));
            total_pool - winning_pool
        }

        /// Claims rewards for a user's winning position
        /// Reward Formula: reward = original_stake + (losing_pool * user_share)
        /// where:
        /// - original_stake = amount user staked on winning outcome
        /// - losing_pool = total stakes on all losing outcomes
        /// - user_share = (original_stake / winning_pool) * 10000 (percentage with 2 decimal
        /// places)
        ///
        /// Example:
        /// If total market has 6000 units:
        /// - Winning outcome (A): 1000 units
        /// - Losing outcome (B): 2000 units
        /// - Losing outcome (C): 3000 units
        /// And user staked 100 units on A:
        /// - Original stake: 100 units
        /// - User share: (100/1000) * 10000 = 1000 (10%)
        /// - Losing pool: 5000 units
        /// - Reward from losing pool: (5000 * 1000) / 10000 = 500 units
        /// - Total reward: 100 + 500 = 600 units
        fn claim_rewards(ref self: ContractState, market_id: u64) {
            let user = get_caller_address();
            let token = self.token_address.read();

            let market = self.markets.read(market_id);
            assert(market.is_resolved, 'Market not resolved');

            let winning_outcome_id = market.winning_outcome_id;
            let user_key = (market_id, user, winning_outcome_id);
            let user_amount = self.user_positions.read(user_key);
            assert(user_amount > 0_u128, 'No units to claim');

            // Get the total pool for the winning outcome
            let winning_pool = self.outcome_totals.read((market_id, winning_outcome_id));

            // Calculate the losing pool (total stakes minus winning stakes)
            let losing_pool = self.get_losing_pool(market_id, winning_outcome_id);

            // Calculate user's share of the winning pool (percentage with 2 decimal places)
            // user_share = (user_amount / winning_pool) * 10000
            let user_share = (user_amount * 10000) / winning_pool;

            // Calculate final reward:
            // reward = original_stake + (losing_pool * user_share / 10000)
            let reward = user_amount + ((losing_pool * user_share) / 10000);

            // Clear user's position
            self.user_positions.write(user_key, 0_u128);

            // Transfer rewards to user
            let dispatcher = IERC20Dispatcher { contract_address: token };
            dispatcher.transfer(user, reward.into());

            self.emit(Event::RewardsClaimed(RewardsClaimed { user, amount: reward }));
        }

        fn get_market(self: @ContractState, market_id: u64) -> Market {
            self.markets.read(market_id)
        }

        fn get_user_position(
            self: @ContractState, user: ContractAddress, market_id: u64, outcome_id: u32,
        ) -> u128 {
            self.user_positions.read((market_id, user, outcome_id))
        }

        fn get_total_outcome_units(self: @ContractState, market_id: u64, outcome_id: u32) -> u128 {
            self.outcome_totals.read((market_id, outcome_id))
        }

        fn get_market_total_volume(self: @ContractState, market_id: u64) -> u128 {
            let mut i = 0_u32;
            let mut total = 0_u128;
            let len = self.outcome_counts.read(market_id).try_into().unwrap();

            while i != len {
                total += self.get_total_outcome_units(market_id, i);
                i += 1;
            }

            total
        }

        fn get_resolved_outcome_id(self: @ContractState, market_id: u64) -> u32 {
            let market = self.markets.read(market_id);
            market.winning_outcome_id
        }

        fn get_market_count(self: @ContractState) -> u64 {
            self.market_count.read()
        }

        fn is_validator(self: @ContractState, address: ContractAddress) -> bool {
            self.validators.read(address)
        }

        fn add_validator(ref self: ContractState, account: ContractAddress) {
            let caller = get_caller_address();
            assert(self.accesscontrol.has_role(DEFAULT_ADMIN_ROLE, caller), 'Caller not admin');
            self.validators.write(account, true);
            self.emit(Event::ValidatorAdded(ValidatorAdded { account, caller }));
        }

        fn remove_validator(ref self: ContractState, account: ContractAddress) {
            let caller = get_caller_address();
            assert(self.accesscontrol.has_role(DEFAULT_ADMIN_ROLE, caller), 'Caller not admin');
            self.validators.write(account, false);
            self.emit(Event::ValidatorRemoved(ValidatorRemoved { account, caller }));
        }

        fn get_market_volume_by_outcome(
            self: @ContractState, market_id: u64, outcome_id: u32,
        ) -> u128 {
            assert(outcome_id < self.outcome_counts.read(market_id), 'Invalid outcome');
            self.outcome_totals.read((market_id, outcome_id))
        }

        fn get_user_share_percentage(
            self: @ContractState, user: ContractAddress, market_id: u64, outcome_id: u32,
        ) -> u128 {
            let user_units = self.get_user_position(user, market_id, outcome_id);
            let total_outcome_units = self.get_total_outcome_units(market_id, outcome_id);

            if total_outcome_units == 0 {
                return 0;
            }

            // Calculate percentage with 2 decimal places (multiply by 10000)
            (user_units * 10000) / total_outcome_units
        }

        /// Calculates potential reward for a user's position if their outcome wins
        /// Uses the same formula as claim_rewards:
        /// potential_reward = original_stake + (losing_pool * user_share)
        /// where:
        /// - original_stake = current user position
        /// - losing_pool = total_pool - outcome_pool
        /// - user_share = (original_stake / outcome_pool) * 10000
        fn get_potential_reward(
            self: @ContractState, user: ContractAddress, market_id: u64, outcome_id: u32,
        ) -> u128 {
            let market = self.markets.read(market_id);
            assert(!market.is_resolved, 'Market already resolved');

            let user_units = self.get_user_position(user, market_id, outcome_id);
            let outcome_pool = self.get_total_outcome_units(market_id, outcome_id);

            if outcome_pool == 0 {
                return user_units; // Return at least the original stake
            }

            // Calculate potential reward if this outcome wins
            let total_pool = self.get_market_total_volume(market_id);
            let losing_pool = total_pool - outcome_pool;

            // Calculate user's share (percentage with 2 decimal places)
            let user_share = (user_units * 10000) / outcome_pool;

            // Return original stake plus potential share of losing pool
            user_units + ((losing_pool * user_share) / 10000)
        }

        fn get_market_outcomes(self: @ContractState, market_id: u64) -> Array<felt252> {
            let count = self.outcome_counts.read(market_id);
            let mut outcomes = ArrayTrait::new();
            let mut i = 0_u32;
            while i != count {
                outcomes.append(self.market_outcomes.read((market_id, i)));
                i += 1;
            }
            outcomes
        }
    }

    // ====== PRIVATE HELPERS ======
    #[generate_trait]
    impl Private of PrivateTrait {
        fn contains_outcome(
            self: @ContractState, outcomes: Array<felt252>, target: felt252,
        ) -> bool {
            let mut i = 0;
            while i != outcomes.len() {
                if *outcomes.at(i) == target {
                    return true;
                }
                i += 1;
            }
            false
        }
    }
}
