# Multi-Token Support Usage Guide

Your StakCast prediction contract now supports multiple tokens! Users can bet with USDC, STRK, ETH, or custom tokens. This guide shows you how to use the new functionality.

## Overview

The multi-token system allows:

- **Betting with different tokens**: USDC, STRK, ETH, and custom tokens
- **Per-market token consistency**: Each market uses one token type
- **Backward compatibility**: Existing `place_bet()` still works
- **Admin control**: Only admins can add/remove supported tokens

## Key Features

### 1. **Multiple Betting Functions**

```cairo
// Original (uses default token)
place_bet(market_id, choice, amount, market_type)

// Multi-token versions
place_bet_with_token(market_id, choice, amount, market_type, token_name)
place_wager_with_token(market_id, choice, amount, market_type, token_name)
```

### 2. **Token Management**

```cairo
// Check if token is supported
is_token_supported('USDC') -> bool

// Get token address
get_supported_token('STRK') -> ContractAddress

// Get token used for a specific market
get_market_token(market_id) -> ContractAddress
```

### 3. **Admin Functions**

```cairo
// Add new token
add_supported_token('MYTOKEN', token_address)

// Remove token
remove_supported_token('MYTOKEN')

// Emergency withdraw specific token
emergency_withdraw_specific_token('USDC', amount, recipient)
```

## Usage Examples

### For Users

#### 1. **Check Supported Tokens**

```cairo
// Check what tokens are available
let is_usdc_supported = prediction_hub.is_token_supported('USDC');
let is_strk_supported = prediction_hub.is_token_supported('STRK');
let is_eth_supported = prediction_hub.is_token_supported('ETH');
```

#### 2. **Place Bet with USDC**

```cairo
// First approve the tokens
usdc_token.approve(prediction_hub_address, bet_amount);

// Place bet with USDC
prediction_hub.place_bet_with_token(
    market_id: 1,
    choice_idx: 0,        // Betting on choice 0 (Yes)
    amount: 1000 * 10^18, // 1000 USDC (18 decimals)
    market_type: 0,       // General prediction market
    token_name: 'USDC'
);
```

#### 3. **Place Bet with STRK**

```cairo
// Approve STRK tokens
strk_token.approve(prediction_hub_address, bet_amount);

// Place bet with STRK
prediction_hub.place_bet_with_token(
    market_id: 2,
    choice_idx: 1,        // Betting on choice 1 (No)
    amount: 500 * 10^18,  // 500 STRK
    market_type: 0,
    token_name: 'STRK'
);
```

#### 4. **Check Market Token**

```cairo
// See what token a market uses
let market_token = prediction_hub.get_market_token(market_id);
```

### For Admins

#### 1. **Add Custom Token**

```cairo
// Deploy your custom token first
let my_token = deploy_custom_token();

// Add it to supported tokens
prediction_hub.add_supported_token('MYTOKEN', my_token.contract_address);
```

#### 2. **Remove Token Support**

```cairo
// Remove a token (users can no longer bet with it)
prediction_hub.remove_supported_token('OLDTOKEN');
```

#### 3. **Emergency Token Withdrawal**

```cairo
// Withdraw specific tokens in emergency
prediction_hub.emergency_withdraw_specific_token(
    'USDC',
    emergency_amount,
    safe_wallet_address
);
```

## Important Rules

### 1. **One Token Per Market**

```cairo
// ✅ This works - first bet sets market token
user1.place_bet_with_token(market_1, 0, 1000, 0, 'USDC');

// ✅ This works - same token as first bet
user2.place_bet_with_token(market_1, 1, 500, 0, 'USDC');

// ❌ This fails - different token on same market
user3.place_bet_with_token(market_1, 0, 200, 0, 'STRK'); // Error!
```

### 2. **Different Markets Can Use Different Tokens**

```cairo
// ✅ This works - different markets
user1.place_bet_with_token(market_1, 0, 1000, 0, 'USDC');  // Market 1 = USDC
user2.place_bet_with_token(market_2, 1, 500, 0, 'STRK');   // Market 2 = STRK
```

### 3. **Backward Compatibility**

```cairo
// ✅ This still works - uses default token
prediction_hub.place_bet(market_id, choice, amount, market_type);
```

## Fee Collection

Fees are collected in the same token as the bet:

- **USDC bet** → **USDC fees** to fee recipient
- **STRK bet** → **STRK fees** to fee recipient
- **ETH bet** → **ETH fees** to fee recipient

```cairo
// Fee recipient receives fees in multiple tokens
let usdc_fees = usdc_token.balance_of(fee_recipient);
let strk_fees = strk_token.balance_of(fee_recipient);
let eth_fees = eth_token.balance_of(fee_recipient);
```

## Deployment Guide

### For Testnet/Development

```cairo
// 1. Deploy prediction contract
let prediction_hub = deploy_prediction_contract(admin, fee_recipient, oracle, default_token);

// 2. Add mock tokens for testing
prediction_hub.add_supported_token('USDC', mock_usdc_address);
prediction_hub.add_supported_token('STRK', mock_strk_address);
prediction_hub.add_supported_token('ETH', mock_eth_address);
```

### For Mainnet

```cairo
// 1. Deploy prediction contract
let prediction_hub = deploy_prediction_contract(admin, fee_recipient, oracle, default_token);

// 2. Add real Starknet token addresses
prediction_hub.add_supported_token('USDC', 0x053c91253bc9682c04929ca02ed00b3e423f6710d2ee7e0d5ebb06f3ecf368a8);
prediction_hub.add_supported_token('STRK', 0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d);
prediction_hub.add_supported_token('ETH', 0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7);
```

## Error Handling

Common errors and their meanings:

| Error                            | Meaning                                      | Solution               |
| -------------------------------- | -------------------------------------------- | ---------------------- |
| `'Unsupported token'`            | Token not added by admin                     | Ask admin to add token |
| `'Market token mismatch'`        | Trying to use different token on same market | Use the market's token |
| `'Insufficient token balance'`   | Not enough tokens                            | Get more tokens        |
| `'Insufficient token allowance'` | Haven't approved tokens                      | Call `approve()` first |
| `'Only admin allowed'`           | Non-admin trying admin function              | Must be admin          |

## Migration from Single Token

If you're upgrading from a single-token system:

### 1. **No Breaking Changes**

```cairo
// Old code still works
prediction_hub.place_bet(market_id, choice, amount, market_type);
```

### 2. **Add Multi-Token Support Gradually**

```cairo
// Start using new functions when ready
prediction_hub.place_bet_with_token(market_id, choice, amount, market_type, 'USDC');
```

### 3. **Update Frontend**

```typescript
// Add token selection to your UI
const supportedTokens = ["USDC", "STRK", "ETH"];
const selectedToken = "USDC";

// Call appropriate function
await predictionHub.place_bet_with_token(
  marketId,
  choice,
  amount,
  marketType,
  selectedToken
);
```

## Security Considerations

1. **Admin Control**: Only admins can add/remove tokens
2. **Token Validation**: Contract validates all token addresses
3. **Market Consistency**: One token per market prevents confusion
4. **Emergency Functions**: Admins can withdraw tokens if needed
5. **No Hardcoded Addresses**: Tokens must be explicitly added

## Testing

The comprehensive test suite covers:

- Multi-token betting functionality
- Token management (add/remove)
- Market consistency enforcement
- Fee collection in multiple tokens
- Emergency withdrawal functions
- Backward compatibility

Run tests with:

```bash
snforge test
```

## Summary

The multi-token system provides:

- **Flexibility**: Users choose their preferred token
- **Safety**: One token per market prevents confusion
- **Compatibility**: Existing code continues to work
- **Control**: Admins manage supported tokens
- **Scalability**: Easy to add new tokens

This makes your prediction markets accessible to users holding different tokens while maintaining security and simplicity.
