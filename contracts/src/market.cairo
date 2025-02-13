#[starknet::contract]
mod MarketValidator {
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::get_block_timestamp;
    use core::array::ArrayTrait;
    use core::option::OptionTrait;
    use openzeppelin::token::erc20::IERC20Dispatcher;
    use super::{IPredictionMarketDispatcher, ValidatorInfo};
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry, Map,
    };
    #[storage]
    struct Storage {
        prediction_market: ContractAddress,
        validators: Map<ContractAddress, ValidatorInfo>,
        validators_array: Array<ContractAddress>,
        min_stake: u256,
        resolution_timeout: u64,
        slash_percentage: u256,
    }

    #[derive(Drop, Copy, Serde, starknet::Store)]
    struct ValidatorInfo {
        stake: u256,
        markets_resolved: u32,
        accuracy_score: u32,
        active: bool,
        last_resolution_time: u64,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        ValidatorRegistered: ValidatorRegistered,
        MarketResolved: MarketResolved,
        ValidatorSlashed: ValidatorSlashed,
        ValidatorActivated: ValidatorActivated,
    }

    #[derive(Drop, starknet::Event)]
    struct ValidatorRegistered {
        validator: ContractAddress,
        stake: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct MarketResolved {
        market_id: u32,
        resolver: ContractAddress,
        resolution_time: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct ValidatorSlashed {
        validator: ContractAddress,
        amount: u256,
        reason: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct ValidatorActivated {
        validator: ContractAddress,
        activation_time: u64,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        prediction_market: ContractAddress,
        min_stake: u256,
        resolution_timeout: u64,
        slash_percentage: u256,
    ) {
        self.prediction_market.write(prediction_market);
        self.min_stake.write(min_stake);
        self.resolution_timeout.write(resolution_timeout);
        self.slash_percentage.write(slash_percentage);
    }

    #[external(v0)]
    #[abi(embed_v0)]
    impl MarketValidatorImpl of super::IMarketValidator<ContractState> {
        fn register_validator(ref self: ContractState, stake: u256) {
            let caller = get_caller_address();
            
            // Validate stake amount
            assert(stake >= self.min_stake.read(), 'Insufficient stake');
            
            // Get stake token from prediction market
            let pm = IPredictionMarketDispatcher {
                contract_address: self.prediction_market.read()
            };
            let stake_token_addr = pm.get_stake_token();
            
            // Transfer stake
            let stake_token = IERC20Dispatcher { contract_address: stake_token_addr };
            assert(
                stake_token.transfer_from(caller, self.contract_address(), stake),
                'Stake transfer failed'
            );

            // Update validator info
            let mut validators_array = self.validators_array.read();
            let mut validator = self.validators.read(caller);

            if !validator.active {
                validators_array.append(caller);
                self.validators_array.write(validators_array);
            }

            let new_validator = ValidatorInfo {
                stake: validator.stake + stake,
                markets_resolved: validator.markets_resolved,
                accuracy_score: validator.accuracy_score,
                active: true,
                last_resolution_time: validator.last_resolution_time,
            };

            self.validators.write(caller, new_validator);
            self.emit(ValidatorRegistered { validator: caller, stake: stake });
        }

        fn resolve_market(
            ref self: ContractState,
            market_id: u32,
            winning_outcome: u32,
            resolution_details: felt252,
        ) {
            let caller = get_caller_address();
            let mut validator = self.validators.read(caller);
            let current_time = get_block_timestamp();

            // Validate validator status
            assert(validator.active, 'Inactive validator');
            assert(
                current_time > validator.last_resolution_time + self.resolution_timeout.read(),
                'Too frequent resolutions'
            );

            // Update validator stats
            validator.markets_resolved += 1;
            validator.last_resolution_time = current_time;
            self.validators.write(caller, validator);

            // Forward resolution to prediction market
            let pm = IPredictionMarketDispatcher {
                contract_address: self.prediction_market.read()
            };
            pm.resolve_market(market_id, winning_outcome, resolution_details);

            self.emit(MarketResolved {
                market_id,
                resolver: caller,
                resolution_time: current_time,
            });
        }

        fn slash_validator(
            ref self: ContractState,
            validator: ContractAddress,
            amount: u256,
            reason: felt252,
        ) {
            // Strict access control
            assert(
                get_caller_address() == self.prediction_market.read(),
                'Unauthorized slashing'
            );

            let mut validator_info = self.validators.read(validator);
            assert(validator_info.active, 'Validator not active');

            // Calculate actual slash amount
            let slash_amount = if amount == 0 {
                (validator_info.stake * self.slash_percentage.read()) / 100
            } else {
                core::cmp::min(amount, validator_info.stake)
            };

            // Update validator stake
            validator_info.stake -= slash_amount;
            
            // Deactivate if below minimum stake
            if validator_info.stake < self.min_stake.read() {
                validator_info.active = false;
                self.remove_validator_from_array(validator);
            }

            self.validators.write(validator, validator_info);

            // Transfer slashed funds to prediction market
            let pm = IPredictionMarketDispatcher {
                contract_address: self.prediction_market.read()
            };
            let stake_token = IERC20Dispatcher { 
                contract_address: pm.get_stake_token() 
            };
            stake_token.transfer(self.prediction_market.read(), slash_amount);

            self.emit(ValidatorSlashed {
                validator,
                amount: slash_amount,
                reason,
            });
        }

        fn get_validator_info(
            self: @ContractState,
            validator: ContractAddress,
        ) -> ValidatorInfo {
            self.validators.read(validator)
        }

        fn is_active_validator(
            self: @ContractState,
            validator: ContractAddress,
        ) -> bool {
            self.validators.read(validator).active
        }

        fn get_validators_array(
            self: @ContractState,
        ) -> Array<ContractAddress> {
            self.validators_array.read()
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn remove_validator_from_array(ref self: ContractState, validator: ContractAddress) {
            let mut validators = self.validators_array.read();
            let mut i = 0;
            let len = validators.len();
            
            while i < len {
                if validators[i] == validator {
                    validators.swap_remove(i);
                    break;
                }
                i += 1;
            }
            self.validators_array.write(validators);
        }

        fn calculate_accuracy(
            self: @ContractState,
            validator: ContractAddress,
            disputed_resolutions: u32
        ) -> u32 {
            let info = self.validators.read(validator);
            let total = info.markets_resolved;
            if total == 0 {
                return 100;
            }
            ((total - disputed_resolutions) * 100) / total
        }
    }
}