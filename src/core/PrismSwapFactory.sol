// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {PrismSwapPair} from "./PrismSwapPair.sol";

contract PrismSwapFactory is Ownable {
    address public feeTo;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    error IdenticalAddresses();
    error ZeroAddress();
    error PairExists();

    event PairCreated(address indexed token0, address indexed token1, address pair, uint256 totalPairs);
    event FeeToUpdated(address indexed oldFeeTo, address indexed newFeeTo);

    constructor(address initialOwner) Ownable(initialOwner) {}

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        if (tokenA == tokenB) revert IdenticalAddresses();

        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

        if (token0 == address(0)) revert ZeroAddress();
        if (getPair[token0][token1] != address(0)) revert PairExists();

        bytes32 salt;
        assembly {
            mstore(0x00, token0)
            mstore(0x20, token1)
            salt := keccak256(0x00, 0x40)
        }
        PrismSwapPair p = new PrismSwapPair{salt: salt}();
        pair = address(p);

        p.initialize(token0, token1);

        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
        allPairs.push(pair);

        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external onlyOwner {
        emit FeeToUpdated(feeTo, _feeTo);
        feeTo = _feeTo;
    }
}
