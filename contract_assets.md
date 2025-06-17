# Starknet Sepolia Deployment & Interaction Guide

## 1. Prerequisites

- **sncast** installed (`cargo install sncast` or via Scarb)
- **Scarb** for contract compilation
- **Funded Starknet Sepolia account** (OpenZeppelin/ArgentX, etc.)
- **snfoundry.toml** configured:

```toml
[sncast.default]
account = "stakcast"
accounts-file = "/Users/macbookprom1/.starknet_accounts/starknet_open_zeppelin_accounts.json"
url = "https://starknet-sepolia.public.blastapi.io/rpc/v0_8"
```

## 2. Key Addresses and Keys Used

- **Admin/Deployer Account Alias:** `stakcast`
- **Admin/Deployer Address:**
  `0x4aef21d7d5af642acbb0d09180652e035d233da06c1a91872e0726f0c2093f9`
- **Admin/Deployer Public Key:**
  `0x1b93f3329a9769c422d6bcfb45331252f8ebc2501477b2a09cf7427f5f799ca`
- **Admin/Deployer Private Key:**
  `0xb00eeae9ea5fd727e5bf60847a9d838ee15b0964d0257984661cbc7a8894f`
- **Pragma Oracle Address (Sepolia):**
  `0x36031daa264c24520b11d93af622c848b2499b66b41d611bac95e13cfca131a`
- **Accounts File:** `/Users/macbookprom1/.starknet_accounts/starknet_open_zeppelin_accounts.json`

## 3. Compile Contracts

```sh
scarb build
```

## 4. Declare Contracts

### Declare MockERC20

```sh
sncast declare --contract-name MockERC20
```

- **Class Hash:** `0x0013f9bc00abdd783535890136d15e28c11cae49f4433ef08c4de2e3f6580390`
- [Starkscan Class Link](https://sepolia.starkscan.co/class/0x0013f9bc00abdd783535890136d15e28c11cae49f4433ef08c4de2e3f6580390)

### Declare PredictionHub

```sh
sncast declare --contract-name PredictionHub
```

- **Class Hash:** `0x05beb701d2a500fc76aac9806594fc98cdae65506cba8f53b3b502c1878a1190`
- [Starkscan Class Link](https://sepolia.starkscan.co/class/0x05beb701d2a500fc76aac9806594fc98cdae65506cba8f53b3b502c1878a1190)

## 5. Deploy Contracts

### Deploy MockERC20

```sh
sncast deploy \
  --class-hash 0x0013f9bc00abdd783535890136d15e28c11cae49f4433ef08c4de2e3f6580390 \
  --constructor-calldata 0x4aef21d7d5af642acbb0d09180652e035d233da06c1a91872e0726f0c2093f9
```

- **Deployed Token Address:** `0x036b9edb4b6d4f67a92af75be657c593e9d65d74a91b47db0e22a9e68d1d4f09`
- [Starkscan Contract Link](https://sepolia.starkscan.co/contract/0x036b9edb4b6d4f67a92af75be657c593e9d65d74a91b47db0e22a9e68d1d4f09)

### Deploy PredictionHub

```sh
sncast deploy \
  --class-hash 0x05beb701d2a500fc76aac9806594fc98cdae65506cba8f53b3b502c1878a1190 \
  --constructor-calldata \
    0x4aef21d7d5af642acbb0d09180652e035d233da06c1a91872e0726f0c2093f9 \
    0x4aef21d7d5af642acbb0d09180652e035d233da06c1a91872e0726f0c2093f9 \
    0x36031daa264c24520b11d93af622c848b2499b66b41d611bac95e13cfca131a \
    0x036b9edb4b6d4f67a92af75be657c593e9d65d74a91b47db0e22a9e68d1d4f09
```

- **Deployed Hub Address:** `0x004acb0f694dbcabcb593a84fcb44a03f8e1b681173da5d0962ed8a171689534`
- [Starkscan Contract Link](https://sepolia.starkscan.co/contract/0x004acb0f694dbcabcb593a84fcb44a03f8e1b681173da5d0962ed8a171689534)

## 6. Upgrade the Contract

To upgrade the implementation (admin only):

1. Declare the new contract version:
   ```sh
   sncast declare --contract-name <NewContract>
   # Copy the new class_hash
   ```
2. Call the `upgrade` function on the deployed contract:
   ```sh
   sncast invoke \
     --contract-address 0x004acb0f694dbcabcb593a84fcb44a03f8e1b681173da5d0962ed8a171689534 \
     --function upgrade \
     --calldata <new_class_hash>
   ```

## 7. Interact with the Deployed Contract

### Example: Add a Moderator

```sh
sncast invoke \
  --contract-address 0x004acb0f694dbcabcb593a84fcb44a03f8e1b681173da5d0962ed8a171689534 \
  --function add_moderator \
  --calldata <moderator_address>
```

### Example: Create a Market

```sh
sncast invoke \
  --contract-address 0x004acb0f694dbcabcb593a84fcb44a03f8e1b681173da5d0962ed8a171689534 \
  --function create_prediction \
  --calldata <title> <description> <choice0> <choice1> <category> <image_url> <end_time>
```

### Example: Query Contract State

```sh
sncast call \
  --contract-address 0x004acb0f694dbcabcb593a84fcb44a03f8e1b681173da5d0962ed8a171689534 \
  --function get_prediction_count
```

## 8. Useful Links

- [Starkscan Sepolia](https://sepolia.starkscan.co/)
- [Pragma Oracle Docs](https://docs.pragma.build/)
- [Pragma Sepolia Oracle Address](https://sepolia.starkscan.co/contract/0x36031daa264c24520b11d93af622c848b2499b66b41d611bac95e13cfca131a)

## 9. Approve and Place a Bet

### **A. Approve the PredictionHub Contract to Spend Your Tokens**

The ERC20 `approve` function expects:

- `spender: ContractAddress`
- `amount: u256` (as two felts: `[low, high]`)

**Example (approve 1 token for PredictionHub):**

```sh
sncast invoke \
  --contract-address 0x036b9edb4b6d4f67a92af75be657c593e9d65d74a91b47db0e22a9e68d1d4f09 \
  --function approve \
  --calldata 0x004acb0f694dbcabcb593a84fcb44a03f8e1b681173da5d0962ed8a171689534 1000000000000000000 0
```

- `0x004acb0f694dbcabcb593a84fcb44a03f8e1b681173da5d0962ed8a171689534` = PredictionHub contract address
- `1000000000000000000 0` = 1 token (u256: low, high)

---

### **B. Place a Bet**

The `place_bet` function expects:

- `market_id: u256` (as two felts: `[low, high]`)
- `choice_idx: u8`
- `amount: u256` (as two felts: `[low, high]`)
- `market_type: u8`

**Example (bet 1 token on market 1, choice 0, general prediction):**

```sh
sncast invoke \
  --contract-address 0x004acb0f694dbcabcb593a84fcb44a03f8e1b681173da5d0962ed8a171689534 \
  --function place_bet \
  --calldata 1 0 0 1000000000000000000 0 0
```

- `1 0` = market_id (u256: low, high)
- `0` = choice_idx (first choice)
- `1000000000000000000 0` = amount (u256: low, high, minimum bet)
- `0` = market_type (general prediction)

---

**Note:**

- Always encode `u256` values as two felts: `[low, high]`.
- Make sure the user has enough tokens and has approved the contract before placing a bet.

---

**Example Transaction Links:**

- [Approve Transaction](https://sepolia.starkscan.co/tx/0x030221a086e7a76ef24b99bf2924e657f6a8bbabe1548bca0e069af1e39a9274)
- [Place Bet Transaction](https://sepolia.starkscan.co/tx/0x077fd728e05afbf79933b16b9327fe8662a18782647efcc584410f2aca67ebad)

---

**Security Note:**

- The private key and account details above are for demonstration. **Never share your real private key in production documentation!**

## 10. Encoding ByteArray Parameters with Packed Felts

Some Cairo contracts (including this PredictionHub) expect ByteArray parameters as:

- A length prefix (number of felts)
- Each felt is a packed string of up to 31 ASCII characters (converted to hex)

### **How to encode a ByteArray for calldata:**

1. **Split your string** into chunks of up to 31 ASCII characters.
2. **Convert each chunk** to a felt (hex). You can use Python:
   ```python
   def str_to_felt(s):
       return hex(int.from_bytes(s.encode(), "big"))
   print(str_to_felt("Test description."))
   ```
3. **Prefix the calldata** with the number of felts (chunks).
4. **Repeat for each ByteArray parameter.**

---

### **Example: Creating a Market with Packed Felts**

- **title:** "Will Bitcoin reach $100K in 2025" (fits in 1 felt)
  - `0x57696c6c20426974636f696e20726561636820243130304b20696e2032303235`
- **description:** "Predict if Bitcoin price will exceed $100000 by Dec 31 2025" (split into two felts):
  - `0x5072656469637420696620426974636f696e2070726963652077696c6c206578`
  - `0x636565642024313030303030206279204465632033312032303235`
- **image_url:** "https://test.com/btc.jpg" (fits in 1 felt):
  - `0x68747470733a2f2f746573742e636f6d2f6274632e6a7067`

**Sample sncast command:**

```sh
sncast invoke \
  --contract-address 0x004acb0f694dbcabcb593a84fcb44a03f8e1b681173da5d0962ed8a171689534 \
  --function create_prediction \
  --calldata \
    1 0x57696c6c20426974636f696e20726561636820243130304b20696e2032303235 \
    2 0x5072656469637420696620426974636f696e2070726963652077696c6c206578 0x636565642024313030303030206279204465632033312032303235 \
    0x596573 0x4e6f \
    0x63727970746f \
    1 0x68747470733a2f2f746573742e636f6d2f6274632e6a7067 \
    1767225600
```

---

**Note:**

- For each ByteArray, always prefix with the number of felts.
- Each felt can hold up to 31 ASCII characters.
- Use this pattern for all string parameters in contract calls.

---
