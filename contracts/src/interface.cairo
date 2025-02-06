// interfaces.cairo
#[starknet::interface]
pub trait IPredictionMarketDispatcher<T> {
    fn resolve_market(
        self: @T,
        market_id: u32,
        winning_outcome: u32,
        resolution_details: felt252
    );
    fn get_market_info(self: @T, market_id: u32) -> Market;
    fn get_market_status(self: @T, market_id: u32) -> MarketStatus;
}

#[starknet::interface]
pub trait IMarketValidatorDispatcher<T> {
    fn slash_validator(
        self: @T,
        validator: ContractAddress,
        amount: u256,
        reason: felt252
    );
    fn get_validator_info(self: @T, validator: ContractAddress) -> ValidatorInfo;
    fn is_active_validator(self: @T, validator: ContractAddress) -> bool;
}

#[starknet::interface]
pub trait IERC20Dispatcher<T> {
    fn transfer(self: @T, recipient: ContractAddress, amount: u256);
    fn transfer_from(self: @T, sender: ContractAddress, recipient: ContractAddress, amount: u256);
    fn approve(self: @T, spender: ContractAddress, amount: u256);
}