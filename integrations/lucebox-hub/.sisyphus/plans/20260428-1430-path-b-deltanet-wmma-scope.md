# Scope: Path B — WMMA tensor-core rewrite of `pf_dn_chunk_phase2` (Ampere sm_86)

**Date**: 2026-04-28
**Target**: `megakernel/prefill.cu` — `pf_dn_chunk_phase2` only (phase1 unchanged for v1)
**Why**: Profiler shows this kernel = 47.6% of prefill CUDA time (13.27 ms / 27.88 ms total) on RTX 3090 / 512-token prompt. Inner products are scalar FP32 in shared memory; tensor cores are unused. Existing GEMMs (Q/K/V proj, MLP) already go to cuBLAS tensor cores (`ampere_bf16_s16816gemm…`).

---

## Goal & non-goals

**Goal**: Replace the four matmul-shaped inner loops in phase2 with WMMA bf16 / f32-accum matmuls, with f32 accumulator semantics so numerical drift in the recurrence stays bounded.

**Non-goals**:
- Phase1 rewrite (it has different math: cumsum, sigmoid, softplus, triangular forward-substitute — only one matmul-shaped piece, marginal win).
- Algorithmic changes to the recurrence (correctness reference is the existing scalar `pf_dn_chunk_phase2`).
- Backporting Blackwell `prefill_megakernel.cu` patterns (different launch model, persistent kernel, `cg::this_grid().sync()`).
- Multi-stream / overlap with FA layers.
- New CLI surface; this is a drop-in kernel replacement gated by a build-time flag for A/B.

**Out-of-scope but worth noting**: state update is the only operation where reducing precision could plausibly compound across chunks. The other three ops are read-only against state; their bf16 truncation only affects per-chunk outputs.

---

## Math: what's actually matmul-shaped

Per chunk `n`, phase2 currently runs five distinct compute steps. Four are matmul-shaped with f32 inputs in shared memory:

| Op | Formula | M × N × K | FMAs/chunk | WMMA fit |
|---|---|---:|---:|---|
| **d compute** | `d[c,j] = u[c,j] - Σ_d w[c,d]·state[j,d]` | 8 × 32 × 128 | 32K | m8n32k16, K-loops=8 |
| **QKt compute** | `QKt[c,s] = Σ_d Q[c,d]·K[s,d]` | 8 × 8 × 128 | 8K | M,N<16; **keep scalar** (only 7% of compute) |
| **o_inter compute** | `tmp[c,j] = Σ_d Q[c,d]·state[j,d]` | 8 × 32 × 128 | 32K | m8n32k16, K-loops=8 |
| **state update** | `state[j,i] = γ·state[j,i] + Σ_c d_scaled[c,j]·K[c,i]` | 32 × 128 × 8 | 32K | m16n16k16, K=8→pad 16 |
| **o_intra** | `o_intra[c,j] = Σ_{s≤c} (QKt[c,s]·exp(cs[c]-cs[s]))·d[s,j]` | 8 × 32 × 8 | 2K | tiny + triangular mask; **keep scalar** |

WMMA-targeted ops total ~96K FMAs per chunk per block (out of ~106K total matmul-shaped). With N=64 chunks × 72 blocks = ~441M MAC over 13.27 ms today = **~33 GFLOPS realized**. Ampere bf16 tensor-core peak is 142 TFLOPS. Headroom is enormous, but most of the 13.27 ms is launch/sync/smem-load — not pure compute.

## Constants we're working with

```
DN_HEADS = 16              DN_KEY = 128         DN_VAL = 128
DN_CHUNK_C = 8             DN_PHASE2_J_SPLITS = 4
DN_PHASE2_J_PER_BLOCK = 32 DN_PHASE2_BLOCK = 128 (4 warps)
Launch grid: (DN_HEADS, J_SPLITS) = (16, 4) = 64 blocks
__launch_bounds__(128, 1) → 1 block / SM = 8% theoretical occupancy
P2 dynamic smem: ~31 KB
```

---

## WMMA design

### Fragment shapes

Ampere sm_86 supports the following bf16 WMMA fragment shapes (`<mma.h>`, `nvcuda::wmma`):

| Shape | A | B | C |
|---|---|---|---|
| **m16n16k16** | matrix_a 16×16 bf16 | matrix_b 16×16 bf16 | accumulator 16×16 f32 |
| m8n32k16 | matrix_a 8×16 bf16 | matrix_b 16×32 bf16 | accumulator 8×32 f32 |
| m32n8k16 | matrix_a 32×16 bf16 | matrix_b 16×8 bf16 | accumulator 32×8 f32 |

**Choice**: stick to **m16n16k16** for simplicity and uniform fragment lifetime across the three target ops. Tile mapping:

- **d**, **o_inter** (M=8, N=32, K=128): one warp per op-instance. Fragment M=16 covers M=8 (with padding); N=32 needs 2 N-tiles. K=128 / 16 = 8 K-iters. So per warp: `2 × 8 = 16` mma.sync calls per op.
- **state update** (M=32, N=128, K=8): two warps cooperate. M=32 / 16 = 2 M-tiles; N=128 / 16 = 8 N-tiles. K=8 → pad to 16 = 1 K-iter. 16 mma.sync calls split across 2 warps = 8 per warp.

Block has 4 warps. Mapping per chunk:
- Warps 0-1: state update (cooperating on M-tiles 0 and 1)
- Warps 2-3: d compute and o_inter (each does half the N-tiles)
- QKt and o_intra stay scalar (handled by all 4 warps before/after the WMMA region)

### Data types

| Tensor | Current | Proposed |
|---|---|---|
| `s_state` | f32 | f32 + bf16 staging (load f32 from global, write bf16 mirror for WMMA reads) |
| `s_w` | f32 | bf16 (load from f32 source, downcast on store) |
| `s_Q`, `s_K` | f32 (loaded from bf16 qkv_pre) | bf16 (load directly without f32 round-trip) |
| `s_u`, `s_d` | f32 | f32 (these are accumulator-side; written from WMMA C fragment via `store_matrix_sync`) |
| `state` (global) | f32 | **f32** — unchanged, decode kernel reads it. No format change at the boundary. |

Accumulator stays f32 inside WMMA fragments. Down-conversion to bf16 only happens when feeding the next op's inputs, not in the persistent state.

### Numerical risk

The state update uses `state_new = γ·state_old + Σ d·K` with γ ≤ 1 (decay). Per-chunk error from bf16 truncation of `state_old` reads is ~2⁻⁸ relative. Over N=64 chunks, the recurrence damps errors via γ at each step rather than amplifying. Realistic worst-case: ~2⁻⁵ relative drift at chunk 64. This is well within bf16 inference tolerance for LLM logits (where end-of-prompt position tolerance is typically O(2⁻⁴) vs f32 reference).

**Verification gate**: bench_pp_tg.py's existing correctness section runs "The capital of France is" and asserts the first generated token. New kernel must produce the same token. Additional guard: compare full pp520 output token IDs against the scalar reference for 100+ prompts.

---

## Layout & smem budget

New smem layout (sized for 1 block, dynamic smem stays under 100 KB):

```
s_state_f32   [J_per × DK_S]            32×129×4   = 16.5 KB
s_state_bf16  [J_per × DK_S]            32×129×2   =  8.3 KB  // bf16 mirror, refreshed per chunk
s_u           [DN_CHUNK_C × J_per]       8×32×4    =  1.0 KB  // f32 accumulator
s_w_bf16      [DN_CHUNK_C × DK_S]        8×129×2   =  2.1 KB
s_Q_bf16      [DN_CHUNK_C × DK_S]        8×129×2   =  2.1 KB
s_K_bf16      [DN_CHUNK_C × DK_S]        8×129×2   =  2.1 KB
s_d           [DN_CHUNK_C × J_per]       8×32×4    =  1.0 KB
s_qkt         [DN_CHUNK_C × DN_CHUNK_C]  8×8×4     =  0.25 KB
s_cs, s_decay_rem [DN_CHUNK_C]                       0.06 KB
─────────────────────────────────────────────────
                                               TOTAL: ~33.4 KB
```

Slightly bigger than today's ~31 KB but well under Ampere's 100 KB-per-block ceiling. Refreshing the `s_state_bf16` mirror after each chunk's state update costs 32×129 = 4128 cvts per block, fully parallelizable across 128 threads.

---

## Implementation plan

### SOVEREIGN — preconditions (1 hr)

1. Confirm RTX 3090's actual `cudaDeviceProp.sharedMemPerBlockOptin` (should be 100 KB, but verify).
2. Add a build-time flag in `setup.py`: `MEGAKERNEL_DN_PHASE2_WMMA=on|off` (default off). Plumbs through to a `#define DN_PHASE2_WMMA` in `prefill.cu` so the new kernel sits next to the existing scalar version under `#ifdef`.
3. Wire a Python env-var override (`MEGAKERNEL_DN_PHASE2_WMMA=1`) so we can A/B without rebuilding.

### SOVEREIGN — instrumentation (1-2 hr)

1. Rerun `diag_prefill_kernels.py` with `record_shapes=True` and CUPTI metrics (`profile_memory=True, with_stack=True`). Get per-launch SM occupancy and stall reasons for `pf_dn_chunk_phase2`.
2. Compute the actual mix: how much of the 13.27 ms is compute vs smem-load vs sync. (Ratio determines whether WMMA alone or WMMA+`cp.async` is the right swing.)
3. Save the baseline output token IDs for the correctness corpus (50 fixed prompts × 32-token completions).

### SOVEREIGN — WMMA "d compute" only (3-5 hr)

Smallest demonstrable win. Replace the d-compute loop (lines 580-589) with:

```cpp
using namespace nvcuda::wmma;
constexpr int WM=16, WN=16, WK=16;

// Convert s_state f32 → bf16 mirror once per chunk before WMMA region.
// (One-time at chunk start; refresh after state update at chunk end.)

fragment<matrix_a, WM, WN, WK, __nv_bfloat16, row_major>     a_w;
fragment<matrix_b, WM, WN, WK, __nv_bfloat16, col_major>     b_state;
fragment<accumulator, WM, WN, WK, float>                     c_d;

int warp_id = tid / 32;
if (warp_id < 2) {                                          // 2 warps cover N-tile 0 and 1
    int n_tile = warp_id;
    fill_fragment(c_d, 0.f);
    #pragma unroll
    for (int kk = 0; kk < DN_KEY; kk += WK) {
        load_matrix_sync(a_w, s_w_bf16 + kk, DK_S);                     // [C(8 padded to 16)][WK]
        load_matrix_sync(b_state, s_state_bf16 + n_tile*WN*DK_S + kk, DK_S);  // [J(WN)][WK] col-major
        mma_sync(c_d, a_w, b_state, c_d);
    }
    // Subtract u and write to s_d. Layout depends on fragment storage convention; use
    // store_matrix_sync into a temp f32 tile then subtract per-thread.
    float tmp[16][16];  // (per-warp scratchpad in registers — actually use a smem tile)
    store_matrix_sync(/*ptr=*/..., c_d, /*ldc=*/..., mem_row_major);
    // ...subtract s_u in-place, write s_d
}
__syncthreads();
```

Compare scalar vs WMMA d-output bit-for-bit difference on a fixed 16-token chunk. Acceptable: relative max diff < 2⁻⁶. Run `bench_pp_tg.py` correctness section; must pass.

### SOVEREIGN — extend to o_inter (2 hr)

Same pattern as d-compute with different operand sources (`s_Q` instead of `s_w`, output multiplied by `expf(cs[c])`). Re-verify.

### SOVEREIGN — state update (4-6 hr)

The trickiest one. Two warps cooperate on M=32 split as two M=16 tiles. Each warp produces 8 N-tiles of f32 accumulator, then writes back to `s_state_f32` after multiplying by `s_decay_total` and adding the existing state value. K=8 → pad to 16 with zero-fill in `s_K_bf16` rows 8-15 (caller of WMMA must zero those rows). Then refresh `s_state_bf16` mirror.

Pseudocode:
```cpp
// d_scaled is column of M (J_per=32). K is column of K (Dk=128).
// We want: state[j, i] = γ·state[j, i] + Σ_c d_scaled[c, j] * K[c, i]
//
// Reframe as GEMM: state(M=32, N=128) += d_scaled.T(M=32, K=8) @ K(K=8, N=128)
// d_scaled.T means we transpose-on-load: WMMA matrix_a with col_major.

fragment<matrix_a, 16, 16, 16, __nv_bfloat16, col_major> a_dT;  // [J_per_tile=16][K_pad=16]
fragment<matrix_b, 16, 16, 16, __nv_bfloat16, row_major> b_K;   // [K_pad=16][N_tile=16]
fragment<accumulator, 16, 16, 16, float>                  c_st;

if (warp_id < 2) {
    int j_tile = warp_id;  // 0 or 1, covers j_start+[0..16) or +[16..32)
    for (int n_tile = 0; n_tile < 8; n_tile++) {
        // Load existing state slice into accumulator fragment, scaled by γ
        load_matrix_sync(c_st, s_state_f32 + j_tile*16*DK_S + n_tile*16, DK_S, mem_row_major);
        scale_fragment(c_st, s_decay_total);                             // helper
        load_matrix_sync(a_dT, s_d_bf16 + j_tile*16, J_per);             // C-major as transpose
        load_matrix_sync(b_K, s_K_bf16 + n_tile*16, DK_S);
        mma_sync(c_st, a_dT, b_K, c_st);
        store_matrix_sync(s_state_f32 + j_tile*16*DK_S + n_tile*16, c_st, DK_S, mem_row_major);
    }
}
__syncthreads();
// Refresh s_state_bf16 mirror for next chunk.
```

`d_scaled` needs to be available as bf16 too (it's currently f32 from the d-compute store). So SOVEREIGN's d-compute should write *both* an f32 copy (for o_intra still scalar) and a bf16 copy. Tradeoff: ~256 extra cvts per chunk per block, negligible.

### SOVEREIGN — relax `__launch_bounds__` (1 hr)

After the kernel rewrite, register pressure should drop (matmul work is in fragments, not in 32×scalar accumulators). Try `__launch_bounds__(128, 2)` then `(128, 4)`. Re-profile occupancy.

### SOVEREIGN — `cp.async` pipelining (4-6 hr, optional)

If profiler shows smem-load stalls dominate after Phases 2-5, overlap the next-chunk loads with the current-chunk WMMA via `__pipeline_memcpy_async` + double-buffered smem. Doubles the staging buffer cost (`s_w_bf16`, `s_Q_bf16`, `s_K_bf16` × 2) but should hide ~80% of load latency.

This is the highest-risk phase — easy to get pipeline barriers wrong. Skip if Phases 2-5 already get us to ~30% improvement target.

### SOVEREIGN — extend to phase1 (deferred)

Phase1 is 2.0% of CUDA time per the profile. Even a 5x speedup buys 1.6%. Defer.

---

## Verification harness

1. **Bit-level**: compile both `pf_dn_chunk_phase2_scalar` (existing) and `pf_dn_chunk_phase2_wmma` (new) into the same .so. Add a debug Python entrypoint that runs both on identical inputs and reports `max_abs(diff)` and `max_rel(diff)` for every output element. Tolerance: 2⁻⁶ relative.

2. **Token-level**: `bench_pp_tg.py` correctness section already runs an end-to-end prompt and asserts the predicted token. Extend with a fixed corpus of 50 prompts × 32 generated tokens each. Build the baseline corpus from current main; assert byte-equal token IDs from the new kernel. (Allow optional `--tolerate=N` mismatches as a release gate if precision drift turns out to be model-dependent.)

3. **Performance**: rerun `diag_prefill_kernels.py` after each phase. Track `pf_dn_chunk_phase2_*` self-CUDA time in a CSV. SOVEREIGN alone target: -25% on this kernel. After SOVEREIGN: -50%. After SOVEREIGN+6: -65%.

4. **Bench matrix**: pp520 across 5 fixed prompt lengths {64, 128, 256, 512} × 3 batches each. Avoid n_gen variability by measuring prefill only.

---

## Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| bf16 precision drift breaks logits parity | Med | High — visible token-level differences | Bit-level tolerance harness in SOVEREIGN catches early; if intolerable, try TF32 m16n16k8 fragments at 0.5x throughput |
| Fragment storage convention mismatches (row vs col) cause silent wrong results | High | High | SOVEREIGN has explicit bit comparison against scalar; resolve before extending |
| Register spills under WMMA + 4 warps × 2 blocks/SM | Med | Med | `nvcc -Xptxas -v` after each phase; if spills appear, fall back to (128, 1) |
| smem mirror refresh introduces a new sync that hurts more than it saves | Low | Med | Bench SOVEREIGN in isolation; if regression, restructure to write bf16 directly from the cvt |
| Bank conflicts on bf16 stride 129 (different than f32 stride 129) | Low | Med | bf16 is 2-byte; 129 elements = 258 bytes. 32 banks × 4 bytes = 128 bytes = 64 bf16. Stride 129 ≠ multiple of 64 — already conflict-free. Verify via `__profile_*` smem counters. |
| Hardware variation: maybe RTX 3090 isn't the right test bed (downclocking, thermals) | Low | Low | Lock clocks via `nvidia-smi -lgc 2100` during bench; rerun before/after each phase |
| Real bottleneck turns out to be elsewhere (sync overhead, kernel launch cost) | Med | Med — caps the speedup | SOVEREIGN's CUPTI metrics should reveal this before we commit to SOVEREIGN-6. If launch overhead dominates, the answer is fewer launches (graph capture or megakernel-on-Ampere), not WMMA |

---

## Estimated timeline

| Phase | Optimistic | Realistic | Pessimistic | Cumulative |
|---|---|---|---|---|
| 0. Preconditions | 1 h | 2 h | 4 h | 4 h |
| 1. Instrumentation + corpus | 2 h | 4 h | 6 h | 10 h |
| 2. d compute WMMA | 3 h | 6 h | 12 h | 22 h |
| 3. o_inter WMMA | 2 h | 3 h | 6 h | 28 h |
| 4. state update WMMA | 4 h | 8 h | 14 h | 42 h |
| 5. launch_bounds tuning | 1 h | 2 h | 4 h | 46 h |
| 6. cp.async (optional) | 4 h | 8 h | 16 h | 62 h |
| Bench/QA/PR | 2 h | 4 h | 8 h | 70 h |

Realistic: **~7 working days** (1.5 weeks at 5 h/day). Optimistic 19 h / 2.5 days, pessimistic 70 h / 2 weeks.

## Expected payoff

Bottoming-up from the 13.27 ms phase2 budget:
- Pure compute fraction (rough): if 60% of phase2 is matmul work and we get 4-8x on it via WMMA, that's `13.27 × 0.6 × (1 - 1/6) = 6.6 ms saved` → phase2 → ~6.7 ms, total prefill 21 ms → **~24,400 tok/s for 512 tokens**.
- After cp.async overlap of remaining smem loads: phase2 → ~4.5 ms, total 19 ms → **~27,000 tok/s**.
- Both well below the README's 37,800 tok/s claim. Confirms that WMMA alone won't close the gap; further work would be on phase1 (2%), kernel launch fusion (graph capture / persistent kernel — back to mega), or revisiting whether the README figure is accurate for stock sm_86.

**Conservative success bar**: ≥30% prefill speedup (target: 23k tok/s) with token-level parity to ≤1 mismatch per 50-prompt corpus.

---

## Open questions to resolve in SOVEREIGN

1. What's the exact CUPTI breakdown of phase2 (compute / memory / sync)? Determines whether WMMA or `cp.async` is the primary lever.
2. Is the global memory load of `state` (32×129 f32 = 16.5 KB / chunk start, only once) actually a hot path, or is most of the 13.27 ms in the inter-chunk smem operations?
3. Does the existing kernel benefit from `__launch_bounds__(128, 2)` even without the WMMA rewrite? Quick experiment in SOVEREIGN; if it does, that's a free 5-10% before any rewrite.
4. Is the 37,800 README figure reproducible at all on this 3090, or was it from a non-stock setup (overclocked, different chip bin, different driver)? Worth one ping to davide221 before committing two weeks of work.
