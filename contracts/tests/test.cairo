#[cfg(test)]
mod tests {
    use starknet::testing::{set_contract_address, set_caller_address, set_block_timestamp};
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::get_block_timestamp;
    use starknet::assert;
    use super::market::{MarketDispatcher, MarketDispatcherTrait};
    use super::prediction::{PredictionMarketDispatcher, PredictionMarketDispatcherTrait};
    use super::interfaces::{IERC20Dispatcher, IMarketValidatorDispatcher};
    use super::lib::{
        types::{Market, MarketStatus, Position, MarketOutcome},
        constants::{MIN_OUTCOMES, RESOLUTION_WINDOW},
        utils::{is_market_active, calculate_fee},
    };

    const STAKE_TOKEN_ADDRESS: ContractAddress = 0x12345;
    const FEE_COLLECTOR: ContractAddress = 0x67890;
    const PLATFORM_FEE: u256 = 100; // 1% fee

    #[test]
    fn test_create_market() {
        let market = PredictionMarketDispatcher::deploy(STAKE_TOKEN_ADDRESS, FEE_COLLECTOR, PLATFORM_FEE);
        set_caller_address(0x11111);

        let market_id = market.create_market(
            'Market Title',
            'Market Description',
            'Category',
            1000, // start_time
            2000, // end_time
            array!['Outcome 1', 'Outcome 2'],
            10, // min_stake
            1000, // max_stake
        );

        assert(market_id == 1, 'Market ID should be 1');

        let (market_details, status, outcome) = market.get_market_details(market_id);
        assert(market_details.creator == 0x11111, 'Creator should be caller');
        assert(status == MarketStatus::Active, 'Market should be active');
        assert(outcome.is_none(), 'Market outcome should be None');
    }

    #[test]
    fn test_take_position() {
        let market = PredictionMarketDispatcher::deploy(STAKE_TOKEN_ADDRESS, FEE_COLLECTOR, PLATFORM_FEE);
        set_caller_address(0x11111);

        let market_id = market.create_market(
            'Market Title',
            'Market Description',
            'Category',
            1000, // start_time
            2000, // end_time
            array!['Outcome 1', 'Outcome 2'],
            10, // min_stake
            1000, // max_stake,
        );

        set_caller_address(0x22222);
        set_block_timestamp(1500); // Within market timeframe

        // Simulate ERC20 token transfer approval
        let stake_token = IERC20Dispatcher { contract_address: STAKE_TOKEN_ADDRESS };
        stake_token.approve(market.contract_address, 100);

        market.take_position(market_id, 0, 100); // Stake 100 on Outcome 1

        let position = market.get_user_position(0x22222, market_id);
        assert(position.amount == 100, 'Stake amount should be 100');
        assert(position.outcome_index == 0, 'Outcome index should be 0');
        assert(!position.claimed, 'Position should not be claimed');

        let (total_stake, stakes_per_outcome) = market.get_market_stats(market_id);
        assert(total_stake == 100, 'Total stake should be 100');
        assert(stakes_per_outcome[0] == 100, 'Stake for Outcome 1 should be 100');
    }

    #[test]
    fn test_claim_winnings() {
        let market = PredictionMarketDispatcher::deploy(STAKE_TOKEN_ADDRESS, FEE_COLLECTOR, PLATFORM_FEE);
        set_caller_address(0x11111);

        let market_id = market.create_market(
            'Market Title',
            'Market Description',
            'Category',
            1000, // start_time
            2000, // end_time
            array!['Outcome 1', 'Outcome 2'],
            10, // min_stake
            1000, // max_stake,
        );

        set_caller_address(0x22222);
        set_block_timestamp(1500); // Within market timeframe

        // Simulate ERC20 token transfer approval
        let stake_token = IERC20Dispatcher { contract_address: STAKE_TOKEN_ADDRESS };
        stake_token.approve(market.contract_address, 100);

        market.take_position(market_id, 0, 100); // Stake 100 on Outcome 1

        set_caller_address(0x11111); // Resolver
        set_block_timestamp(2500); // After market end time
        market.resolve_market(market_id, 0, 'Outcome 1 resolved');

        set_caller_address(0x22222);
        market.claim_winnings(market_id);

        let position = market.get_user_position(0x22222, market_id);
        assert(position.claimed, 'Position should be claimed');

        let (_, _, outcome) = market.get_market_details(market_id);
        assert(outcome.is_some(), 'Market should have an outcome');
        assert(outcome.unwrap().winning_outcome == 0, 'Winning outcome should be 0');
    }

    #[test]
    fn test_slash_validator() {
        let market = PredictionMarketDispatcher::deploy(STAKE_TOKEN_ADDRESS, FEE_COLLECTOR, PLATFORM_FEE);
        set_caller_address(0x11111);

        let market_id = market.create_market(
            'Market Title',
            'Market Description',
            'Category',
            1000, // start_time
            2000, // end_time
            array!['Outcome 1', 'Outcome 2'],
            10, // min_stake
            1000, // max_stake,
        );

        set_caller_address(0x22222); // Validator
        set_block_timestamp(1500); // Within market timeframe

        // Simulate ERC20 token transfer approval
        let stake_token = IERC20Dispatcher { contract_address: STAKE_TOKEN_ADDRESS };
        stake_token.approve(market.contract_address, 100);

        market.take_position(market_id, 0, 100); // Stake 100 on Outcome 1

        set_caller_address(0x11111); // Resolver
        set_block_timestamp(2500); // After market end time
        market.resolve_market(market_id, 0, 'Outcome 1 resolved');

        set_caller_address(0x22222); // Validator
        market.claim_winnings(market_id);

        set_caller_address(0x11111); // Resolver
        market.slash_validator(0x22222, 50, 'Validator misbehavior');

        let validator_info = market.get_validator_info(0x22222);
        assert(validator_info.stake == 50, 'Validator stake should be reduced to 50');
        assert(validator_info.active, 'Validator should still be active');
    }
}