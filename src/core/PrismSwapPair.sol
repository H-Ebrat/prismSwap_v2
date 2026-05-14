// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {PrismSwapERC20} from "./PrismSwapERC20.sol";
import {IPrismSwapFactory} from "./interfaces/IPrismSwapFactory.sol";
import {IPrismSwapCallee} from "./interfaces/IPrismSwapCallee.sol";
import {UQ112x112} from "./libraries/UQ112x112.sol";

contract PrismSwapPair is PrismSwapERC20, ReentrancyGuard {
    using UQ112x112 for uint224;
    using SafeERC20 for IERC20;

    // --- Constants ---
    uint256 public constant MINIMUM_LIQUIDITY = 1000;
    // Dead address used to permanently lock MINIMUM_LIQUIDITY (OZ v5 rejects minting to address(0))
    address public constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    uint256 public constant BASE_FEE = 30; // 0.30% default fee
    uint256 public constant FEE_DENOMINATOR = 10000;

    // --- Core State ---
    address public immutable factory;
    address public token0;
    address public token1;

    // Packed into one 32-byte storage slot (112 + 112 + 32 = 256 bits)
    uint112 private reserve0;
    uint112 private reserve1;
    uint32 private blockTimestampLast;

    // --- TWAP Accumulators ---
    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;

    // --- Protocol Fee ---
    uint256 public kLast;

    // --- Errors ---
    error Forbidden();
    error InsufficientLiquidityMinted();
    error InsufficientLiquidityBurned();
    error InsufficientOutputAmount();
    error InsufficientLiquidity();
    error InsufficientInputAmount();
    error InvalidTo();
    error KInvariantViolated();
    error Overflow();

    // --- Events ---
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    // --- Constructor ---
    constructor() {
        factory = msg.sender;
    }

    // --- Initializer (called by factory after CREATE2 deployment) ---
    function initialize(address _token0, address _token1) external {
        if (msg.sender != factory) revert Forbidden();
        if (_token0 == address(0) || _token1 == address(0)) revert Forbidden();
        token0 = _token0;
        token1 = _token1;
    }

    // --- Getters ---
    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    // --- Internal: Update reserves and accumulate TWAP ---
    function _update(uint256 balance0, uint256 balance1, uint112 _reserve0, uint112 _reserve1) private {
        if (balance0 > type(uint112).max || balance1 > type(uint112).max) revert Overflow();

        uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);
        uint32 timeElapsed;
        unchecked {
            timeElapsed = blockTimestamp - blockTimestampLast; // intentional overflow for timestamp wrapping
        }

        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            unchecked {
                price0CumulativeLast += uint256(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
                price1CumulativeLast += uint256(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
            }
        }

        // safe: overflow checked above via type(uint112).max guard
        // forge-lint: disable-next-line(unsafe-typecast)
        reserve0 = uint112(balance0);
        // forge-lint: disable-next-line(unsafe-typecast)
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // --- Internal: Mint protocol fee as LP tokens if fee is on ---
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = IPrismSwapFactory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint256 _kLast = kLast;

        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = Math.sqrt(uint256(_reserve0) * uint256(_reserve1));
                uint256 rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint256 numerator = totalSupply() * (rootK - rootKLast);
                    uint256 denominator = rootK * 5 + rootKLast;
                    uint256 liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    // --- Mint: Add liquidity, receive LP tokens ---
    function mint(address to) external nonReentrant returns (uint256 liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0 = balance0 - _reserve0;
        uint256 amount1 = balance1 - _reserve1;

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 supply = totalSupply();

        if (supply == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            _mint(DEAD_ADDRESS, MINIMUM_LIQUIDITY);
        } else {
            liquidity = Math.min(amount0 * supply / _reserve0, amount1 * supply / _reserve1);
        }

        if (liquidity == 0) revert InsufficientLiquidityMinted();
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint256(reserve0) * uint256(reserve1);
        emit Mint(msg.sender, amount0, amount1);
    }

    function burn(address to) external nonReentrant returns (uint256 amount0, uint256 amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        address _token0 = token0;
        address _token1 = token1;
        uint256 liquidity = balanceOf(address(this));

        bool feeOn = _mintFee(_reserve0, _reserve1);

        uint256 supply = totalSupply();

        // Use stored reserves (not live balances) — prevents donation-timing attacks
        amount0 = liquidity * uint256(_reserve0) / supply;
        amount1 = liquidity * uint256(_reserve1) / supply;
        if (amount0 == 0 || amount1 == 0) revert InsufficientLiquidityBurned();

        _burn(address(this), liquidity);
        IERC20(_token0).safeTransfer(to, amount0);
        IERC20(_token1).safeTransfer(to, amount1);
        uint256 balance0 = IERC20(_token0).balanceOf(address(this));
        uint256 balance1 = IERC20(_token1).balanceOf(address(this));
        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint256(reserve0) * uint256(reserve1);
        emit Burn(msg.sender, amount0, amount1, to);
    }

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external nonReentrant {
        if (amount0Out == 0 && amount1Out == 0) revert InsufficientOutputAmount();

        (uint112 _reserve0, uint112 _reserve1,) = getReserves();
        if (amount0Out >= _reserve0 || amount1Out >= _reserve1) revert InsufficientLiquidity();

        address _token0 = token0;
        address _token1 = token1;
        if (to == _token0 || to == _token1) revert InvalidTo();

        // Optimistically transfer output tokens before verifying payment
        if (amount0Out > 0) IERC20(_token0).safeTransfer(to, amount0Out);
        if (amount1Out > 0) IERC20(_token1).safeTransfer(to, amount1Out);

        // Flash swap: call recipient before checking invariant so they can pay back in same tx
        if (data.length > 0) IPrismSwapCallee(to).prismSwapCall(msg.sender, amount0Out, amount1Out, data);

        uint256 balance0 = IERC20(_token0).balanceOf(address(this));
        uint256 balance1 = IERC20(_token1).balanceOf(address(this));

        // Calculate how much was actually sent in by comparing post-transfer balances to pre-swap reserves
        uint256 amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint256 amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        if (amount0In == 0 && amount1In == 0) revert InsufficientInputAmount();

        // Compute fee independently per input side — prevents dust-based fee bypass
        uint256 fee0 = amount0In > 0 ? BASE_FEE + (BASE_FEE * amount0In) / (_reserve0 + amount0In) : 0;
        uint256 fee1 = amount1In > 0 ? BASE_FEE + (BASE_FEE * amount1In) / (_reserve1 + amount1In) : 0;

        uint256 balance0Adjusted = balance0 * FEE_DENOMINATOR - amount0In * fee0;
        uint256 balance1Adjusted = balance1 * FEE_DENOMINATOR - amount1In * fee1;
        if (balance0Adjusted * balance1Adjusted < uint256(_reserve0) * uint256(_reserve1) * FEE_DENOMINATOR ** 2)
            revert KInvariantViolated();

        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    function skim(address to) external nonReentrant {
        address _token0 = token0;
        address _token1 = token1;
        IERC20(_token0).safeTransfer(to, IERC20(_token0).balanceOf(address(this)) - reserve0);
        IERC20(_token1).safeTransfer(to, IERC20(_token1).balanceOf(address(this)) - reserve1);
    }

    function sync() external nonReentrant {
        _update(
            IERC20(token0).balanceOf(address(this)),
            IERC20(token1).balanceOf(address(this)),
            reserve0,
            reserve1
        );
    }
}
