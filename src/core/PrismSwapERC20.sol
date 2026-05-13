// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/// @title PrismSwap LP Token
/// @notice ERC20 token representing liquidity provider shares in a PrismSwap pair.
/// Inherits standard ERC20 + EIP-2612 permit from OpenZeppelin.
contract PrismSwapERC20 is ERC20, ERC20Permit {
    constructor() ERC20("PrismSwap V2", "PRISM-V2") ERC20Permit("PrismSwap V2") {}
}
