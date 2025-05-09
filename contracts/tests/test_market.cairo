use core::array::ArrayTrait;
use core::traits::Into;
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, declare, start_cheat_caller_address,
    stop_cheat_caller_address,
};
use stakcast::interfaces::IMarket::{IPredictionMarketDispatcher, IPredictionMarketDispatcherTrait};
use starknet::{ContractAddress, contract_address_const};

fn setup() -> (ContractAddress, ContractAddress, IPredictionMarketDispatcher) {
    let sender: ContractAddress = contract_address_const::<'sender'>();

    // Deploy mock ERC20
    let erc20_class = declare("MockUsdc").unwrap().contract_class();
    let mut calldata = array![sender.into(), sender.into(), 6];
    let (erc20_address, _) = erc20_class.deploy(@calldata).unwrap();

    // Deploy Prediction Market contract
    let market_class = declare("PredictionMarket").unwrap().contract_class();
    let admin = contract_address_const::<'admin'>();
    let mut calldata = array![admin.into(), erc20_address.into()];
    let (market_address, _) = market_class.deploy(@calldata).unwrap();

    (erc20_address, sender, IPredictionMarketDispatcher { contract_address: market_address })
}
