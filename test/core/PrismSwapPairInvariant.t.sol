// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {PrismSwapPair} from "../../src/core/PrismSwapPair.sol";
import {PrismSwapFactory} from "../../src/core/PrismSwapFactory.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

// =========================================================
// Handler — Foundry calls these functions randomly
// =========================================================

contract Handler is Test {
    PrismSwapPair public pair;
    MockERC20 public token0;
    MockERC20 public token1;

    // Ghost variable: K snapshotted at the START of each swap
    // Foundry checks invariants AFTER the call, so we capture before
    uint256 public ghostKSnapshot;

    address internal constant LP_RECEIVER = address(0xBEEF);

    constructor(PrismSwapPair _pair, MockERC20 _token0, MockERC20 _token1) {
        pair = _pair;
        token0 = _token0;
        token1 = _token1;
    }

    function addLiquidity(uint256 amount0, uint256 amount1) public {
        amount0 = bound(amount0, 1001, 100_000 ether);
        amount1 = bound(amount1, 1001, 100_000 ether);

        token0.mint(address(pair), amount0);
        token1.mint(address(pair), amount1);
        pair.mint(LP_RECEIVER);
    }

    function removeLiquidity(uint256 lpAmount) public {
        uint256 balance = pair.balanceOf(LP_RECEIVER);
        if (balance == 0) return;

        lpAmount = bound(lpAmount, 1, balance);

        vm.prank(LP_RECEIVER);
        pair.transfer(address(pair), lpAmount);
        pair.burn(LP_RECEIVER);

        // Burns legitimately reduce K — reset snapshot so invariant doesn't false-positive
        (uint112 r0, uint112 r1,) = pair.getReserves();
        ghostKSnapshot = uint256(r0) * uint256(r1);
    }

    function swapToken0In(uint256 amountIn) public {
        (uint112 r0, uint112 r1,) = pair.getReserves();
        if (r0 == 0 || r1 == 0) return;

        amountIn = bound(amountIn, 1001, uint256(r0) / 20); // max 5% of reserve

        // Snapshot K before the swap — invariant is checked after this function returns
        ghostKSnapshot = uint256(r0) * uint256(r1);

        uint256 D = 10_000;
        uint256 fee = 30 + (30 * amountIn) / (uint256(r0) + amountIn);
        uint256 amountOut = uint256(r1) * amountIn * (D - fee)
            / (uint256(r0) * D + amountIn * (D - fee));
        if (amountOut == 0) return;

        token0.mint(address(pair), amountIn);
        pair.swap(0, amountOut, LP_RECEIVER, "");
    }

    function swapToken1In(uint256 amountIn) public {
        (uint112 r0, uint112 r1,) = pair.getReserves();
        if (r0 == 0 || r1 == 0) return;

        amountIn = bound(amountIn, 1001, uint256(r1) / 20);

        // Snapshot K before the swap
        ghostKSnapshot = uint256(r0) * uint256(r1);

        uint256 D = 10_000;
        uint256 fee = 30 + (30 * amountIn) / (uint256(r1) + amountIn);
        uint256 amountOut = uint256(r0) * amountIn * (D - fee)
            / (uint256(r1) * D + amountIn * (D - fee));
        if (amountOut == 0) return;

        token1.mint(address(pair), amountIn);
        pair.swap(amountOut, 0, LP_RECEIVER, "");
    }
}

// =========================================================
// Invariant Test
// =========================================================

contract PrismSwapPairInvariantTest is Test {
    MockERC20 token0;
    MockERC20 token1;
    PrismSwapFactory factory;
    PrismSwapPair pair;
    Handler handler;

    function setUp() public {
        factory = new PrismSwapFactory(address(this));

        MockERC20 tokenA = new MockERC20("Token A", "TKA");
        MockERC20 tokenB = new MockERC20("Token B", "TKB");

        address pairAddr = factory.createPair(address(tokenA), address(tokenB));
        pair = PrismSwapPair(pairAddr);

        token0 = MockERC20(pair.token0());
        token1 = MockERC20(pair.token1());

        handler = new Handler(pair, token0, token1);

        // Seed initial liquidity so invariants have something to check from the start
        handler.addLiquidity(1000 ether, 1000 ether);

        // calling functions on the handler
        targetContract(address(handler));
    }

    function invariant_kNeverDecreases() public view {
        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 currentK = uint256(r0) * uint256(r1);
        assertGe(currentK, handler.ghostKSnapshot());
    }

    function invariant_reservesNeverExceedBalances() public view {
        (uint112 r0, uint112 r1,) = pair.getReserves();
        assertLe(uint256(r0), token0.balanceOf(address(pair)));
        assertLe(uint256(r1), token1.balanceOf(address(pair)));
    }

    function invariant_minimumLiquidityAlwaysLocked() public view {
        assertGe(pair.balanceOf(pair.DEAD_ADDRESS()), pair.MINIMUM_LIQUIDITY());
    }
}
