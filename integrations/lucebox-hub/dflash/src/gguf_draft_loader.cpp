// Loads a DFlash draft model from a GGUF file on disk into a ggml context
// on the CUDA backend.
//
// This is the Q8_0-quantized counterpart of safetensors_draft.cpp. The draft
// graph builder (qwen3_dflash_graph.cpp) doesn't care about tensor storage
// types — ggml's ggml_mul_mat handles Q8_0 × F32 dequantization transparently.
//
// GGUF arch: "qwen35-dflash-draft" (from convert_dflash_to_gguf.py /
// quantize_draft_q8.py). Tensor naming convention:
//
//   dflash.fc.weight                        [5*hidden, hidden]  Q8_0 / F16
//   dflash.hidden_norm.weight               [hidden]            F32
//   output_norm.weight                      [hidden]            F32
//   blk.<i>.attn_norm.weight                [hidden]            F32
//   blk.<i>.ffn_norm.weight                 [hidden]            F32
//   blk.<i>.attn_q.weight                   [q_dim, hidden]     Q8_0 / F16
//   blk.<i>.attn_k.weight                   [kv_dim, hidden]    Q8_0 / F16
//   blk.<i>.attn_v.weight                   [kv_dim, hidden]    Q8_0 / F16
//   blk.<i>.attn_output.weight              [hidden, q_dim]     Q8_0 / F16
//   blk.<i>.attn_q_norm.weight              [head_dim]          F32
//   blk.<i>.attn_k_norm.weight              [head_dim]          F32
//   blk.<i>.ffn_gate.weight                 [intermediate, hidden]  Q8_0 / F16
//   blk.<i>.ffn_up.weight                   [intermediate, hidden]  Q8_0 / F16
//   blk.<i>.ffn_down.weight                 [hidden, intermediate]  Q8_0 / F16

#include "internal.h"

#include <cinttypes>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <string>

#if !defined(_WIN32)
#include <cerrno>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>
#endif

namespace dflash27b {

namespace {

struct Mmap {
    void *  addr = nullptr;
    size_t  len  = 0;
#if defined(_WIN32)
    HANDLE  hFile = INVALID_HANDLE_VALUE;
    HANDLE  hMap  = nullptr;
#else
    int     fd   = -1;
#endif

    bool open_ro(const std::string & path, std::string & err) {
#if defined(_WIN32)
        hFile = CreateFileA(path.c_str(), GENERIC_READ, FILE_SHARE_READ,
                            nullptr, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
        if (hFile == INVALID_HANDLE_VALUE) {
            err = "CreateFileA: " + path + ": error " + std::to_string(GetLastError());
            return false;
        }
        LARGE_INTEGER sz;
        if (!GetFileSizeEx(hFile, &sz)) {
            err = "GetFileSizeEx: error " + std::to_string(GetLastError());
            return false;
        }
        len = (size_t)sz.QuadPart;
        hMap = CreateFileMappingA(hFile, nullptr, PAGE_READONLY, 0, 0, nullptr);
        if (!hMap) {
            err = "CreateFileMappingA: error " + std::to_string(GetLastError());
            return false;
        }
        addr = MapViewOfFile(hMap, FILE_MAP_READ, 0, 0, 0);
        if (!addr) {
            err = "MapViewOfFile: error " + std::to_string(GetLastError());
            return false;
        }
#else
        fd = ::open(path.c_str(), O_RDONLY);
        if (fd < 0) { err = "open: " + path + ": " + std::strerror(errno); return false; }
        struct stat st;
        if (::fstat(fd, &st) < 0) { err = "fstat: " + std::string(std::strerror(errno)); return false; }
        len = (size_t)st.st_size;
        addr = ::mmap(nullptr, len, PROT_READ, MAP_PRIVATE, fd, 0);
        if (addr == MAP_FAILED) { err = "mmap: " + std::string(std::strerror(errno)); addr = nullptr; return false; }
#endif
        return true;
    }
    ~Mmap() {
#if defined(_WIN32)
        if (addr)                        UnmapViewOfFile(addr);
        if (hMap)                        CloseHandle(hMap);
        if (hFile != INVALID_HANDLE_VALUE) CloseHandle(hFile);
#else
        if (addr) ::munmap(addr, len);
        if (fd >= 0) ::close(fd);
#endif
    }
};

uint32_t get_u32_or(const gguf_context * g, const char * key, uint32_t fallback) {
    int64_t id = gguf_find_key(g, key);
    if (id < 0) return fallback;
    return gguf_get_val_u32(g, id);
}

} // namespace

bool load_draft_gguf(const std::string & path,
                     ggml_backend_t       backend,
                     DraftWeights &       out) {

    // ── 1. Parse metadata + create ggml_context with tensor descriptors ──
    ggml_context * meta_ctx = nullptr;
    gguf_init_params gip{};
    gip.no_alloc = true;
    gip.ctx      = &meta_ctx;
    gguf_context * gctx = gguf_init_from_file(path.c_str(), gip);
    if (!gctx) {
        set_last_error("gguf_init_from_file failed: " + path);
        return false;
    }

    // Validate arch
    {
        int64_t arch_id = gguf_find_key(gctx, "general.architecture");
        if (arch_id < 0) {
            set_last_error("missing general.architecture in draft GGUF");
            gguf_free(gctx);
            return false;
        }
        const char * arch = gguf_get_val_str(gctx, arch_id);
        if (std::string(arch) != "qwen35-dflash-draft") {
            set_last_error(std::string("unexpected draft arch: ") + arch +
                           " (expected qwen35-dflash-draft)");
            gguf_free(gctx);
            return false;
        }
    }

    // Validate dimensions that the graph builder hardcodes
    const char * A = "qwen35-dflash-draft";
    char key[128];

    auto check_u32 = [&](const char * suffix, uint32_t expected) -> bool {
        std::snprintf(key, sizeof(key), "%s.%s", A, suffix);
        uint32_t v = get_u32_or(gctx, key, 0);
        if (v != expected) {
            char b[256];
            std::snprintf(b, sizeof(b), "draft GGUF: %s=%u expected %u", key, v, expected);
            set_last_error(b);
            return false;
        }
        return true;
    };

    bool ok = true;
    ok = ok && check_u32("embedding_length",        DFLASH27B_TARGET_HIDDEN);
    ok = ok && check_u32("block_count",             DFLASH27B_DRAFT_LAYERS);
    ok = ok && check_u32("feed_forward_length",     DFLASH27B_TARGET_INTERMEDIATE);
    ok = ok && check_u32("attention.head_count",    DFLASH27B_TARGET_N_HEADS);
    ok = ok && check_u32("attention.head_count_kv", DFLASH27B_TARGET_N_KV_HEADS);
    ok = ok && check_u32("attention.key_length",    DFLASH27B_TARGET_HEAD_DIM);
    ok = ok && check_u32("attention.value_length",  DFLASH27B_TARGET_HEAD_DIM);
    ok = ok && check_u32("dflash.block_size",       DFLASH27B_DRAFT_BLOCK_SIZE);
    ok = ok && check_u32("dflash.n_target_layers",  DFLASH27B_DRAFT_N_TARGET_LAYERS);
    if (!ok) {
        gguf_free(gctx);
        return false;
    }

    // ── 2. Wire tensor pointers into DraftWeights ────────────────────────
    out.ctx     = meta_ctx;
    out.backend = backend;
    out.layers.assign(DFLASH27B_DRAFT_LAYERS, DraftLayer{});

    auto g = [&](const char * name) -> ggml_tensor * {
        return ggml_get_tensor(meta_ctx, name);
    };

    out.fc          = g("dflash.fc.weight");
    out.hidden_norm = g("dflash.hidden_norm.weight");
    out.out_norm    = g("output_norm.weight");
    if (!out.fc || !out.hidden_norm || !out.out_norm) {
        set_last_error("draft GGUF: missing top-level tensors "
                       "(dflash.fc / dflash.hidden_norm / output_norm)");
        gguf_free(gctx);
        return false;
    }

    for (int il = 0; il < DFLASH27B_DRAFT_LAYERS; il++) {
        char name[128];
        auto fnd = [&](const char * suffix) -> ggml_tensor * {
            std::snprintf(name, sizeof(name), "blk.%d.%s", il, suffix);
            return ggml_get_tensor(meta_ctx, name);
        };
        DraftLayer & L = out.layers[il];
        L.attn_norm = fnd("attn_norm.weight");
        L.ffn_norm  = fnd("ffn_norm.weight");
        L.wq        = fnd("attn_q.weight");
        L.wk        = fnd("attn_k.weight");
        L.wv        = fnd("attn_v.weight");
        L.wo        = fnd("attn_output.weight");
        L.q_norm    = fnd("attn_q_norm.weight");
        L.k_norm    = fnd("attn_k_norm.weight");
        L.w_gate    = fnd("ffn_gate.weight");
        L.w_up      = fnd("ffn_up.weight");
        L.w_down    = fnd("ffn_down.weight");
        if (!L.attn_norm || !L.ffn_norm || !L.wq || !L.wk || !L.wv || !L.wo ||
            !L.q_norm || !L.k_norm || !L.w_gate || !L.w_up || !L.w_down) {
            char b[128];
            std::snprintf(b, sizeof(b), "draft GGUF: layer %d missing tensors", il);
            set_last_error(b);
            gguf_free(gctx);
            return false;
        }
    }

    // ── 3. Allocate CUDA buffer for all tensors ──────────────────────────
    out.buf = ggml_backend_alloc_ctx_tensors(meta_ctx, backend);
    if (!out.buf) {
        set_last_error("ggml_backend_alloc_ctx_tensors failed (draft GGUF)");
        gguf_free(gctx);
        return false;
    }

    // ── 4. mmap file and copy tensor bytes to CUDA ───────────────────────
    std::string err;
    Mmap mm;
    if (!mm.open_ro(path, err)) { set_last_error(err); gguf_free(gctx); return false; }
    const size_t data_start = gguf_get_data_offset(gctx);
    const int64_t n_tensors = gguf_get_n_tensors(gctx);

    size_t total = 0;
    for (int64_t tid = 0; tid < n_tensors; tid++) {
        const char * tname = gguf_get_tensor_name(gctx, tid);
        ggml_tensor * t = ggml_get_tensor(meta_ctx, tname);
        if (!t) continue;
        const size_t off = data_start + gguf_get_tensor_offset(gctx, tid);
        const size_t sz  = gguf_get_tensor_size(gctx, tid);
        if (off + sz > mm.len) {
            set_last_error(std::string("draft GGUF: tensor '") + tname + "' overflows file");
            gguf_free(gctx);
            return false;
        }
        ggml_backend_tensor_set(t, (const uint8_t *)mm.addr + off, 0, sz);
        total += sz;
    }

    gguf_free(gctx);

    char summary[192];
    std::snprintf(summary, sizeof(summary),
        "draft GGUF loaded: %" PRId64 " tensors, %.2f GiB on GPU",
        n_tensors, total / (1024.0 * 1024.0 * 1024.0));
    set_last_error(summary);

    return true;
}

} // namespace dflash27b
