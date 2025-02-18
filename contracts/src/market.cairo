use starknet::ContractAddress;
use starknet::get_caller_address;
use starknet::get_block_timestamp;
use core::array::ArrayTrait;
use core::option::OptionTrait;
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use stakcast::interface::{IPredictionMarketDispatcher, IPredictionMarketDispatcherTrait, ValidatorInfo, IMarketValidator};
use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry, Map};

#[starknet::contract]
mod MarketValidator {
    use super::*;

    // Storage
    #[storage]
    struct Storage {
        prediction_market: ContractAddress,
        validators: Map<ContractAddress, LocalValidatorInfo>,
        validators_array: Array<ContractAddress>,
        validator_count: u32,
        min_stake: u256,
        resolution_timeout: u64,
        slash_percentage: u64,
        
    }  

    // Data Structures
    #[derive(Drop, Copy, Serde, starknet::Store)]
    struct LocalValidatorInfo {
        stake: u256,
        markets_resolved: u32,
        disputed_resolutions: u32,
        accuracy_score: u32,
        active: bool,
        last_resolution_time: u64,
        validator_index: u32,
        
    }

    // Events
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

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        ValidatorRegistered: ValidatorRegistered,
        MarketResolved: MarketResolved,
        ValidatorSlashed: ValidatorSlashed,
        ValidatorActivated: ValidatorActivated,
    }

    // Constructor
    #[constructor]
    fn constructor(
        ref self: ContractState,
        prediction_market: ContractAddress,
        min_stake: u256,
        resolution_timeout: u64,
        slash_percentage: u64,
    ) {
        self.prediction_market.write(prediction_market);
        self.min_stake.write(min_stake);
        self.resolution_timeout.write(resolution_timeout);
        self.slash_percentage.write(slash_percentage);
        self.validator_count.write(0);
    }

    // External Implementation
    #[external(v0)]
    #[abi(embed_v0)]
    impl MarketValidatorImp of IMarketValidator<ContractState> {
        fn register_validator(ref self: ContractState, stake: u256) {
            let caller = get_caller_address();
        
            // Validate stake amount
            assert(stake >= self.min_stake.read(), 'Insufficient stake');
        
            // Get stake token from prediction market
            let pm = IPredictionMarketDispatcher { contract_address: self.prediction_market.read() };
            let stake_token_addr = pm.get_stake_token();
        
            // Transfer stake
            let stake_token = IERC20Dispatcher { contract_address: stake_token_addr };
            assert(
                stake_token.transfer_from(caller, self.contract_address(), stake),
                'Stake transfer failed'
            );
        
            // Read the validator info from storage (default value if not found)
            let mut validator_info = self.validators.entry(caller).read();
            if validator_info.active == false {
                // Initialize default values if the validator is new
                validator_info = LocalValidatorInfo {
                    stake: 0.into(),
                    markets_resolved: 0,
                    disputed_resolutions: 0,
                    accuracy_score: 0,
                    active: false,
                    last_resolution_time: 0,
                    validator_index: 0,
                };
            }
        
            // If the validator is new, add them to the array
            if !validator_info.active {
                // Load the current validators array from storage (default value if not found)
                let mut validators_array: Array<ContractAddress> = self.validators_array.entry().read();
        
                // Append the new validator
                validators_array.append(caller);
        
                // Write the updated array back to storage
                self.validators_array.entry().write(validators_array);
        
                // Update validator index and increment validator count
                let validator_count = self.validator_count.read();
                validator_info.validator_index = validator_count;
                self.validator_count.write(validator_count + 1);
            }
        
            // Update validator details in memory
            validator_info.stake = stake;
            validator_info.active = true;
            validator_info.markets_resolved = 0;
            validator_info.disputed_resolutions = 0;
            validator_info.accuracy_score = 0;
        
            // Write the updated validator info back to storage
            self.validators.entry(caller).write(validator_info);
        
            // Emit event
            self.emit(ValidatorRegistered {
                validator: caller,
                stake,
            });
        }
        fn resolve_market(
    ref self: ContractState,
    market_id: u32,
    winning_outcome: u32,
    resolution_details: felt252,
) {
    let caller = get_caller_address();
    let current_time = get_block_timestamp();

    // Read the validator info from storage (default value if not found)
    let mut validator_info: LocalValidatorInfo = self.validators.entry(caller).read();

    // If the validator does not exist or is inactive, panic with an error message
    if !validator_info.active {
        panic('Validator not found or inactive');
    }

    // Validate validator status
    assert(
        current_time > validator_info.last_resolution_time + self.resolution_timeout.read(),
        ('Too frequent resolutions')
    );

    // Update validator stats in memory
    validator_info.markets_resolved += 1;
    validator_info.last_resolution_time = current_time;

    // Write the updated validator info back to storage
    self.validators.entry(caller).write(validator_info);

    // Forward resolution to prediction market
    let pm = IPredictionMarketDispatcher { contract_address: self.prediction_market.read() };
    pm.resolve_market(market_id, winning_outcome, resolution_details);

    // Emit event
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
    // Ensure only the prediction market can call this function
    assert(get_caller_address() == self.prediction_market.read(), 'Unauthorized slashing');

    // Read the validator info from storage (default value if not found)
    let mut validator_info: LocalValidatorInfo = self.validators.entry(validator).read();

    // Validate that the validator is active
    if !validator_info.active {
        panic('Validator not active');
    }

    // Convert u64 values to u256 for consistency
    let min_stake: u256 = self.min_stake.read().into(); // Convert u64 to u256
    let slash_percentage: u256 = self.slash_percentage.read().into(); // Convert u64 to u256

    // Calculate the actual slash amount
    let slash_amount = if amount == 0.into() {
        (validator_info.stake * slash_percentage) / 100.into()
    } else {
        core::cmp::min(amount, validator_info.stake)
    };

    // Update validator stats in memory
    validator_info.stake -= slash_amount;
    validator_info.disputed_resolutions += 1;

    // Deactivate the validator if their stake falls below the minimum
    if validator_info.stake < min_stake {
        validator_info.active = false;
    }

    // Write the updated validator info back to storage
    self.validators.entry(validator).write(validator_info);

    // Transfer slashed funds to the prediction market
    let pm = IPredictionMarketDispatcher { contract_address: self.prediction_market.read() };
    let stake_token = IERC20Dispatcher { contract_address: pm.get_stake_token() };
    stake_token.transfer(self.prediction_market.read(), slash_amount);

    // Emit event
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
            let local_info = self.validators.entry(validator).read();
            ValidatorInfo {
                stake: local_info.stake,
                markets_resolved: local_info.markets_resolved,
                accuracy_score: local_info.accuracy_score,
                active: local_info.active,
            }
        }

        fn is_active_validator(
            self: @ContractState,
            validator: ContractAddress,
        ) -> bool {
            self.validators.entry(validator).read().active
        }

        fn get_validators_array(
            self: @ContractState,
        ) -> Array<ContractAddress> { 
            self.validators_array.get()
        }
    }

    // Internal Implementation
    #[generate_trait]
    impl InternalImpl of InternalTrait {
        fn get_validator_by_index(self: @ContractState, index: u32) -> ContractAddress {
            // Ensure the index is within bounds
            let validator_count = self.validator_count.read();
            assert(index < validator_count, 'Invalid validator index');
        
            // Read the validators array from storage (default value if not found)
            let validators_array: Array<ContractAddress> = self.validators_array.entry().read();
        
            // Return the validator at the given index
            validators_array.get(index)
        }
        fn calculate_accuracy(self: @ContractState, validator: ContractAddress) -> u32 {
            // Read the validator info from storage (default value if not found)
            let validator_info: LocalValidatorInfo = self.validators.entry(validator).read();
        
            // Validate that the validator exists
            if !validator_info.active {
                panic('Validator not found or inactive');
            }
        
            // Calculate accuracy score
            let total = validator_info.markets_resolved;
            if total == 0 {
                return 0;
            }
        
            ((total - validator_info.disputed_resolutions) * 100) / total
        }
}