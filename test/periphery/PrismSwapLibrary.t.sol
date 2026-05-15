// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {PrismSwapLibrary} from "../../src/periphery/libraries/PrismSwapLibrary.sol";
import {PrismSwapFactory} from "../../src/core/PrismSwapFactory.sol";
import {PrismSwapPair} from "../../src/core/PrismSwapPair.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}
    function mint(address to, uint256 amount) external { _mint(to, amount); }
}

// Harness exposes internal library functions as external so vm.expectRevert works
contract LibraryHarness {
    function sortTokens(address a, address b) external pure returns (address, address) {
        return PrismSwapLibrary.sortTokens(a, b);
    }

    function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) external pure returns (uint256) {
        return PrismSwapLibrary.quote(amountA, reserveA, reserveB);
    }

    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256) {
        return PrismSwapLibrary.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) external pure returns (uint256) {
        return PrismSwapLibrary.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    function getAmountsOut(address factory, uint256 amountIn, address[] memory path) external view returns (uint256[] memory) {
        return PrismSwapLibrary.getAmountsOut(factory, amountIn, path);
    }

    function getAmountsIn(address factory, uint256 amountOut, address[] memory path) external view returns (uint256[] memory) {
        return PrismSwapLibrary.getAmountsIn(factory, amountOut, path);
    }
}

contract PrismSwapLibraryTest is Test {
    LibraryHarness harness;
    PrismSwapFactory factory;
    MockERC20 tokenA;
    MockERC20 tokenB;

    // Sorted versions — assigned in setUp after we know which address is smaller
    address token0;
    address token1;

    function setUp() public {
        harness = new LibraryHarness();
        factory = new PrismSwapFactory(address(this));
        tokenA = new MockERC20("Token A", "TKA");
        tokenB = new MockERC20("Token B", "TKB");

        // Mirror what the library does — sort so token0 < token1
        (token0, token1) = address(tokenA) < address(tokenB)
            ? (address(tokenA), address(tokenB))
            : (address(tokenB), address(tokenA));
    }

    // =========================================================
    // sortTokens
    // =========================================================

    function test_sortTokens_smallerAddressFirst() public pure {
        address a = address(0x1);
        address b = address(0x2);
        (address t0, address t1) = PrismSwapLibrary.sortTokens(a, b);
        assertEq(t0, address(0x1));
        assertEq(t1, address(0x2));
    }

    function test_sortTokens_reversedInputStillSorts() public pure {
        address a = address(0x2);
        address b = address(0x1);
        (address t0, address t1) = PrismSwapLibrary.sortTokens(a, b);
        assertEq(t0, address(0x1));
        assertEq(t1, address(0x2));
    }

    function test_sortTokens_revertsOnIdenticalAddresses() public {
        vm.expectRevert(PrismSwapLibrary.IdenticalAddresses.selector);
        harness.sortTokens(address(0x1), address(0x1));
    }

    function test_sortTokens_revertsOnZeroAddress() public {
        vm.expectRevert(PrismSwapLibrary.ZeroAddress.selector);
        harness.sortTokens(address(0), address(0x1));
    }

    // =========================================================
    // pairFor
    // =========================================================

    function test_pairFor_matchesActualDeployedPair() public {
        address deployed = factory.createPair(address(tokenA), address(tokenB));
        address computed = PrismSwapLibrary.pairFor(address(factory), address(tokenA), address(tokenB));
        assertEq(computed, deployed);
    }

    function test_pairFor_isOrderIndependent() public {
        address deployed = factory.createPair(address(tokenA), address(tokenB));
        address computedAB = PrismSwapLibrary.pairFor(address(factory), address(tokenA), address(tokenB));
        address computedBA = PrismSwapLibrary.pairFor(address(factory), address(tokenB), address(tokenA));
        assertEq(computedAB, deployed);
        assertEq(computedBA, deployed);
    }

    // =========================================================
    // getReserves
    // =========================================================

    function test_getReserves_alignsToCallerTokenOrder() public {
        address pairAddr = factory.createPair(address(tokenA), address(tokenB));
        PrismSwapPair pair = PrismSwapPair(pairAddr);

        // Deposit 100 token0 and 200 token1 into the pool
        MockERC20(token0).mint(pairAddr, 100 ether);
        MockERC20(token1).mint(pairAddr, 200 ether);
        pair.mint(address(this));

        // Ask for reserves in token0/token1 order
        (uint256 r0, uint256 r1) = PrismSwapLibrary.getReserves(address(factory), token0, token1);
        assertEq(r0, 100 ether);
        assertEq(r1, 200 ether);

        // Ask for reserves in reversed order — should flip
        (uint256 rA, uint256 rB) = PrismSwapLibrary.getReserves(address(factory), token1, token0);
        assertEq(rA, 200 ether);
        assertEq(rB, 100 ether);
    }

    // =========================================================
    // quote
    // =========================================================

    function test_quote_returnsProportionalAmount() public pure {
        // 1 tokenA in a pool with 10A:20B should give 2B
        uint256 amountB = PrismSwapLibrary.quote(1 ether, 10 ether, 20 ether);
        assertEq(amountB, 2 ether);
    }

    function test_quote_revertsOnZeroAmount() public {
        vm.expectRevert(PrismSwapLibrary.InsufficientAmount.selector);
        harness.quote(0, 10 ether, 20 ether);
    }

    function test_quote_revertsOnZeroReserve() public {
        vm.expectRevert(PrismSwapLibrary.InsufficientLiquidity.selector);
        harness.quote(1 ether, 0, 20 ether);
    }

    // =========================================================
    // getAmountOut
    // =========================================================

    function test_getAmountOut_lessThanInputDueToFee() public pure {
        // In a 1000:1000 pool, 10 tokens in should give slightly less than 10 out
        uint256 amountOut = PrismSwapLibrary.getAmountOut(10 ether, 1000 ether, 1000 ether);
        assertLt(amountOut, 10 ether);
        assertGt(amountOut, 0);
    }

    function test_getAmountOut_largerSwapPaysHigherFee() public pure {
        // Small swap: 1 in on 1000:1000 pool
        uint256 smallOut = PrismSwapLibrary.getAmountOut(1 ether, 1000 ether, 1000 ether);
        // Large swap: 100 in on same pool
        uint256 largeOut = PrismSwapLibrary.getAmountOut(100 ether, 1000 ether, 1000 ether);

        // Small swap efficiency = out/in should be higher than large swap efficiency
        // i.e. small swap gets a better rate (dynamic fee is lower)
        uint256 smallEfficiency = smallOut * 1e18 / 1 ether;
        uint256 largeEfficiency = largeOut * 1e18 / 100 ether;
        assertGt(smallEfficiency, largeEfficiency);
    }

    function test_getAmountOut_revertsOnZeroInput() public {
        vm.expectRevert(PrismSwapLibrary.InsufficientInputAmount.selector);
        harness.getAmountOut(0, 1000 ether, 1000 ether);
    }

    function test_getAmountOut_revertsOnZeroReserve() public {
        vm.expectRevert(PrismSwapLibrary.InsufficientLiquidity.selector);
        harness.getAmountOut(1 ether, 0, 1000 ether);
    }

    // =========================================================
    // getAmountIn
    // =========================================================

    function test_getAmountIn_roundsUp() public pure {
        // getAmountIn should always round up to protect the pool
        uint256 amountIn = PrismSwapLibrary.getAmountIn(1 ether, 1000 ether, 1000 ether);
        // The computed amountIn, when used in getAmountOut, should yield >= 1 ether out
        uint256 amountOut = PrismSwapLibrary.getAmountOut(amountIn, 1000 ether, 1000 ether);
        assertGe(amountOut, 1 ether);
    }

    function test_getAmountIn_revertsOnZeroOutput() public {
        vm.expectRevert(PrismSwapLibrary.InsufficientOutputAmount.selector);
        harness.getAmountIn(0, 1000 ether, 1000 ether);
    }

    function test_getAmountIn_revertsOnZeroReserve() public {
        vm.expectRevert(PrismSwapLibrary.InsufficientLiquidity.selector);
        harness.getAmountIn(1 ether, 0, 1000 ether);
    }

    // =========================================================
    // getAmountsOut / getAmountsIn
    // =========================================================

    function test_getAmountsOut_singleHop() public {
        factory.createPair(address(tokenA), address(tokenB));
        address pairAddr = PrismSwapLibrary.pairFor(address(factory), address(tokenA), address(tokenB));

        MockERC20(token0).mint(pairAddr, 1000 ether);
        MockERC20(token1).mint(pairAddr, 1000 ether);
        PrismSwapPair(pairAddr).mint(address(this));

        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);

        uint256[] memory amounts = PrismSwapLibrary.getAmountsOut(address(factory), 10 ether, path);

        assertEq(amounts[0], 10 ether);       // input is exact
        assertLt(amounts[1], 10 ether);       // output less than input due to fee
        assertGt(amounts[1], 0);
    }

    function test_getAmountsIn_singleHop() public {
        factory.createPair(address(tokenA), address(tokenB));
        address pairAddr = PrismSwapLibrary.pairFor(address(factory), address(tokenA), address(tokenB));

        MockERC20(token0).mint(pairAddr, 1000 ether);
        MockERC20(token1).mint(pairAddr, 1000 ether);
        PrismSwapPair(pairAddr).mint(address(this));

        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);

        uint256[] memory amounts = PrismSwapLibrary.getAmountsIn(address(factory), 10 ether, path);

        assertEq(amounts[amounts.length - 1], 10 ether); // desired output is exact
        assertGt(amounts[0], 10 ether);                  // required input more than output due to fee
    }

    function test_getAmountsOut_revertsOnShortPath() public {
        vm.expectRevert(PrismSwapLibrary.InvalidPath.selector);
        address[] memory path = new address[](1);
        path[0] = address(tokenA);
        harness.getAmountsOut(address(factory), 1 ether, path);
    }

    function test_getAmountsIn_revertsOnShortPath() public {
        vm.expectRevert(PrismSwapLibrary.InvalidPath.selector);
        address[] memory path = new address[](1);
        path[0] = address(tokenA);
        harness.getAmountsIn(address(factory), 1 ether, path);
    }

    // =========================================================
    // fuzz tests
    // =========================================================

    function testFuzz_sortTokens_alwaysOrdered(address a, address b) public {
        vm.assume(a != b);
        vm.assume(a != address(0));
        vm.assume(b != address(0));
        (address t0, address t1) = PrismSwapLibrary.sortTokens(a, b);
        // No matter what order the caller passed, t0 must always be the smaller address
        assertLt(uint160(t0), uint160(t1));
    }

    function testFuzz_quote_roundsDown(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) public pure {
        vm.assume(amountA > 0 && amountA <= type(uint112).max);
        vm.assume(reserveA > 0 && reserveA <= type(uint112).max);
        vm.assume(reserveB > 0 && reserveB <= type(uint112).max);

        uint256 amountB = PrismSwapLibrary.quote(amountA, reserveA, reserveB);

        // quote is integer division so it rounds down — amountB * reserveA can never exceed amountA * reserveB
        assertLe(amountB * reserveA, amountA * reserveB);
    }

    function testFuzz_getAmountOut_neverDrainsPool(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure {
        vm.assume(amountIn > 0 && amountIn <= type(uint112).max);
        vm.assume(reserveIn > 0 && reserveIn <= type(uint112).max);
        vm.assume(reserveOut > 0 && reserveOut <= type(uint112).max);

        uint256 amountOut = PrismSwapLibrary.getAmountOut(amountIn, reserveIn, reserveOut);

        // Output must always be strictly less than the reserve — pool can never be fully drained
        assertLt(amountOut, reserveOut);
    }

    function testFuzz_getAmountOut_feeAlwaysApplied(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure {
        vm.assume(amountIn > 0 && amountIn <= type(uint112).max);
        vm.assume(reserveIn > 0 && reserveIn <= type(uint112).max);
        vm.assume(reserveOut > 0 && reserveOut <= type(uint112).max);

        uint256 amountOut = PrismSwapLibrary.getAmountOut(amountIn, reserveIn, reserveOut);

        // Zero-fee constant-product output — always the maximum possible output
        // With any fee applied, actual output must be at or below this ceiling
        uint256 zeroFeeOut = amountIn * reserveOut / (reserveIn + amountIn);
        assertLe(amountOut, zeroFeeOut);
    }

    function testFuzz_getAmountIn_roundTrip(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) public pure {
        vm.assume(reserveIn > 0 && reserveIn <= type(uint112).max);
        vm.assume(reserveOut > 0 && reserveOut <= type(uint112).max);
        // amountOut must be strictly less than reserveOut — can't want more than the pool holds
        vm.assume(amountOut > 0 && amountOut < reserveOut);

        uint256 amountIn = PrismSwapLibrary.getAmountIn(amountOut, reserveIn, reserveOut);
        uint256 actualOut = PrismSwapLibrary.getAmountOut(amountIn, reserveIn, reserveOut);

        // Round-trip: the input computed by getAmountIn, when run through getAmountOut,
        // must yield at least as much output as originally desired
        // This proves getAmountIn never underestimates the required input
        assertGe(actualOut, amountOut);
    }

    function testFuzz_getAmountsOut_pathLengthMatchesAmounts(
        uint256 amountIn
    ) public {
        vm.assume(amountIn > 0 && amountIn <= 100 ether);

        factory.createPair(address(tokenA), address(tokenB));
        address pairAddr = PrismSwapLibrary.pairFor(address(factory), address(tokenA), address(tokenB));
        MockERC20(token0).mint(pairAddr, 1000 ether);
        MockERC20(token1).mint(pairAddr, 1000 ether);
        PrismSwapPair(pairAddr).mint(address(this));

        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);

        uint256[] memory amounts = PrismSwapLibrary.getAmountsOut(address(factory), amountIn, path);

        // amounts array length always equals path length
        assertEq(amounts.length, path.length);
        // first element is always the exact input
        assertEq(amounts[0], amountIn);
    }

    function testFuzz_getAmountsIn_pathLengthMatchesAmounts(
        uint256 amountOut
    ) public {
        vm.assume(amountOut > 0 && amountOut <= 100 ether);

        factory.createPair(address(tokenA), address(tokenB));
        address pairAddr = PrismSwapLibrary.pairFor(address(factory), address(tokenA), address(tokenB));
        MockERC20(token0).mint(pairAddr, 1000 ether);
        MockERC20(token1).mint(pairAddr, 1000 ether);
        PrismSwapPair(pairAddr).mint(address(this));

        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);

        uint256[] memory amounts = PrismSwapLibrary.getAmountsIn(address(factory), amountOut, path);

        // amounts array length always equals path length
        assertEq(amounts.length, path.length);
        // last element is always the exact desired output
        assertEq(amounts[amounts.length - 1], amountOut);
    }
}
