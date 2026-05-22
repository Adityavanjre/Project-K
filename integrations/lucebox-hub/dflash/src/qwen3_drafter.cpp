// Qwen3-0.6B drafter for pflash speculative prefill, hosted in-process.
//
// Wires three pieces:
//   - qwen3_0p6b_loader.cpp : mmap GGUF + populate ggml tensors on backend
//   - qwen3_0p6b_graph.cpp  : custom forward (per-layer ggml + FP CUDA kernel)
//   - chunk-top-K + span merge (this file)
//
// Single-pass forward at full S using a custom Qwen3-0.6B graph with the
// FlashPrefill block-sparse attention kernel (or BSA when enabled). Tail
// attention scoring runs in a separate post-forward graph using saved Q_last
// and K_curr per layer.
//
// Result running_max [n_lookahead, S] f32 is reduced to per-token scores via
// mean-over-lookahead, smoothed with AvgPool, scored per chunk, top-K kept.

#include "qwen3_drafter.h"
#include "qwen3_0p6b_drafter.h"
#include "internal.h"

#include "ggml.h"
#include "ggml-backend.h"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstdio>
#include <cstring>
#include <vector>

namespace dflash27b {

bool load_drafter(const std::string & gguf_path, int /*gpu_layers*/,
                  DrafterContext & out) {
    if (out.loaded) {
        set_last_error("drafter already loaded");
        return false;
    }

    // If caller didn't supply a backend, spin up our own CUDA one. Sharing
    // would be ideal but we don't have a handle to the daemon's backend
    // through this API. Same-process CUDA pools coexist fine — fragmentation
    // is the only cost, and we free everything in free_drafter.
    if (!out.backend) {
        size_t n_dev = ggml_backend_dev_count();
        for (size_t i = 0; i < n_dev; ++i) {
            ggml_backend_dev_t dev = ggml_backend_dev_get(i);
            if (ggml_backend_dev_type(dev) == GGML_BACKEND_DEVICE_TYPE_GPU) {
                out.backend = ggml_backend_dev_init(dev, nullptr);
                break;
            }
        }
        if (!out.backend) {
            set_last_error("load_drafter: no GPU backend available");
            return false;
        }
    }

    if (!load_qwen3_0p6b_drafter(gguf_path, out.backend, out.weights)) {
        // last_error already set by loader
        return false;
    }

    out.loaded = true;
    std::fprintf(stderr,
        "[drafter] loaded Qwen3-0.6B BF16: n_layer=%d n_head=%d n_kv=%d "
        "n_embd=%d n_ff=%d head_dim=%d vocab=%d\n",
        out.weights.n_layer, out.weights.n_head, out.weights.n_head_kv,
        out.weights.n_embd, out.weights.n_ff, out.weights.head_dim,
        out.weights.n_vocab);
    std::fflush(stderr);
    return true;
}

void free_drafter(DrafterContext & ctx) {
    if (ctx.loaded) {
        free_qwen3_0p6b_drafter(ctx.weights);
    }
    if (ctx.backend) {
        ggml_backend_free(ctx.backend);
        ctx.backend = nullptr;
    }
    ctx.loaded = false;
}

std::vector<int32_t> drafter_score_and_compress(
    DrafterContext & ctx,
    const std::vector<int32_t> & ids,
    float keep_ratio,
    int chunk_size,
    int n_lookahead,
    int pool_kernel) {
    if (!ctx.loaded) {
        set_last_error("drafter not loaded");
        return {};
    }
    const int S = (int)ids.size();
    if (S < n_lookahead + 1) {
        // Too short to score — return as-is.
        return ids;
    }

    // ── 1. Custom forward + GPU tail-attention scoring ────────────────
    auto t0 = std::chrono::steady_clock::now();
    std::vector<float> running_max;
    if (!forward_qwen3_0p6b_drafter(ctx.weights, ids, n_lookahead, running_max)) {
        return {};
    }
    auto t1 = std::chrono::steady_clock::now();
    std::fprintf(stderr, "[drafter] forward+score in %.2fs S=%d\n",
        std::chrono::duration<double>(t1 - t0).count(), S);
    std::fflush(stderr);

    // ── 2. Mean over lookahead → per-token score [S] ──────────────────
    std::vector<float> score((size_t)S, 0.0f);
    for (int j = 0; j < S; ++j) {
        float s = 0.0f;
        for (int t = 0; t < n_lookahead; ++t) {
            s += running_max[(size_t)t * S + j];
        }
        score[j] = s / (float)n_lookahead;
    }

    // ── 3. AvgPool 1D smoothing ───────────────────────────────────────
    std::vector<float> smooth((size_t)S, 0.0f);
    int half = pool_kernel / 2;
    for (int j = 0; j < S; ++j) {
        int lo = std::max(0, j - half);
        int hi = std::min(S - 1, j + half);
        float s = 0.0f;
        int n = 0;
        for (int k = lo; k <= hi; ++k) { s += score[k]; ++n; }
        smooth[j] = (n > 0) ? (s / (float)n) : 0.0f;
    }

    // ── 4. Chunk-top-K + span merge ───────────────────────────────────
    int n_chunks = (S + chunk_size - 1) / chunk_size;
    int n_keep   = std::max(1, (int)((float)n_chunks * keep_ratio));
    std::vector<std::pair<float, int>> chunk_means;
    chunk_means.reserve((size_t)n_chunks);
    for (int c = 0; c < n_chunks; ++c) {
        int s_ = c * chunk_size;
        int e_ = std::min(S, (c + 1) * chunk_size);
        float m = 0.0f;
        for (int j = s_; j < e_; ++j) m += smooth[j];
        m /= std::max(1, e_ - s_);
        chunk_means.push_back({m, c});
    }
    std::partial_sort(chunk_means.begin(),
                      chunk_means.begin() + n_keep,
                      chunk_means.end(),
                      [](auto a, auto b) { return a.first > b.first; });
    std::vector<int> selected;
    selected.reserve((size_t)n_keep);
    for (int i = 0; i < n_keep; ++i) selected.push_back(chunk_means[i].second);
    std::sort(selected.begin(), selected.end());

    std::vector<int32_t> out;
    out.reserve((size_t)n_keep * chunk_size + 16);
    int span_start = -1, span_end = -1;
    for (int c : selected) {
        int s_ = c * chunk_size;
        int e_ = std::min(S, (c + 1) * chunk_size);
        if (span_start < 0) {
            span_start = s_; span_end = e_;
        } else if (s_ == span_end) {
            span_end = e_;
        } else {
            for (int j = span_start; j < span_end; ++j) out.push_back(ids[j]);
            span_start = s_; span_end = e_;
        }
    }
    if (span_start >= 0) {
        for (int j = span_start; j < span_end; ++j) out.push_back(ids[j]);
    }

    auto t2 = std::chrono::steady_clock::now();
    std::fprintf(stderr,
        "[drafter] score_and_compress total %.2fs S=%d kept=%zu (%d/%d chunks)\n",
        std::chrono::duration<double>(t2 - t0).count(),
        S, out.size(), n_keep, n_chunks);
    std::fflush(stderr);

    return out;
}

} // namespace dflash27b
