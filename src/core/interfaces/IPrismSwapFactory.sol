// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IPrismSwapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256 totalPairs);
    event FeeToUpdated(address indexed oldFeeTo, address indexed newFeeTo);

    function feeTo() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint256) external view returns (address pair);
    function allPairsLength() external view returns (uint256);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
}
