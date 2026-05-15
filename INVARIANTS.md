# PrismSwap — Invariants & Critical Protocol Properties

A reference document for invariant tests, formal verification, and audit review.
Covers both core (Pair, Factory) and periphery (Library, Router).

---

## Core — PrismSwapPair

### Hard Invariants
These must NEVER be violated under any sequence of calls.

| ID | Property | Where enforced |
|---|---|---|
| H-1 | `reserve0 * reserve1` never decreases after a swap | K-invariant check in `swap()` |
| H-2 | `balanceOf(pair, token0) >= reserve0` at all times | `_update()` called at end of every state-mutating function |
| H-3 | `balanceOf(pair, token1) >= reserve1` at all times | same |
| H-4 | `DEAD_ADDRESS` LP balance always >= `MINIMUM_LIQUIDITY` (1000) | First mint burns 1000 to dead address permanently |
| H-5 | `reserve0 <= type(uint112).max` and `reserve1 <= type(uint112).max` | Overflow check at top of `_update()` |
| H-6 | `sum(all LP balances) == totalSupply` | OZ ERC20 internal accounting |
| H-7 | `swap()` output recipient can never be `token0` or `token1` | `InvalidTo` check in `swap()` |
| H-8 | Only factory can call `initialize()` | `msg.sender == factory` check |
| H-9 | TWAP accumulators are monotonically non-decreasing (mod uint256) | `unchecked` addition in `_update()` |

### Soft Invariants
These hold under normal conditions but can be affected by edge cases (donations, exotic tokens).

| ID | Property | Caveat |
|---|---|---|
| S-1 | `kLast == reserve0 * reserve1` after every `mint()`/`burn()` when `feeOn` | `sync()` and `swap()` do not update `kLast` |
| S-2 | LP burn payout is strictly proportional to `reserve0`/`reserve1` | Holds because we use stored reserves not live balances in `burn()` |
| S-3 | Dynamic fee is always in `[30, 60)` bps | Bounded by formula: `30 + 30 * x / (reserve + x)` |
| S-4 | `price0CumulativeLast` and `price1CumulativeLast` only advance when `timeElapsed > 0` and reserves are non-zero | Skipped if either reserve is zero |
| S-5 | `feeTo` receives exactly 1/6 of K-growth when `feeOn` | Subject to rounding in sqrt computation |

### Known Bypass Surfaces (not bugs — design properties)
| ID | Property |
|---|---|
| B-1 | `skim()` has no access control — any surplus above reserve is extractable by anyone |
| B-2 | `sync()` has no access control — anyone can snap reserves to current balance, poisoning TWAP |
| B-3 | First depositor sets the initial price ratio — MINIMUM_LIQUIDITY limits but does not prevent manipulation |
| B-4 | CREATE2 pair address is deterministic — pairs can be pre-funded before deployment |
| B-5 | Flash-swap callback receives tokens before `_update()` — `getReserves()` returns stale values during callback |

---

## Core — PrismSwapFactory

| ID | Property |
|---|---|
| F-1 | `getPair[token0][token1] == getPair[token1][token0]` always (symmetric mapping) |
| F-2 | Each pair appears exactly once in `allPairs` |
| F-3 | `allPairs.length == number of unique pairs created` |
| F-4 | Only `onlyOwner` can call `setFeeTo()` |
| F-5 | `createPair()` reverts if pair already exists |
| F-6 | Pair address is deterministic: `CREATE2(factory, keccak256(abi.encodePacked(token0, token1)), PAIR_INIT_CODE_HASH)` |

---

## Periphery — PrismSwapLibrary

### Mathematical Properties

| ID | Property | Function |
|---|---|---|
| L-1 | `sortTokens` always returns `token0 < token1` regardless of input order | `sortTokens` |
| L-2 | `pairFor` output matches actual deployed pair address | `pairFor` |
| L-3 | `quote` rounds down: `amountB * reserveA <= amountA * reserveB` | `quote` |
| L-4 | `getAmountOut` never returns >= `reserveOut` (pool never drained) | `getAmountOut` |
| L-5 | `getAmountOut` always returns <= zero-fee constant-product output (fee always costs something) | `getAmountOut` |
| L-6 | `getAmountIn` rounds up: `getAmountOut(getAmountIn(x)) >= x` for all valid x | `getAmountIn` |
| L-7 | `getAmountsOut` amounts array length == path length | `getAmountsOut` |
| L-8 | `getAmountsOut` amounts[0] == exact input | `getAmountsOut` |
| L-9 | `getAmountsIn` amounts[last] == exact desired output | `getAmountsIn` |

---

## Periphery — PrismSwapRouter

### Liquidity Invariants

| ID | Property |
|---|---|
| R-1 | `addLiquidity` always creates the pair if it doesn't exist |
| R-2 | `addLiquidity` actual deposit never exceeds `amountADesired` or `amountBDesired` |
| R-3 | `addLiquidity` actual deposit always >= `amountAMin` and `amountBMin` — else revert |
| R-4 | `addLiquidity` reverts if `deadline < block.timestamp` |
| R-5 | `removeLiquidity` output always >= `amountAMin` and `amountBMin` — else revert |
| R-6 | `removeLiquidity` reverts if `deadline < block.timestamp` |

### Swap Invariants

| ID | Property |
|---|---|
| R-7 | `swapExactTokensForTokens` output always >= `amountOutMin` — else revert |
| R-8 | `swapExactTokensForTokens` input is always the exact `amountIn` specified |
| R-9 | `swapTokensForExactTokens` output is always the exact `amountOut` specified |
| R-10 | `swapTokensForExactTokens` input never exceeds `amountInMax` — else revert |
| R-11 | Both swap functions revert if `deadline < block.timestamp` |
| R-12 | Multi-hop: tokens flow pair-to-pair without touching the Router |

---

## Critical Cross-Contract Properties

These span multiple contracts and are the hardest to test but most important.

| ID | Property | Risk if violated |
|---|---|---|
| X-1 | `PAIR_INIT_CODE_HASH` in Library matches actual deployed Pair bytecode | Router silently routes all calls to wrong address — complete protocol failure |
| X-2 | Factory salt (`keccak256(abi.encodePacked(token0, token1))`) matches Library's `pairFor` salt | Same as X-1 |
| X-3 | Dynamic fee formula in Library matches K-invariant check in Pair | Quotes diverge from execution — users pay more or less than expected |
| X-4 | `token0`/`token1` ordering in Pair matches Library's `sortTokens` ordering | Reserve alignment breaks — wrong token amounts returned on every operation |
| X-5 | Router's `_swap` sends tokens directly pair-to-pair (not through Router) | Gas inefficiency and potential balance accounting errors |

---

## Unverified — Requires Formal Verification

These cannot be proven by fuzz testing alone and are flagged by Stratum as needing formal methods.

| ID | Property | Why fuzz is insufficient |
|---|---|---|
| FV-1 | K-invariant holds for ALL valid input tuples under the dynamic fee formula — including two-sided input (`amount0In > 0` AND `amount1In > 0` simultaneously) | Fuzz explores random inputs; formal verification proves over all possible inputs |
| FV-2 | `getAmountIn` always overestimates by exactly 1 unit (no more, no less) | Requires proof over all integer inputs |
| FV-3 | `price0CumulativeLast` modular arithmetic is consistent with TWAP consumer subtraction | Requires reasoning about overflow semantics |
| FV-4 | No sequence of calls can cause `reserve0 * reserve1` to decrease | Requires exhaustive state space exploration |

---

## Testing Checklist

| Layer | Unit | Fuzz | Invariant | Slither | Mythril | Stratum | Formal |
|---|---|---|---|---|---|---|---|
| PrismSwapPair | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ⬜ |
| PrismSwapFactory | ⬜ | ⬜ | ⬜ | ✅ | ✅ | ✅ | ⬜ |
| PrismSwapLibrary | ✅ | ✅ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| PrismSwapRouter | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
