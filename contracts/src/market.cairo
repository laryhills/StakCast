#[starknet::contract]
mod MarketValidator {
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::get_block_timestamp;
    use core::option::OptionTrait;
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, Map,
    };

    // Import the IMarketValidator and IERC20 interfaces
    use stakcast::interface::{IMarketValidator, IERC20, IERC20Dispatcher};

    #[storage]
    struct Storage {
        prediction_market: ContractAddress,
        validators: Map<ContractAddress, ValidatorInfo>,
        validator_count: u32,
        min_stake: core::integer::u256,
        resolution_timeout: u64,
    }

    #[derive(Drop, Copy, Serde, starknet::Store)]
    struct ValidatorInfo {
        stake: u256,
        markets_resolved: u32,
        accuracy_score: u32,
        active: bool,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        ValidatorRegistered: ValidatorRegistered,
        MarketResolved: MarketResolved,
        ValidatorSlashed: ValidatorSlashed,
    }

    #[derive(Drop, starknet::Event)]
    struct ValidatorRegistered {
        validator: ContractAddress,
        stake: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct MarketResolved {
        market_id: u32,
        outcome: u32,
        resolver: ContractAddress,
        resolution_details: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct ValidatorSlashed {
        validator: ContractAddress,
        amount: core::integer::u256,
        reason: felt252,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        prediction_market: ContractAddress,
        min_stake: u256,
        resolution_timeout: u64,
    ) {
        self.prediction_market.write(prediction_market);
        self.min_stake.write(min_stake);
        self.resolution_timeout.write(resolution_timeout);
    }

    // Implement the IMarketValidator interface
    #[external(v0)]
    #[abi (embed_v0)]
    impl MarketValidator of IMarketValidator<ContractState> {
        fn register_validator(ref self: ContractState, stake: core::integer::u256) {
            let caller = get_caller_address();
            assert(stake >= self.min_stake.read(), 'Insufficient stake');

            // Transfer stake using the IERC20 interface
            let mut stake_token = IERC20Dispatcher { contract_address: self.prediction_market.read().get_stake_token() };
            let transfer_result = IERC20::transfer_from(ref stake_token, caller, self.contract_address(), stake);
            assert(transfer_result, 'Stake transfer failed');

            // Update validator info
            let mut validator = OptionTrait::unwrap_or(self.validators.get(caller), ValidatorInfo {
                stake: 0,
                markets_resolved: 0,
                accuracy_score: 0,
                active: false,
            });
            let updated_validator = ValidatorInfo {
                stake: validator.stake + stake,
                markets_resolved: 0,
                accuracy_score: 100,
                active: true,
            };
            self.validators.write(caller, validator);

            self.validator_count.write(self.validator_count.read() + 1);

            self.emit(ValidatorRegistered { validator: caller, stake: stake });
        }

        fn resolve_market(
            ref self: ContractState,
            market_id: u32,
            winning_outcome: u32,
            resolution_details: felt252,
        ) {
            let caller = get_caller_address();
            let validator_info = self.validators.read(caller);
            assert(validator_info.active, 'Not an active validator');

            // Get prediction market contract
            let mut prediction_market = IPredictionMarketDispatcher {
                contract_address: self.prediction_market.read(),
            };

            // Verify validator is assigned to this market
            let market = prediction_market.get_market_info(market_id);
            assert(market.validator == caller, 'Not assigned validator');

            // Check resolution timeframe
            let current_time = get_block_timestamp();
            assert(current_time >= market.end_time, 'Market not ended');
            assert(
                current_time <= market.end_time + self.resolution_timeout.read(),
                'Resolution timeout',
            );

            // Update validator stats
            let mut validator = self.validators.read(caller);
            validator.markets_resolved += 1;
            self.validators.write(caller, validator);

            // Resolve market
            prediction_market.resolve_market(market_id, winning_outcome, resolution_details);

            self.emit(MarketResolved {
                market_id,
                outcome: winning_outcome,
                resolver: caller,
                resolution_details,
            });
        }

        fn slash_validator(
            ref self: ContractState,
            validator: ContractAddress,
            amount: u256,
            reason: felt252,
        ) {
            // Only prediction market contract can slash
            assert(get_caller_address() == self.prediction_market.read(), 'Unauthorized');

            let mut validator_info = self.validators.read(validator);
            assert(validator_info.stake >= amount, 'Insufficient stake');

            validator_info.stake -= amount;
            if validator_info.stake < core::integer::u256_from_felt252(self.min_stake.read()) {
                validator_info.active = false;
            }
            self.validators.write(validator, validator_info);

            self.emit(ValidatorSlashed {
                validator,
                amount,
                reason,
            });
        }

        fn get_validator_info(
            self: @ContractState,
            validator: ContractAddress,
        ) -> stakcast::interface::ValidatorInfo {
            let info = self.validators.read(validator).unwrap_or(stakcast::interface::ValidatorInfo {
                stake: 0,
                markets_resolved: 0,
                accuracy_score: 0,
                active: false,
            });

            stakcast::interface::ValidatorInfo {
                stake: info.stake,
                markets_resolved: info.markets_resolved,
                accuracy_score: info.accuracy_score,
                active: info.active,
            }
        }

        fn is_active_validator(
            self: @ContractState,
            validator: ContractAddress,
        ) -> bool {
            self.validators.read(validator).active
        }
    }
}