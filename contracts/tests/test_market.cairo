use crate::test_utils::default_create_sports_prediction;
use crate::test_utils::default_create_crypto_prediction;
use crate::test_utils::default_create_predictions;
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, EventSpyTrait, declare, spy_events,
    start_cheat_block_timestamp, start_cheat_caller_address, stop_cheat_caller_address,
};
use stakcast::admin_interface::{IAdditionalAdminDispatcher, IAdditionalAdminDispatcherTrait};
use stakcast::interface::{IPredictionHubDispatcher, IPredictionHubDispatcherTrait};
use starknet::{ContractAddress, contract_address_const, get_block_timestamp};
use crate::test_utils::{
    ADMIN_ADDR, FEE_RECIPIENT_ADDR, MODERATOR_ADDR, USER1_ADDR, USER2_ADDR,
    create_business_prediction, create_crypto_prediction, create_sports_prediction,
    create_test_market, setup_test_environment,
};

// ================ General Prediction Market Tests ================

#[test]
fn test_create_prediction_market_success() {
    let (contract, _admin_interface, _token) = setup_test_environment();

    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    default_create_predictions(contract);
    stop_cheat_caller_address(contract.contract_address);
    let count = contract.get_prediction_count();
    assert(count == 1, 'Market count should be 1');

}

#[test]
fn test_create_multiple_prediction_markets() {
    let (contract, _admin_contract, _token) = setup_test_environment();

    start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());
    let mut spy = spy_events();
    let future_time = get_block_timestamp() + 86400;
    // Create first market
    default_create_predictions(contract);

    // Fetch market_id for first market
    let market1_id = match spy.get_events().events.into_iter().last() {
        Option::Some((_, event)) => (*event.data.at(0)).into(),
        Option::None => panic!("No MarketCreated event emitted"),
    };
    // spy.clear_events(); // Clear events to avoid confusion

    // Create second market
    contract
        .create_predictions(
            "Market 2",
            "Description 2",
            ('True', 'False'),
            'category2',
            "https://example.com/2.png",
            future_time + 3600,
            0, // Normal general prediction market
            None,
            None,
            None,
        );

    // Fetch market_id for second market
    let market2_id = match spy.get_events().events.into_iter().last() {
        Option::Some((_, event)) => (*event.data.at(0)).into(),
        Option::None => panic!("No MarketCreated event emitted"),
    };

    // Verify market count
    let count = contract.get_prediction_count();
    assert(count == 2, 'Should have 2 markets');

    // Verify both markets exist and have correct IDs
    let market1 = contract.get_prediction(market1_id, 0);
    let market2 = contract.get_prediction(market2_id, 0);

    assert(market1.market_id == market1_id, 'Market 1 ID mismatch');
    assert(market2.market_id == market2_id, 'Market 2 ID mismatch');
    assert(market1.title == "Market 1", 'Market 1 title mismatch');
    assert(market2.title == "Market 2", 'Market 2 title mismatch');

    stop_cheat_caller_address(contract.contract_address);
}

#[test]
#[should_panic(expected: 'Contract is paused')]
fn test_create_market_should_panic_if_contract_is_pasued() {
    let (contract, _admin_contract, _token) = setup_test_environment();
    let admin_dispatcher = IAdditionalAdminDispatcher {contract_address: contract.contract_address };

    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR().into());
    admin_dispatcher.emergency_pause("Testing Contract Paused");
    stop_cheat_caller_address(contract.contract_address);

    // try creating a new market
    default_create_predictions(contract);
}

#[test]
#[should_panic(expected: 'Market creation paused')]
fn test_create_market_should_panic_if_market_creation_is_pasued() {
    let (contract, _admin_contract, _token) = setup_test_environment();
    let admin_dispatcher = IAdditionalAdminDispatcher {contract_address: contract.contract_address };
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR().into());
    admin_dispatcher.pause_market_creation();
    stop_cheat_caller_address(contract.contract_address);
    default_create_predictions(contract);
}

#[test]
#[should_panic(expected: 'Only admin or moderator')]
fn test_create_market_should_panic_if_non_admin_tries_to_create() {
    let (contract, _admin_contract, _token) = setup_test_environment();
    start_cheat_caller_address(contract.contract_address, USER2_ADDR().into());
    default_create_predictions(contract);
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
#[should_panic(expected: 'End time must be in future')]
fn test_create_market_should_panic_if_end_time_not_in_future() {
    let (contract, _admin_contract, _token) = setup_test_environment();
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR().into());
    let past_time = get_block_timestamp() - 86400;
    contract.create_predictions(
        "Market 2",
        "Description 2",
        ('True', 'False'),
        'category2',
        "https://example.com/2.png",
        past_time,
        0, // Normal general prediction market
        None,
        None,
        None,
    );
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
#[should_panic(expected: 'Market duration too short')]
fn test_create_market_should_panic_if_end_time_is_too_short() {
    let (contract, _admin_contract, _token) = setup_test_environment();
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR().into());
    let small_time = get_block_timestamp() + 10;
    contract.create_predictions(
        "Market 2",
        "Description 2",
        ('True', 'False'),
        'category2',
        "https://example.com/2.png",
        small_time,
        0,
        None,
        None,
        None,
    );
    stop_cheat_caller_address(contract.contract_address);
}

#[test]
#[should_panic(expected: 'Market duration too long')]
fn test_create_market_should_panic_if_end_time_is_too_long() {
    let (contract, _admin_contract, _token) = setup_test_environment();
    start_cheat_caller_address(contract.contract_address, ADMIN_ADDR().into());
    let large_time = get_block_timestamp() + 1000000000;
    contract.create_predictions(
        "Market 2",
        "Description 2",
        ('True', 'False'),
        'category2',
        "https://example.com/2.png",
        large_time,
        0,
        None,
        None,
        None,
    );
    stop_cheat_caller_address(contract.contract_address);
}


// // ================ Crypto Prediction Market Tests ================

// #[test]
// fn test_create_crypto_prediction_success() {
//     let (contract, _admin_contract, _token) = setup_test_environment();
//     let mut spy = spy_events();

//     start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());

//     default_create_crypto_prediction(contract);

//     // Fetch market_id from MarketCreated event
//     let market_id = match spy.get_events().events.into_iter().last() {
//         Option::Some((_, event)) => (*event.data.at(0)).into(),
//         Option::None => panic!("No MarketCreated event emitted"),
//     };

//     stop_cheat_caller_address(contract.contract_address);

//     // Verify market count
//     let count = contract.get_prediction_count();
//     assert(count == 1, 'Market count should be 1');

//     // Verify crypto market data
//     let crypto_market = contract.get_prediction(market_id, 1);
//     assert(crypto_market.market_id == market_id, 'Market ID mismatch');
//     assert(crypto_market.title == "ETH Price Prediction", 'Title mismatch');
//     assert(crypto_market.is_open, 'Market should be open');
//     assert(!crypto_market.is_resolved, 'Market not resolved');
//     assert(crypto_market.prediction_market_type == 1, 'Prediction market type mismatch');
//     let (crypto_prediction_option_1, crypto_prediction_option_2) = crypto_market.crypto_prediction.unwrap();
//     assert(crypto_prediction_option_1 == 'ETH', 'Asset key mismatch');
//     assert(crypto_prediction_option_2 == 3000, 'Target value mismatch');

//     // Verify choices;
// }

// // // ================ Sports Prediction Market Tests ================

// #[test]
// fn test_create_sports_prediction_success() {
//     let (contract, _admin_contract, _token) = setup_test_environment();
//     let mut spy = spy_events();

//     start_cheat_caller_address(contract.contract_address, MODERATOR_ADDR());

//     default_create_sports_prediction(contract);

//     // Fetch market_id from MarketCreated event
//     let market_id = match spy.get_events().events.into_iter().last() {
//         Option::Some((_, event)) => (*event.data.at(0)).into(),
//         Option::None => panic!("No MarketCreated event emitted"),
//     };

//     stop_cheat_caller_address(contract.contract_address);

//     // Verify market count
//     let count = contract.get_prediction_count();
//     assert(count == 1, 'Market count should be 1');

//     // Verify sports market data
//     let sports_market = contract.get_prediction(market_id, 2);
//     let (event_id, team_flag) = sports_market.sports_prediction.unwrap();
//     assert(sports_market.market_id == market_id, 'Market ID should be 1');
//     assert(sports_market.title == "Lakers vs Warriors", 'Title mismatch');
//     assert(event_id == 123456, 'Event ID 123456');
//     assert(team_flag, 'Team flag true');
//     assert(sports_market.is_open, 'Market should be open');
//     assert(!sports_market.is_resolved, 'Market not resolved');
//     assert(sports_market.prediction_market_type == 2, 'Prediction market type mismatch');

//     let (detail_0, detail_1) = sports_market.sports_prediction.unwrap();

//     assert(detail_0 == 123456, 'Option not set correctly');
//     assert(!detail_1, 'option not set correctly');

// }
