use starknet::ContractAddress;
use starknet::get_caller_address;
use starknet::get_block_timestamp;
use starknet::get_contract_address; // Added missing import.
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use stakcast::interface::{
    IPredictionMarketDispatcher, IPredictionMarketDispatcherTrait, ValidatorInfo, IMarketValidator
};
use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry, Map};

#[starknet::contract]
pub mod MarketValidator {
    use super::*;

    // Storage: Removed the array and introduced a mapping for index-based lookup.
    #[storage]
    struct Storage {
        prediction_market: ContractAddress,
        validators: Map<ContractAddress, LocalValidatorInfo>,
        validators_by_index: Map<u32, ContractAddress>, // mapping from index to validator address
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
    pub fn constructor(
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

            // Ensure the provided stake meets the minimum.
            assert!(stake >= self.min_stake.read(), "Insufficient stake");

            let pm = IPredictionMarketDispatcher { contract_address: self.prediction_market.read() };
            let stake_token_addr = pm.get_stake_token();

            let stake_token = IERC20Dispatcher { contract_address: stake_token_addr };
            // Use get_contract_address from Starknet.
            assert!(stake_token.transfer_from(caller, get_contract_address(), stake),
                "Stake transfer failed");

            let mut validator_info = self.validators.entry(caller).read();
            if !validator_info.active {
                // Initialize the validator info if not already active.
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

            if !validator_info.active {
                // Instead of appending to an array, we store the caller address in a mapping.
                let validator_count = self.validator_count.read();
                self.validators_by_index.entry(validator_count).write(caller);
                validator_info.validator_index = validator_count;
                self.validator_count.write(validator_count + 1);
            }

            // Update the validator's info.
            validator_info.stake = stake;
            validator_info.active = true;
            validator_info.markets_resolved = 0;
            validator_info.disputed_resolutions = 0;
            validator_info.accuracy_score = 0;

            self.validators.entry(caller).write(validator_info);

            self.emit(ValidatorRegistered { validator: caller, stake });
        }

        fn resolve_market(
            ref self: ContractState,
            market_id: u32,
            winning_outcome: u32,
            resolution_details: felt252,
        ) {
            let caller = get_caller_address();
            let current_time = get_block_timestamp();

            let mut validator_info = self.validators.entry(caller).read();

            if !validator_info.active {
                panic!("Validator not found or inactive");
            }

            // Ensure sufficient time has passed since the last resolution.
            assert!(current_time > validator_info.last_resolution_time + self.resolution_timeout.read(),
                    "Too frequent resolutions");

            validator_info.markets_resolved += 1;
            validator_info.last_resolution_time = current_time;

            self.validators.entry(caller).write(validator_info);

            let pm = IPredictionMarketDispatcher { contract_address: self.prediction_market.read() };
            pm.resolve_market(market_id, winning_outcome, resolution_details);

            self.emit(MarketResolved { market_id, resolver: caller, resolution_time: current_time });
        }

        fn slash_validator(
            ref self: ContractState,
            validator: ContractAddress,
            amount: u256,
            reason: felt252,
        ) {
            // Only the prediction market contract can perform slashing.
            assert!(get_caller_address() == self.prediction_market.read(),
                    "Unauthorized slashing");

            let mut validator_info = self.validators.entry(validator).read();

            if !validator_info.active {
                panic!("Validator not active");
            }

            let min_stake: u256 = self.min_stake.read().into();
            let slash_percentage: u256 = self.slash_percentage.read().into();

            let slash_amount = if amount == 0.into() {
                (validator_info.stake * slash_percentage) / 100.into()
            } else {
                core::cmp::min(amount, validator_info.stake)
            };

            validator_info.stake -= slash_amount;
            validator_info.disputed_resolutions += 1;

            if validator_info.stake < min_stake {
                validator_info.active = false;
            }

            self.validators.entry(validator).write(validator_info);

            let pm = IPredictionMarketDispatcher { contract_address: self.prediction_market.read() };
            let stake_token = IERC20Dispatcher { contract_address: pm.get_stake_token() };
            stake_token.transfer(self.prediction_market.read(), slash_amount);

            self.emit(ValidatorSlashed { validator, amount: slash_amount, reason });
        }

        fn get_validator_info(
            self: @ContractState,
            validator: ContractAddress,
        ) -> ValidatorInfo {
            let local_info = self.validators.entry(validator).read();
            ValidatorInfo {
                stake: local_info.stake,
                markets_resolved: local_info.markets_resolved,
                disputed_resolutions: local_info.disputed_resolutions,
                accuracy_score: local_info.accuracy_score,
                active: local_info.active,
                last_resolution_time: local_info.last_resolution_time,
                validator_index: local_info.validator_index,
            }
        }

        fn is_active_validator(
            self: @ContractState,
            validator: ContractAddress,
        ) -> bool {
            self.validators.entry(validator).read().active
        }

        // Implement missing trait items:
        fn get_validator_by_index(
            self: @ContractState,
            index: u32,
        ) -> ContractAddress {
            let validator_count = self.validator_count.read();
            assert!(index < validator_count, "Invalid validator index: {}", index);
            self.validators_by_index.entry(index).read()
        }

        fn get_validator_count(
            self: @ContractState,
        ) -> u32 {
            self.validator_count.read()
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        // Retrieve a validator's address by its index from the new mapping.
        fn get_validator_by_index(self: @ContractState, index: u32) -> ContractAddress {
            let validator_count = self.validator_count.read();
            assert!(index < validator_count, "Invalid validator index: {}", index);
            self.validators_by_index.entry(index).read()
        }

        fn calculate_accuracy(self: @ContractState, validator: ContractAddress) -> u32 {
            let validator_info = self.validators.entry(validator).read();
            if !validator_info.active {
                panic!("Validator not found or inactive");
            }
            let total = validator_info.markets_resolved;
            if total == 0 {
                return 0;
            }
            ((total - validator_info.disputed_resolutions) * 100) / total
        }
    }
}
