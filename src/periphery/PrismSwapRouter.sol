// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IPrismSwapFactory} from "../core/interfaces/IPrismSwapFactory.sol";
import {IPrismSwapPair} from "../core/interfaces/IPrismSwapPair.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {PrismSwapLibrary} from "./libraries/PrismSwapLibrary.sol";

contract PrismSwapRouter {
    using SafeERC20 for IERC20;

    // --- Errors ---
    error Expired();
    error InsufficientAAmount();
    error InsufficientBAmount();
    error InsufficientOutputAmount();
    error ExcessiveInputAmount();
    error InvalidPath();

    // --- State ---
    address public immutable factory;

    // --- Constructor ---
    constructor(address _factory) {
        factory = _factory;
    }

    // =========================================================
    // ensure — deadline guard on every state-changing function
    // =========================================================

    modifier ensure(uint256 deadline) {
        if (deadline < block.timestamp) revert Expired();
        _;
    }

    // =========================================================
    // _addLiquidity — internal: compute how much of each token to deposit
    // =========================================================

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal returns (uint256 amountA, uint256 amountB) {
        // Create the pair if it doesn't exist yet
        if (IPrismSwapFactory(factory).getPair(tokenA, tokenB) == address(0)) {
            IPrismSwapFactory(factory).createPair(tokenA, tokenB);
        }

        (uint256 reserveA, uint256 reserveB) = PrismSwapLibrary.getReserves(factory, tokenA, tokenB);

        if (reserveA == 0 && reserveB == 0) {
            // Empty pool: accept whatever the user wants to deposit
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            // Existing pool: match the current ratio
            uint256 amountBOptimal = PrismSwapLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                if (amountBOptimal < amountBMin) revert InsufficientBAmount();
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = PrismSwapLibrary.quote(amountBDesired, reserveB, reserveA);
                // amountAOptimal <= amountADesired always holds at this branch
                if (amountAOptimal < amountAMin) revert InsufficientAAmount();
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    // =========================================================
    // addLiquidity — public: deposit tokens, receive LP tokens
    // =========================================================

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);

        address pair = PrismSwapLibrary.pairFor(factory, tokenA, tokenB);

        IERC20(tokenA).safeTransferFrom(msg.sender, pair, amountA);
        IERC20(tokenB).safeTransferFrom(msg.sender, pair, amountB);

        liquidity = IPrismSwapPair(pair).mint(to);
    }

    // =========================================================
    // removeLiquidity — public: burn LP tokens, receive tokens
    // =========================================================

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256 amountA, uint256 amountB) {
        address pair = PrismSwapLibrary.pairFor(factory, tokenA, tokenB);

        // Transfer LP tokens from user to pair, then call burn
        IERC20(pair).safeTransferFrom(msg.sender, pair, liquidity);
        (uint256 amount0, uint256 amount1) = IPrismSwapPair(pair).burn(to);

        // Re-align amounts to the caller's token order (pair always returns amount0 for token0)
        (address token0,) = PrismSwapLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);

        if (amountA < amountAMin) revert InsufficientAAmount();
        if (amountB < amountBMin) revert InsufficientBAmount();
    }

    // =========================================================
    // _swap — internal: execute a multi-hop swap along a path
    // =========================================================

    function _swap(uint256[] memory amounts, address[] memory path, address _to) internal {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = PrismSwapLibrary.sortTokens(input, output);

            uint256 amountOut = amounts[i + 1];

            // Pair always uses token0/token1 order — we must map our amountOut to the right slot
            (uint256 amount0Out, uint256 amount1Out) =
                input == token0 ? (uint256(0), amountOut) : (amountOut, uint256(0));

            // Send output to the next pair in the path, or to the final recipient
            address to = i < path.length - 2
                ? PrismSwapLibrary.pairFor(factory, output, path[i + 2])
                : _to;

            IPrismSwapPair(PrismSwapLibrary.pairFor(factory, input, output))
                .swap(amount0Out, amount1Out, to, "");
        }
    }

    // =========================================================
    // swapExactTokensForTokens — send exact A, receive ≥ minAmountOut B
    // =========================================================

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256[] memory amounts) {
        if (path.length < 2) revert InvalidPath();

        amounts = _splitIfLargeOrder(amountIn, path);

        if (amounts[amounts.length - 1] < amountOutMin) revert InsufficientOutputAmount();

        IERC20(path[0]).safeTransferFrom(
            msg.sender,
            PrismSwapLibrary.pairFor(factory, path[0], path[1]),
            amounts[0]
        );

        _swap(amounts, path, to);
    }

    // =========================================================
    // swapTokensForExactTokens — receive exact B, send ≤ amountInMax A
    // =========================================================

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256[] memory amounts) {
        if (path.length < 2) revert InvalidPath();

        amounts = PrismSwapLibrary.getAmountsIn(factory, amountOut, path);

        if (amounts[0] > amountInMax) revert ExcessiveInputAmount();

        IERC20(path[0]).safeTransferFrom(
            msg.sender,
            PrismSwapLibrary.pairFor(factory, path[0], path[1]),
            amounts[0]
        );

        _swap(amounts, path, to);
    }

    // =========================================================
    // _splitIfLargeOrder — PrismSwap custom feature
    // If a single swap would cause >25% price impact, split into two halves
    // =========================================================

    function _splitIfLargeOrder(uint256 amountIn, address[] calldata path)
        internal
        view
        returns (uint256[] memory amounts)
    {
        (uint256 reserveIn,) = PrismSwapLibrary.getReserves(factory, path[0], path[1]);

        // Price impact approximation: amountIn / (reserveIn + amountIn) * 100
        uint256 impact = (amountIn * 100) / (reserveIn + amountIn);

        if (impact > 25) {
            // Split into two equal halves and sum outputs
            uint256 half = amountIn / 2;
            uint256 remainder = amountIn - half;

            uint256[] memory a1 = PrismSwapLibrary.getAmountsOut(factory, half, path);
            uint256[] memory a2 = PrismSwapLibrary.getAmountsOut(factory, remainder, path);

            amounts = new uint256[](path.length);
            amounts[0] = amountIn;
            for (uint256 i = 1; i < path.length; i++) {
                amounts[i] = a1[i] + a2[i];
            }
        } else {
            amounts = PrismSwapLibrary.getAmountsOut(factory, amountIn, path);
        }
    }

    // =========================================================
    // View wrappers — expose Library functions publicly
    // =========================================================

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB)
        external
        pure
        returns (uint256 amountB)
    {
        return PrismSwapLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        external
        pure
        returns (uint256 amountOut)
    {
        return PrismSwapLibrary.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut)
        external
        pure
        returns (uint256 amountIn)
    {
        return PrismSwapLibrary.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts)
    {
        return PrismSwapLibrary.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts)
    {
        return PrismSwapLibrary.getAmountsIn(factory, amountOut, path);
    }
}
