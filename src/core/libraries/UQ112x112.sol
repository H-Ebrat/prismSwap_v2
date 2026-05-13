// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Fixed-point math library for TWAP price accumulation.
// Represents numbers as UQ112x112 format: 112 bits integer + 112 bits fraction.
library UQ112x112 {
    uint224 constant Q112 = 2 ** 112;

    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112;
    }

    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}
