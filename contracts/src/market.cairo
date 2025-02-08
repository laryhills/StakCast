#[starknet::contract]
mod MarketValidator {
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::get_block_timestamp;
    use starknet::storage;
    use starknet::event;
    use starknet::assert;
    use starknet::transfer_from;

    // Import shared components from lib.cairo and interface.cairo
    use super::interfaces::{ValidatorInfo, Market, MarketStatus, IPredictionMarketDispatcher, IERC20Dispatcher};
    use super::lib::{
        constants::{MIN_STAKE, RESOLUTION_TIMEOUT},
        events::{ValidatorRegistered, MarketResolved, ValidatorSlashed},
        utils::{is_market_active, calculate_fee},
    };

    #[storage]
    struct Storage {
        prediction_market: ContractAddress,
        validators: LegacyMap<ContractAddress, ValidatorInfo>,
        validator_count: u32,
        min_stake: u256,
        resolution_timeout: u64,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        ValidatorRegistered: ValidatorRegistered,
        MarketResolved: MarketResolved,
        ValidatorSlashed: ValidatorSlashed,
    }

    #[constructor]
    fn constructor(
        ref self: Storage,
        prediction_market: ContractAddress,
        min_stake: u256,
        resolution_timeout: u64,
    ) {
        self.prediction_market.write(prediction_market);
        self.min_stake.write(min_stake);
        self.resolution_timeout.write(resolution_timeout);
    }

    #[external]
    fn register_validator(ref self: Storage, stake: u256) {
        let caller = get_caller_address();
        assert(stake >= self.min_stake.read(), 'Insufficient stake');

        // Transfer stake
        let transfer_result = transfer_from(caller, self.address, stake);
        assert(transfer_result, 'Stake transfer failed');

        // Update validator info
        let mut validator = self.validators.read(caller);
        validator.stake += stake;
        validator.markets_resolved = 0;
        validator.accuracy_score = 100;
        validator.active = true;
        self.validators.write(caller, validator);

        self.validator_count.write(self.validator_count.read() + 1);

        self.emit(ValidatorRegistered { validator: caller, stake });
    }

    #[external]
    fn resolve_market(
        ref self: Storage,
        market_id: u32,
        winning_outcome: u32,
        resolution_details: felt252,
    ) {
        let caller = get_caller_address();
        assert(self.is_active_validator(caller), 'Not an active validator');

        let market = self.get_market_info(market_id);
        assert(market.validator == caller, 'Not assigned validator');

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

        self.resolve_market_internal(market_id, winning_outcome, resolution_details);
    }

    #[internal]
    fn resolve_market_internal(
        ref self: Storage,
        market_id: u32,
        winning_outcome: u32,
        resolution_details: felt252,
    ) {
        self.emit(MarketResolved {
            market_id,
            outcome: winning_outcome,
            resolver: get_caller_address(),
            resolution_details,
        });
    }

    #[external]
    fn slash_validator(ref self: Storage, validator: ContractAddress, amount: u256, reason: felt252) {
        assert(get_caller_address() == self.prediction_market.read(), 'Unauthorized');
        let mut validator_info = self.validators.read(validator);
        assert(validator_info.stake >= amount, 'Insufficient stake');

        validator_info.stake -= amount;
        if validator_info.stake < self.min_stake.read() {
            validator_info.active = false;
        }
        self.validators.write(validator, validator_info);

        self.emit(ValidatorSlashed { validator, amount, reason });
    }

    #[external]
    fn get_validator_info(self: @Storage, validator: ContractAddress) -> ValidatorInfo {
        self.validators.read(validator)
    }

    #[external]
    fn is_active_validator(self: @Storage, validator: ContractAddress) -> bool {
        self.validators.read(validator).active
    }
}