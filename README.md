# PrismSwap

PrismSwap is a modern fork of Uniswap V2, rebuilt from scratch in Solidity 0.8.x with OpenZeppelin, improved patterns, and custom protocol enhancements. It follows the same V2 → V3 → V4 progression as Uniswap, with each version introducing new mechanics.

---

## Why fork Uniswap V2?

Uniswap V2 is the foundational AMM primitive in DeFi. It's simple enough to understand fully, yet deep enough to teach every core concept: constant product pricing, LP tokens, TWAP oracles, flash swaps. PrismSwap starts here and builds up.

---

## What's different from Uniswap V2

### Modern Solidity (0.8.x)
- Built-in overflow/underflow protection — no SafeMath
- Custom errors instead of revert strings (cheaper gas)
- `type(uint256).max` instead of `uint(-1)` hacks
- `block.chainid` instead of inline assembly
- OpenZeppelin for battle-tested base contracts (ERC20, ERC20Permit, ReentrancyGuard)

### V2 Custom Features
1. **Dynamic Fees** — swap fee adjusts based on price volatility within a block, instead of a hardcoded 0.3%
2. **Circuit Breaker** — swaps are paused automatically if price moves beyond a configurable threshold in a single block, protecting LPs from extreme manipulation

---

## Repo Structure

```
src/
├── core/         — Pair, Factory, ERC20 (LP token)
└── periphery/    — Router, Library helpers
test/
├── core/
└── periphery/
```

---

## Versions Roadmap

| Version | Status | Focus |
|---------|--------|-------|
| V2 | In Progress | AMM primitives + dynamic fees + circuit breaker |
| V3 | Planned | TBD |
| V4 | Shortlisted | Intent-based DEX (CoW/UniswapX style) or MEV-protected DEX (commit-reveal) |

---

## Dependencies

- [OpenZeppelin Contracts v5](https://github.com/OpenZeppelin/openzeppelin-contracts)
- [Foundry](https://github.com/foundry-rs/foundry)
