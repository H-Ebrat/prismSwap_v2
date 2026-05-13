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

contract PrismSwapPairTest is Test {
    MockERC20 token0;
    MockERC20 token1;

    PrismSwapFactory factory;
    PrismSwapPair pair;

    address alice = makeAddr("alice");
    address bob   = makeAddr("bob");

    function setUp() public {
        factory = new PrismSwapFactory(address(this));

        MockERC20 tokenA = new MockERC20("Token A", "TKA");
        MockERC20 tokenB = new MockERC20("Token B", "TKB");

        address pairAddr = factory.createPair(address(tokenA), address(tokenB));
        pair = PrismSwapPair(pairAddr);

        // Factory sorts tokens by address — read back which is which
        token0 = MockERC20(pair.token0());
        token1 = MockERC20(pair.token1());
    }

    // =========================================================
    // mint
    // =========================================================

    function test_mint_firstDeposit() public {
        token0.mint(address(pair), 1 ether);
        token1.mint(address(pair), 4 ether);
        uint256 liquidity = pair.mint(alice);

        // sqrt(1e18 * 4e18) - MINIMUM_LIQUIDITY = 2e18 - 1000
        assertEq(liquidity, 2 ether - 1000);
        assertEq(pair.balanceOf(alice), 2 ether - 1000);

        // MINIMUM_LIQUIDITY permanently locked in dead address
        assertEq(pair.balanceOf(pair.DEAD_ADDRESS()), 1000);

        // Reserves match deposited amounts
        (uint112 r0, uint112 r1,) = pair.getReserves();
        assertEq(r0, 1 ether);
        assertEq(r1, 4 ether);
    }

    function test_mint_subsequentDeposit() public {
        // First deposit — alice
        token0.mint(address(pair), 10 ether);
        token1.mint(address(pair), 10 ether);
        pair.mint(alice);

        // Second deposit — bob at same ratio, half the amounts
        token0.mint(address(pair), 5 ether);
        token1.mint(address(pair), 5 ether);
        uint256 bobLiquidity = pair.mint(bob);

        // Bob deposited half the amounts at the same ratio
        // Gets exactly 5 ether LP — slightly more than aliceLiquidity/2
        // because MINIMUM_LIQUIDITY was deducted from alice but counts in totalSupply for bob's calc
        assertEq(bobLiquidity, 5 ether);
        assertEq(pair.balanceOf(bob), bobLiquidity);
    }

    function test_mint_revertsIfZeroLiquidity() public {
        // sqrt(1000 * 1000) - MINIMUM_LIQUIDITY = 1000 - 1000 = 0
        token0.mint(address(pair), 1000);
        token1.mint(address(pair), 1000);
        vm.expectRevert(PrismSwapPair.InsufficientLiquidityMinted.selector);
        pair.mint(alice);
    }

    // =========================================================
    // Helper
    // =========================================================

    function _addLiquidity(address to, uint256 amount0, uint256 amount1) internal returns (uint256 liquidity) {
        token0.mint(address(pair), amount0);
        token1.mint(address(pair), amount1);
        liquidity = pair.mint(to);
    }

    // =========================================================
    // burn
    // =========================================================

    function test_burn_returnsProportionalAmounts() public {
        uint256 liquidity = _addLiquidity(alice, 10 ether, 10 ether);

        // Send LP tokens back to pair, then burn
        vm.startPrank(alice);
        pair.transfer(address(pair), liquidity);
        (uint256 out0, uint256 out1) = pair.burn(alice);
        vm.stopPrank();

        // Alice should get back her share — almost all tokens minus the MINIMUM_LIQUIDITY portion
        assertGt(out0, 0);
        assertGt(out1, 0);
        assertEq(token0.balanceOf(alice), out0);
        assertEq(token1.balanceOf(alice), out1);
    }

    function test_burn_updatesReserves() public {
        uint256 liquidity = _addLiquidity(alice, 10 ether, 10 ether);

        vm.startPrank(alice);
        pair.transfer(address(pair), liquidity);
        pair.burn(alice);
        vm.stopPrank();

        // Only MINIMUM_LIQUIDITY worth of tokens remain locked in the pair
        (uint112 r0, uint112 r1,) = pair.getReserves();
        assertLt(r0, 10 ether);
        assertLt(r1, 10 ether);
        assertGt(r0, 0);
        assertGt(r1, 0);
    }

    function test_burn_revertsIfNoLiquiditySent() public {
        _addLiquidity(alice, 10 ether, 10 ether);

        // No LP tokens transferred to pair — amounts compute to 0
        vm.expectRevert(PrismSwapPair.InsufficientLiquidityBurned.selector);
        pair.burn(alice);
    }

    // =========================================================
    // swap
    // =========================================================

    function test_swap_token0In() public {
        // Deep pool so small swap doesn't trip circuit breaker
        _addLiquidity(alice, 1000 ether, 1000 ether);

        // Send token0 in, get token1 out
        uint256 amountOut = 1 ether;
        token0.mint(address(pair), 1.1 ether); // ~10% above output to cover fee
        pair.swap(0, amountOut, bob, "");
        
        assertEq(token1.balanceOf(bob), amountOut);
    }

    function test_swap_token1In() public {
        _addLiquidity(alice, 1000 ether, 1000 ether);

        uint256 amountOut = 1 ether;
        token1.mint(address(pair), 1.1 ether);
        pair.swap(amountOut, 0, bob, "");

        assertEq(token0.balanceOf(bob), amountOut);
    }

    function test_swap_kInvariantHolds() public {
        _addLiquidity(alice, 1000 ether, 1000 ether);

        (uint112 r0Before, uint112 r1Before,) = pair.getReserves();
        uint256 kBefore = uint256(r0Before) * uint256(r1Before);

        token0.mint(address(pair), 1.1 ether);
        pair.swap(0, 1 ether, bob, "");

        (uint112 r0After, uint112 r1After,) = pair.getReserves();
        uint256 kAfter = uint256(r0After) * uint256(r1After);

        // k should grow (fees accumulate in pool) or at minimum stay the same
        assertGe(kAfter, kBefore);
    }

    function test_swap_revertsWithNoOutput() public {
        _addLiquidity(alice, 1000 ether, 1000 ether);
        vm.expectRevert(PrismSwapPair.InsufficientOutputAmount.selector);
        pair.swap(0, 0, bob, "");
    }

    function test_swap_revertsIfOutputExceedsReserve() public {
        _addLiquidity(alice, 1000 ether, 1000 ether);
        vm.expectRevert(PrismSwapPair.InsufficientLiquidity.selector);
        pair.swap(0, 1001 ether, bob, "");
    }

    function test_swap_revertsIfToIsToken() public {
        _addLiquidity(alice, 1000 ether, 1000 ether);
        token0.mint(address(pair), 1.1 ether);
        vm.expectRevert(PrismSwapPair.InvalidTo.selector);
        pair.swap(0, 1 ether, address(token1), "");
    }

    function test_swap_revertsIfNoInputSent() public {
        _addLiquidity(alice, 1000 ether, 1000 ether);
        // Don't send any token0 in — nothing to pay with
        vm.expectRevert(PrismSwapPair.InsufficientInputAmount.selector);
        pair.swap(0, 1 ether, bob, "");
    }

    function test_swap_revertsIfKViolated() public {
        _addLiquidity(alice, 1000 ether, 1000 ether);
        // Send exactly 1 ether in but request 1 ether out — no fee paid, K check fails
        token0.mint(address(pair), 1 ether);
        vm.expectRevert(PrismSwapPair.KInvariantViolated.selector);
        pair.swap(0, 1 ether, bob, "");
    }

    function test_swap_circuitBreakerTrips() public {
        // Shallow pool — 10 ether out of 100 moves price ~18% > 10% limit
        _addLiquidity(alice, 100 ether, 100 ether);
        token0.mint(address(pair), 15 ether); // enough to pass K check
        vm.expectRevert(PrismSwapPair.CircuitBreakerActive.selector);
        pair.swap(0, 10 ether, bob, "");
    }

    // =========================================================
    // skim
    // =========================================================

    function test_skim_removesExcessTokens() public {
        _addLiquidity(alice, 10 ether, 10 ether);

        // Send tokens directly to pair bypassing mint — creates surplus above reserves
        token0.mint(address(pair), 5 ether);

        (uint112 r0Before,,) = pair.getReserves();
        pair.skim(bob);

        // Bob received the surplus
        assertEq(token0.balanceOf(bob), 5 ether);

        // Reserves unchanged — skim doesn't call _update
        (uint112 r0After,,) = pair.getReserves();
        assertEq(r0After, r0Before);
    }

    // =========================================================
    // sync
    // =========================================================

    function test_sync_updatesReservesToMatchBalances() public {
        _addLiquidity(alice, 10 ether, 10 ether);

        // Send tokens directly to pair — reserves lag behind real balances
        token0.mint(address(pair), 5 ether);

        // Before sync, reserves are stale
        (uint112 r0Before,,) = pair.getReserves();
        assertEq(r0Before, 10 ether);

        pair.sync();

        // After sync, reserves match actual balance
        (uint112 r0After,,) = pair.getReserves();
        assertEq(r0After, 15 ether);
    }

    // =========================================================
    // fuzz tests
    // =========================================================

    function testFuzz_mint(uint256 amount0, uint256 amount1) public {
        vm.assume(amount0 > 1000);
        vm.assume(amount1 > 1000);
        vm.assume(amount0 < type(uint112).max);
        vm.assume(amount1 < type(uint112).max);

        token0.mint(address(pair), amount0);
        token1.mint(address(pair), amount1);
        uint256 liquidity = pair.mint(alice);

        assertGt(liquidity, 0);
        assertEq(pair.balanceOf(alice), liquidity);
        assertEq(pair.balanceOf(pair.DEAD_ADDRESS()), pair.MINIMUM_LIQUIDITY());

        (uint112 r0, uint112 r1,) = pair.getReserves();
        assertEq(r0, amount0);
        assertEq(r1, amount1);
    }



    function testFuzz_burn(uint256 amount0, uint256 amount1) public {
        vm.assume(amount0 > 1000);
        vm.assume(amount1 > 1000);
        vm.assume(amount0 < type(uint112).max);
        vm.assume(amount1 < type(uint112).max);

        token0.mint(address(pair), amount0);
        token1.mint(address(pair), amount1);
        uint256 liquidity = pair.mint(alice);


        vm.startPrank(alice);
        pair.transfer(address(pair), liquidity);
        (uint256 out0, uint256 out1) = pair.burn(alice);
        vm.stopPrank();


        assertGt(out0, 0);
        assertGt(out1, 0);

        assertLe(out0, amount0);
        assertLe(out1, amount1);
        assertEq(token0.balanceOf(alice), out0);
        assertEq(token1.balanceOf(alice), out1);
    }


   function testFuzz_swap_kNeverDecreases(uint256 amount0In) public {
        vm.assume(amount0In > 1000);
        vm.assume(amount0In < 50 ether);

        _addLiquidity(alice, 1000 ether, 1000 ether);

        (uint112 r0Before, uint112 r1Before,) = pair.getReserves();
        uint256 kBefore = uint256(r0Before) * uint256(r1Before);

        // Mirror the contract's dynamic fee formula to compute a valid amountOut
        uint256 D = 10_000;
        uint256 fee = 30 + (30 * amount0In) / (uint256(r0Before) + amount0In);
        uint256 amountOut = uint256(r1Before) * amount0In * (D - fee)
            / (uint256(r0Before) * D + amount0In * (D - fee));
        vm.assume(amountOut > 0);

        token0.mint(address(pair), amount0In);
        pair.swap(0, amountOut, bob, "");

        (uint112 r0After, uint112 r1After,) = pair.getReserves();
        uint256 kAfter = uint256(r0After) * uint256(r1After);

        assertGe(kAfter, kBefore);
   }


   

}
