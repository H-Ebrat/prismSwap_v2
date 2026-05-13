/Users/harisebrat/Library/Python/3.9/lib/python/site-packages/urllib3/__init__.py:35: NotOpenSSLWarning: urllib3 v2 only supports OpenSSL 1.1.1+, currently the 'ssl' module is compiled with 'LibreSSL 2.8.3'. See: https://github.com/urllib3/urllib3/issues/3020
  warnings.warn(
# Analysis results for src/core/PrismSwapPair.sol

## Integer Arithmetic Bugs
- SWC ID: 101
- Severity: Low
- Contract: PrismSwapPair
- Function name: `sync()`
- PC address: 378
- Estimated Gas Usage: 1875 - 2538

### Description

The arithmetic operator can overflow.
It is possible to cause an integer overflow or underflow in the arithmetic operation.  This issue is reported for internal compiler generated code.

### Initial State:

Account: [CREATOR], balance: 0x0, nonce:0, storage:{}
Account: [ATTACKER], balance: 0x0, nonce:0, storage:{}

### Transaction Sequence

Caller: [CREATOR], calldata: , decoded_data: , value: 0x0
Caller: [ATTACKER], function: allowance(address,address), txdata: 0xdd62ed3e00000000000000000000000000000100000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000, decoded_data: ('0x0000010000000000000001000000000000000000', '0x0000000000000000000000000000000000000000'), value: 0x0


## Integer Arithmetic Bugs
- SWC ID: 101
- Severity: Low
- Contract: PrismSwapPair
- Function name: `maxPriceChangePercent()`
- PC address: 704
- Estimated Gas Usage: 1875 - 2538

### Description

The arithmetic operator can overflow.
It is possible to cause an integer overflow or underflow in the arithmetic operation.  This issue is reported for internal compiler generated code.

### Initial State:

Account: [CREATOR], balance: 0x0, nonce:0, storage:{}
Account: [ATTACKER], balance: 0x0, nonce:0, storage:{}

### Transaction Sequence

Caller: [CREATOR], calldata: , decoded_data: , value: 0x0
Caller: [ATTACKER], function: allowance(address,address), txdata: 0xdd62ed3e00000000000000000000000000000100000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000, decoded_data: ('0x0000010000000000000001000000000000000000', '0x0000000000000000000000000000000000000000'), value: 0x0


## Integer Arithmetic Bugs
- SWC ID: 101
- Severity: Low
- Contract: PrismSwapPair
- Function name: `allowance(address,address)`
- PC address: 733
- Estimated Gas Usage: 1875 - 2538

### Description

The arithmetic operator can overflow.
It is possible to cause an integer overflow or underflow in the arithmetic operation.  This issue is reported for internal compiler generated code.

### Initial State:

Account: [CREATOR], balance: 0x0, nonce:0, storage:{}
Account: [ATTACKER], balance: 0x0, nonce:0, storage:{}

### Transaction Sequence

Caller: [CREATOR], calldata: , decoded_data: , value: 0x0
Caller: [ATTACKER], function: allowance(address,address), txdata: 0xdd62ed3e00000000000000000000000000000100000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000, decoded_data: ('0x0000010000000000000001000000000000000000', '0x0000000000000000000000000000000000000000'), value: 0x0


## Integer Arithmetic Bugs
- SWC ID: 101
- Severity: Low
- Contract: PrismSwapPair
- Function name: `FEE_DENOMINATOR()`
- PC address: 815
- Estimated Gas Usage: 1875 - 2538

### Description

The arithmetic operator can overflow.
It is possible to cause an integer overflow or underflow in the arithmetic operation.  This issue is reported for internal compiler generated code.

### Initial State:

Account: [CREATOR], balance: 0x0, nonce:0, storage:{}
Account: [ATTACKER], balance: 0x0, nonce:0, storage:{}

### Transaction Sequence

Caller: [CREATOR], calldata: , decoded_data: , value: 0x0
Caller: [ATTACKER], function: allowance(address,address), txdata: 0xdd62ed3e00000000000000000000000000000100000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000, decoded_data: ('0x0000010000000000000001000000000000000000', '0x0000000000000000000000000000000000000000'), value: 0x0


## Dependence on predictable environment variable
- SWC ID: 116
- Severity: Low
- Contract: PrismSwapPair
- Function name: `permit(address,address,uint256,uint256,uint8,bytes32,bytes32)`
- PC address: 895
- Estimated Gas Usage: 910 - 1005

### Description

A control flow decision is made based on The block.timestamp environment variable.
The block.timestamp environment variable is used to determine a control flow decision. Note that the values of variables like coinbase, gaslimit, block number and timestamp are predictable and can be manipulated by a malicious miner. Also keep in mind that attackers know hashes of earlier blocks. Don't use any of those environment variables as sources of randomness and be aware that use of these variables introduces a certain level of trust into miners.
In file: lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol:51

### Code

```
if (block.timestamp > deadline) {
            revert ERC2612ExpiredSignature(deadline);
        }
```

### Initial State:

Account: [CREATOR], balance: 0x0, nonce:0, storage:{}
Account: [ATTACKER], balance: 0x0, nonce:0, storage:{}

### Transaction Sequence

Caller: [CREATOR], calldata: , decoded_data: , value: 0x0
Caller: [CREATOR], function: permit(address,address,uint256,uint256,uint8,bytes32,bytes32), txdata: 0xd505accf0000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000, decoded_data: ('0x0000000000000000000000000000000000000001', '0x0000000000000000000000000000000000000000', 0, 0, 0, '0000000000000000000000000000000000000000000000000000000000000000', '0000000000000000000000000000000000000000000000000000000000000000'), value: 0x0


## Integer Arithmetic Bugs
- SWC ID: 101
- Severity: Low
- Contract: PrismSwapPair
- Function name: `token1()`
- PC address: 1179
- Estimated Gas Usage: 1875 - 2538

### Description

The arithmetic operator can overflow.
It is possible to cause an integer overflow or underflow in the arithmetic operation.  This issue is reported for internal compiler generated code.

### Initial State:

Account: [CREATOR], balance: 0x0, nonce:0, storage:{}
Account: [ATTACKER], balance: 0x0, nonce:0, storage:{}

### Transaction Sequence

Caller: [CREATOR], calldata: , decoded_data: , value: 0x0
Caller: [ATTACKER], function: allowance(address,address), txdata: 0xdd62ed3e00000000000000000000000000000100000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000, decoded_data: ('0x0000010000000000000001000000000000000000', '0x0000000000000000000000000000000000000000'), value: 0x0


## Integer Arithmetic Bugs
- SWC ID: 101
- Severity: Low
- Contract: PrismSwapPair
- Function name: `factory()`
- PC address: 1220
- Estimated Gas Usage: 1875 - 2538

### Description

The arithmetic operator can overflow.
It is possible to cause an integer overflow or underflow in the arithmetic operation.  This issue is reported for internal compiler generated code.

### Initial State:

Account: [CREATOR], balance: 0x0, nonce:0, storage:{}
Account: [ATTACKER], balance: 0x0, nonce:0, storage:{}

### Transaction Sequence

Caller: [CREATOR], calldata: , decoded_data: , value: 0x0
Caller: [ATTACKER], function: allowance(address,address), txdata: 0xdd62ed3e00000000000000000000000000000100000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000, decoded_data: ('0x0000010000000000000001000000000000000000', '0x0000000000000000000000000000000000000000'), value: 0x0


## Integer Arithmetic Bugs
- SWC ID: 101
- Severity: Low
- Contract: PrismSwapPair
- Function name: `MINIMUM_LIQUIDITY()`
- PC address: 1624
- Estimated Gas Usage: 1875 - 2538

### Description

The arithmetic operator can overflow.
It is possible to cause an integer overflow or underflow in the arithmetic operation.  This issue is reported for internal compiler generated code.

### Initial State:

Account: [CREATOR], balance: 0x0, nonce:0, storage:{}
Account: [ATTACKER], balance: 0x0, nonce:0, storage:{}

### Transaction Sequence

Caller: [CREATOR], calldata: , decoded_data: , value: 0x0
Caller: [ATTACKER], function: allowance(address,address), txdata: 0xdd62ed3e00000000000000000000000000000100000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000, decoded_data: ('0x0000010000000000000001000000000000000000', '0x0000000000000000000000000000000000000000'), value: 0x0


## Integer Arithmetic Bugs
- SWC ID: 101
- Severity: Low
- Contract: PrismSwapPair
- Function name: `transfer(address,uint256)`
- PC address: 1654
- Estimated Gas Usage: 14156 - 55453

### Description

The arithmetic operator can overflow.
It is possible to cause an integer overflow or underflow in the arithmetic operation.  This issue is reported for internal compiler generated code.

### Initial State:

Account: [CREATOR], balance: 0x0, nonce:0, storage:{}
Account: [ATTACKER], balance: 0x0, nonce:0, storage:{}

### Transaction Sequence

Caller: [CREATOR], calldata: , decoded_data: , value: 0x0
Caller: [CREATOR], function: transfer(address,uint256), txdata: 0xa9059cbb00000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000, decoded_data: ('0x0000000000000000000000000000000000000001', 0), value: 0x0


## Integer Arithmetic Bugs
- SWC ID: 101
- Severity: Low
- Contract: PrismSwapPair
- Function name: `symbol()`
- PC address: 1703
- Estimated Gas Usage: 20129 - 82186

### Description

The arithmetic operator can overflow.
It is possible to cause an integer overflow or underflow in the arithmetic operation.  This issue is reported for internal compiler generated code.

### Initial State:

Account: [CREATOR], balance: 0x0, nonce:0, storage:{}
Account: [ATTACKER], balance: 0x0, nonce:0, storage:{}

### Transaction Sequence

Caller: [CREATOR], calldata: , decoded_data: , value: 0x0
Caller: [ATTACKER], function: transferFrom(address,address,uint256), txdata: 0x23b872dd000000000000000000000000010001000101010100000101000101000101800000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000, decoded_data: ('0x0100010001010101000001010001010001018000', '0x0000000000000000000000000000000000000001', 0), value: 0x0


## Integer Arithmetic Bugs
- SWC ID: 101
- Severity: Low
- Contract: PrismSwapPair
- Function name: `eip712Domain()`
- PC address: 2826
- Estimated Gas Usage: 20129 - 82186

### Description

The arithmetic operator can overflow.
It is possible to cause an integer overflow or underflow in the arithmetic operation.  This issue is reported for internal compiler generated code.

### Initial State:

Account: [CREATOR], balance: 0x0, nonce:0, storage:{}
Account: [ATTACKER], balance: 0x0, nonce:0, storage:{}

### Transaction Sequence

Caller: [CREATOR], calldata: , decoded_data: , value: 0x0
Caller: [ATTACKER], function: transferFrom(address,address,uint256), txdata: 0x23b872dd000000000000000000000000010001000101010100000101000101000101800000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000, decoded_data: ('0x0100010001010101000001010001010001018000', '0x0000000000000000000000000000000000000001', 0), value: 0x0


## Integer Arithmetic Bugs
- SWC ID: 101
- Severity: Low
- Contract: PrismSwapPair
- Function name: `nonces(address)`
- PC address: 3079
- Estimated Gas Usage: 1481 - 1954

### Description

The arithmetic operator can overflow.
It is possible to cause an integer overflow or underflow in the arithmetic operation.  This issue is reported for internal compiler generated code.

### Initial State:

Account: [CREATOR], balance: 0x0, nonce:0, storage:{}
Account: [ATTACKER], balance: 0x0, nonce:0, storage:{}

### Transaction Sequence

Caller: [CREATOR], calldata: , decoded_data: , value: 0x0
Caller: [CREATOR], function: nonces(address), txdata: 0x7ecebe000000000000000000000000000000000000000000000000000000000000000000, decoded_data: ('0x0000000000000000000000000000000000000000',), value: 0x0


## Integer Arithmetic Bugs
- SWC ID: 101
- Severity: Low
- Contract: PrismSwapPair
- Function name: `kLast()`
- PC address: 3135
- Estimated Gas Usage: 20129 - 82186

### Description

The arithmetic operator can overflow.
It is possible to cause an integer overflow or underflow in the arithmetic operation.  This issue is reported for internal compiler generated code.

### Initial State:

Account: [CREATOR], balance: 0x0, nonce:0, storage:{}
Account: [ATTACKER], balance: 0x0, nonce:0, storage:{}

### Transaction Sequence

Caller: [CREATOR], calldata: , decoded_data: , value: 0x0
Caller: [ATTACKER], function: transferFrom(address,address,uint256), txdata: 0x23b872dd000000000000000000000000010001000101010100000101000101000101800000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000, decoded_data: ('0x0100010001010101000001010001010001018000', '0x0000000000000000000000000000000000000001', 0), value: 0x0


## Integer Arithmetic Bugs
- SWC ID: 101
- Severity: Low
- Contract: PrismSwapPair
- Function name: `balanceOf(address)`
- PC address: 3166
- Estimated Gas Usage: 1437 - 1910

### Description

The arithmetic operator can overflow.
It is possible to cause an integer overflow or underflow in the arithmetic operation.  This issue is reported for internal compiler generated code.

### Initial State:

Account: [CREATOR], balance: 0x0, nonce:0, storage:{}
Account: [ATTACKER], balance: 0x0, nonce:0, storage:{}

### Transaction Sequence

Caller: [CREATOR], calldata: , decoded_data: , value: 0x0
Caller: [SOMEGUY], function: balanceOf(address), txdata: 0x70a082310000000000000000000000000000000000000000000000000000000000000000, decoded_data: ('0x0000000000000000000000000000000000000000',), value: 0x0


## Integer Arithmetic Bugs
- SWC ID: 101
- Severity: Low
- Contract: PrismSwapPair
- Function name: `price1CumulativeLast()`
- PC address: 3834
- Estimated Gas Usage: 20129 - 82186

### Description

The arithmetic operator can overflow.
It is possible to cause an integer overflow or underflow in the arithmetic operation.  This issue is reported for internal compiler generated code.

### Initial State:

Account: [CREATOR], balance: 0x0, nonce:0, storage:{}
Account: [ATTACKER], balance: 0x0, nonce:0, storage:{}

### Transaction Sequence

Caller: [CREATOR], calldata: , decoded_data: , value: 0x0
Caller: [ATTACKER], function: transferFrom(address,address,uint256), txdata: 0x23b872dd000000000000000000000000010001000101010100000101000101000101800000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000, decoded_data: ('0x0100010001010101000001010001010001018000', '0x0000000000000000000000000000000000000001', 0), value: 0x0


## Integer Arithmetic Bugs
- SWC ID: 101
- Severity: Low
- Contract: PrismSwapPair
- Function name: `price0CumulativeLast()`
- PC address: 3864
- Estimated Gas Usage: 20129 - 82186

### Description

The arithmetic operator can overflow.
It is possible to cause an integer overflow or underflow in the arithmetic operation.  This issue is reported for internal compiler generated code.

### Initial State:

Account: [CREATOR], balance: 0x0, nonce:0, storage:{}
Account: [ATTACKER], balance: 0x0, nonce:0, storage:{}

### Transaction Sequence

Caller: [CREATOR], calldata: , decoded_data: , value: 0x0
Caller: [ATTACKER], function: transferFrom(address,address,uint256), txdata: 0x23b872dd000000000000000000000000010001000101010100000101000101000101800000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000, decoded_data: ('0x0100010001010101000001010001010001018000', '0x0000000000000000000000000000000000000001', 0), value: 0x0


## Integer Arithmetic Bugs
- SWC ID: 101
- Severity: Low
- Contract: PrismSwapPair
- Function name: `DEAD_ADDRESS()`
- PC address: 3894
- Estimated Gas Usage: 20129 - 82186

### Description

The arithmetic operator can overflow.
It is possible to cause an integer overflow or underflow in the arithmetic operation.  This issue is reported for internal compiler generated code.

### Initial State:

Account: [CREATOR], balance: 0x0, nonce:0, storage:{}
Account: [ATTACKER], balance: 0x0, nonce:0, storage:{}

### Transaction Sequence

Caller: [CREATOR], calldata: , decoded_data: , value: 0x0
Caller: [ATTACKER], function: transferFrom(address,address,uint256), txdata: 0x23b872dd000000000000000000000000010001000101010100000101000101000101800000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000, decoded_data: ('0x0100010001010101000001010001010001018000', '0x0000000000000000000000000000000000000001', 0), value: 0x0


## Integer Arithmetic Bugs
- SWC ID: 101
- Severity: Low
- Contract: PrismSwapPair
- Function name: `initialize(address,address)`
- PC address: 3924
- Estimated Gas Usage: 12292 - 52387

### Description

The arithmetic operator can overflow.
It is possible to cause an integer overflow or underflow in the arithmetic operation.  This issue is reported for internal compiler generated code.

### Initial State:

Account: [CREATOR], balance: 0x0, nonce:0, storage:{}
Account: [ATTACKER], balance: 0x0, nonce:0, storage:{}

### Transaction Sequence

Caller: [CREATOR], calldata: , decoded_data: , value: 0x0
Caller: [CREATOR], function: initialize(address,address), txdata: 0x485cc95500000000000000000000000000000000000000000000000000000000000020000000000000000000000000000801010201010101010108010101010101010201, decoded_data: ('0x0000000000000000000000000000000000002000', '0x0801010201010101010108010101010101010201'), value: 0x0


## Integer Arithmetic Bugs
- SWC ID: 101
- Severity: High
- Contract: PrismSwapPair
- Function name: `initialize(address,address)`
- PC address: 3990
- Estimated Gas Usage: 20129 - 82186

### Description

The arithmetic operator can underflow.
It is possible to cause an integer overflow or underflow in the arithmetic operation.
In file: src/core/PrismSwapPair.sol:77

### Code

```
msg.sender != factory
```

### Initial State:

Account: [CREATOR], balance: 0x0, nonce:0, storage:{}
Account: [ATTACKER], balance: 0x0, nonce:0, storage:{}

### Transaction Sequence

Caller: [CREATOR], calldata: , decoded_data: , value: 0x0
Caller: [SOMEGUY], function: transferFrom(address,address,uint256), txdata: 0x23b872dd000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000, decoded_data: ('0x0000000000000000000000000000000110000000', '0x0000000000000000000000000000000000000001', 0), value: 0x0


## Integer Arithmetic Bugs
- SWC ID: 101
- Severity: Low
- Contract: PrismSwapPair
- Function name: `BASE_FEE()`
- PC address: 4119
- Estimated Gas Usage: 20129 - 82186

### Description

The arithmetic operator can overflow.
It is possible to cause an integer overflow or underflow in the arithmetic operation.  This issue is reported for internal compiler generated code.

### Initial State:

Account: [CREATOR], balance: 0x0, nonce:0, storage:{}
Account: [ATTACKER], balance: 0x0, nonce:0, storage:{}

### Transaction Sequence

Caller: [CREATOR], calldata: , decoded_data: , value: 0x0
Caller: [ATTACKER], function: transferFrom(address,address,uint256), txdata: 0x23b872dd000000000000000000000000010001000101010100000101000101000101800000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000, decoded_data: ('0x0100010001010101000001010001010001018000', '0x0000000000000000000000000000000000000001', 0), value: 0x0


## Integer Arithmetic Bugs
- SWC ID: 101
- Severity: Low
- Contract: PrismSwapPair
- Function name: `DOMAIN_SEPARATOR()`
- PC address: 4147
- Estimated Gas Usage: 20129 - 82186

### Description

The arithmetic operator can overflow.
It is possible to cause an integer overflow or underflow in the arithmetic operation.  This issue is reported for internal compiler generated code.

### Initial State:

Account: [CREATOR], balance: 0x0, nonce:0, storage:{}
Account: [ATTACKER], balance: 0x0, nonce:0, storage:{}

### Transaction Sequence

Caller: [CREATOR], calldata: , decoded_data: , value: 0x0
Caller: [ATTACKER], function: transferFrom(address,address,uint256), txdata: 0x23b872dd000000000000000000000000010001000101010100000101000101000101800000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000, decoded_data: ('0x0100010001010101000001010001010001018000', '0x0000000000000000000000000000000000000001', 0), value: 0x0


## Integer Arithmetic Bugs
- SWC ID: 101
- Severity: Low
- Contract: PrismSwapPair
- Function name: `decimals()`
- PC address: 4182
- Estimated Gas Usage: 20129 - 82186

### Description

The arithmetic operator can overflow.
It is possible to cause an integer overflow or underflow in the arithmetic operation.  This issue is reported for internal compiler generated code.

### Initial State:

Account: [CREATOR], balance: 0x0, nonce:0, storage:{}
Account: [ATTACKER], balance: 0x0, nonce:0, storage:{}

### Transaction Sequence

Caller: [CREATOR], calldata: , decoded_data: , value: 0x0
Caller: [ATTACKER], function: transferFrom(address,address,uint256), txdata: 0x23b872dd000000000000000000000000010001000101010100000101000101000101800000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000, decoded_data: ('0x0100010001010101000001010001010001018000', '0x0000000000000000000000000000000000000001', 0), value: 0x0


## Integer Arithmetic Bugs
- SWC ID: 101
- Severity: Low
- Contract: PrismSwapPair
- Function name: `transferFrom(address,address,uint256)`
- PC address: 4211
- Estimated Gas Usage: 20129 - 82186

### Description

The arithmetic operator can overflow.
It is possible to cause an integer overflow or underflow in the arithmetic operation.  This issue is reported for internal compiler generated code.

### Initial State:

Account: [CREATOR], balance: 0x0, nonce:0, storage:{}
Account: [ATTACKER], balance: 0x0, nonce:0, storage:{}

### Transaction Sequence

Caller: [CREATOR], calldata: , decoded_data: , value: 0x0
Caller: [SOMEGUY], function: transferFrom(address,address,uint256), txdata: 0x23b872dd000000000000000000000000000101010000010100010001010100010101000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000, decoded_data: ('0x0001010100000101000100010101000101010000', '0x0000000000000000000000000000000000000001', 0), value: 0x0


## Integer Arithmetic Bugs
- SWC ID: 101
- Severity: Low
- Contract: PrismSwapPair
- Function name: `totalSupply()`
- PC address: 4436
- Estimated Gas Usage: 20129 - 82186

### Description

The arithmetic operator can overflow.
It is possible to cause an integer overflow or underflow in the arithmetic operation.  This issue is reported for internal compiler generated code.

### Initial State:

Account: [CREATOR], balance: 0x0, nonce:0, storage:{}
Account: [ATTACKER], balance: 0x0, nonce:0, storage:{}

### Transaction Sequence

Caller: [CREATOR], calldata: , decoded_data: , value: 0x0
Caller: [ATTACKER], function: transferFrom(address,address,uint256), txdata: 0x23b872dd000000000000000000000000010001000101010100000101000101000101800000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000, decoded_data: ('0x0100010001010101000001010001010001018000', '0x0000000000000000000000000000000000000001', 0), value: 0x0


## Integer Arithmetic Bugs
- SWC ID: 101
- Severity: Low
- Contract: PrismSwapPair
- Function name: `token0()`
- PC address: 4466
- Estimated Gas Usage: 20129 - 82186

### Description

The arithmetic operator can overflow.
It is possible to cause an integer overflow or underflow in the arithmetic operation.  This issue is reported for internal compiler generated code.

### Initial State:

Account: [CREATOR], balance: 0x0, nonce:0, storage:{}
Account: [ATTACKER], balance: 0x0, nonce:0, storage:{}

### Transaction Sequence

Caller: [CREATOR], calldata: , decoded_data: , value: 0x0
Caller: [ATTACKER], function: transferFrom(address,address,uint256), txdata: 0x23b872dd000000000000000000000000010001000101010100000101000101000101800000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000, decoded_data: ('0x0100010001010101000001010001010001018000', '0x0000000000000000000000000000000000000001', 0), value: 0x0


## Integer Arithmetic Bugs
- SWC ID: 101
- Severity: Low
- Contract: PrismSwapPair
- Function name: `approve(address,uint256)`
- PC address: 4508
- Estimated Gas Usage: 7056 - 28163

### Description

The arithmetic operator can overflow.
It is possible to cause an integer overflow or underflow in the arithmetic operation.  This issue is reported for internal compiler generated code.

### Initial State:

Account: [CREATOR], balance: 0x0, nonce:0, storage:{}
Account: [ATTACKER], balance: 0x0, nonce:0, storage:{}

### Transaction Sequence

Caller: [CREATOR], calldata: , decoded_data: , value: 0x0
Caller: [CREATOR], function: approve(address,uint256), txdata: 0x095ea7b300000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000, decoded_data: ('0x0000000000000000000000000100000000000000', 0), value: 0x0


## Integer Arithmetic Bugs
- SWC ID: 101
- Severity: Low
- Contract: PrismSwapPair
- Function name: `getReserves()`
- PC address: 4546
- Estimated Gas Usage: 20129 - 82186

### Description

The arithmetic operator can overflow.
It is possible to cause an integer overflow or underflow in the arithmetic operation.  This issue is reported for internal compiler generated code.

### Initial State:

Account: [CREATOR], balance: 0x0, nonce:0, storage:{}
Account: [ATTACKER], balance: 0x0, nonce:0, storage:{}

### Transaction Sequence

Caller: [CREATOR], calldata: , decoded_data: , value: 0x0
Caller: [ATTACKER], function: transferFrom(address,address,uint256), txdata: 0x23b872dd000000000000000000000000010001000101010100000101000101000101800000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000, decoded_data: ('0x0100010001010101000001010001010001018000', '0x0000000000000000000000000000000000000001', 0), value: 0x0


## Integer Arithmetic Bugs
- SWC ID: 101
- Severity: Low
- Contract: PrismSwapPair
- Function name: `name()`
- PC address: 4611
- Estimated Gas Usage: 20129 - 82186

### Description

The arithmetic operator can overflow.
It is possible to cause an integer overflow or underflow in the arithmetic operation.  This issue is reported for internal compiler generated code.

### Initial State:

Account: [CREATOR], balance: 0x0, nonce:0, storage:{}
Account: [ATTACKER], balance: 0x0, nonce:0, storage:{}

### Transaction Sequence

Caller: [CREATOR], calldata: , decoded_data: , value: 0x0
Caller: [ATTACKER], function: transferFrom(address,address,uint256), txdata: 0x23b872dd000000000000000000000000010001000101010100000101000101000101800000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000, decoded_data: ('0x0100010001010101000001010001010001018000', '0x0000000000000000000000000000000000000001', 0), value: 0x0


