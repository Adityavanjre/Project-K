"""
OpenAI-compatible HTTP server on top of test_dflash.

    pip install fastapi uvicorn transformers
    python3 scripts/server.py                 # serves on :8000

    curl http://localhost:8000/v1/chat/completions \\
        -H 'Content-Type: application/json' \\
        -d '{"model":"luce-dflash","messages":[{"role":"user","content":"hi"}],"stream":true}'

Drop-in for Open WebUI / LM Studio / Cline by setting
  OPENAI_API_BASE=http://localhost:8000/v1  OPENAI_API_KEY=sk-any

Streams tokens as Server-Sent Events using the OpenAI delta format.
Model reloads per request (~10 s first-token latency). A daemon-mode
binary that keeps the model resident is a planned follow-up.
"""
import argparse
import json
import os
import struct
import subprocess
import sys
import tempfile
import time
import uuid
from pathlib import Path
from typing import AsyncIterator

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse, StreamingResponse
from pydantic import BaseModel
from starlette.concurrency import iterate_in_threadpool
from transformers import AutoTokenizer

from _prefill_hook import (
    PrefillConfig, add_cli_flags, config_from_args,
    compress_text_via_daemon,
)


ROOT = Path(__file__).resolve().parent.parent
DEFAULT_TARGET = Path(os.environ.get(
    "DFLASH_TARGET",
    str(ROOT / "models" / "Qwen3.6-27B-Q4_K_M.gguf"),
))
DEFAULT_DRAFT_ROOT = ROOT / "models" / "draft"
DEFAULT_BIN = ROOT / "build" / ("test_dflash" + (".exe" if sys.platform == "win32" else ""))
DEFAULT_BUDGET = 22
MODEL_NAME = "luce-dflash"


def resolve_draft(root: Path) -> Path:
    for st in root.rglob("model.safetensors"):
        return st
    raise FileNotFoundError(f"no model.safetensors under {root}")


# Models known to share the qwen35 GGUF arch + vocab. Verified via
# tokenizer.ggml.pre == "qwen35" and identical eos/pad/bos token IDs.
_QWEN35_FAMILY_TOKENIZERS = {
    "Qwen3.5-27B": "Qwen/Qwen3.5-27B",
    "Qwen3.6-27B": "Qwen/Qwen3.6-27B",
}


def _tokenizer_id_from_gguf(gguf_path: Path) -> str:
    """Infer the HuggingFace tokenizer repo from a GGUF target file.

    The GGUF file encodes its own tokenizer so in principle we could use that
    directly, but `test_dflash` drives generation through the HF tokenizer for
    chat-template application. We match on `general.basename` / `general.name`
    metadata; if anything goes wrong we fall back to the historical default
    (Qwen/Qwen3.5-27B) so existing setups don't break.
    """
    default = "Qwen/Qwen3.5-27B"
    try:
        from gguf import GGUFReader  # type: ignore
        r = GGUFReader(str(gguf_path))
        for key in ("general.basename", "general.name"):
            f = r.fields.get(key)
            if f is None or not f.data:
                continue
            import numpy as np
            p = f.parts[f.data[0]]
            if not isinstance(p, np.ndarray):
                continue
            try:
                val = bytes(p).decode("utf-8", errors="replace")
            except Exception:
                continue
            for known, repo in _QWEN35_FAMILY_TOKENIZERS.items():
                if known.lower() in val.lower():
                    return repo
    except Exception:
        pass
    return default


class ChatMessage(BaseModel):
    role: str
    content: str | list[dict]


class ChatRequest(BaseModel):
    model: str = MODEL_NAME
    messages: list[ChatMessage]
    stream: bool = False
    max_tokens: int = 512
    temperature: float | None = None  # noted + ignored (greedy-only)
    top_p: float | None = None


class AnthropicMessage(BaseModel):
    role: str
    # Anthropic allows either a plain string or a list of content blocks.
    content: str | list[dict]


class AnthropicMessagesRequest(BaseModel):
    model: str = MODEL_NAME
    max_tokens: int
    messages: list[AnthropicMessage]
    system: str | list[dict] | None = None
    stream: bool = False
    temperature: float | None = None
    top_p: float | None = None
    stop_sequences: list[str] | None = None


def build_app(target: Path, draft: Path, bin_path: Path, budget: int, max_ctx: int,
              tokenizer: AutoTokenizer, stop_ids: set[int],
              prefill_cfg: PrefillConfig | None = None,
              drafter_tokenizer: AutoTokenizer | None = None) -> FastAPI:
    import asyncio
    app = FastAPI(title="Luce DFlash OpenAI server")
    daemon_lock = asyncio.Lock()

    r_pipe, w_pipe = os.pipe()
    if sys.platform == "win32":
        import msvcrt
        os.set_inheritable(w_pipe, True)
        stream_fd_val = int(msvcrt.get_osfhandle(w_pipe))
    else:
        stream_fd_val = w_pipe

    bin_abs = str(Path(bin_path).resolve())
    dll_dir = str(Path(bin_abs).parent / "bin")
    env = {**os.environ}
    if sys.platform == "win32":
        env["PATH"] = dll_dir + os.pathsep + str(Path(bin_abs).parent) + os.pathsep + env.get("PATH", "")

    cmd = [bin_abs, str(target), str(draft), "--daemon",
           "--fast-rollback", "--ddtree", f"--ddtree-budget={budget}",
           f"--max-ctx={max_ctx}",
           f"--stream-fd={stream_fd_val}"]
    if sys.platform == "win32":
        daemon_proc = subprocess.Popen(cmd, close_fds=False, env=env,
                                       stdin=subprocess.PIPE)
    else:
        daemon_proc = subprocess.Popen(cmd, pass_fds=(w_pipe,), env=env,
                                       stdin=subprocess.PIPE)
    os.close(w_pipe)

    @app.get("/v1/models")
    def list_models():
        return {
            "object": "list",
            "data": [{"id": MODEL_NAME, "object": "model", "owned_by": "luce"}],
        }

    def _ids_to_bin(ids: list[int]) -> Path:
        # mkstemp returns (fd, path). os.fdopen() takes ownership and closes.
        fd, path = tempfile.mkstemp(suffix=".bin")
        with os.fdopen(fd, "wb") as f:
            for t in ids:
                f.write(struct.pack("<i", int(t)))
        return Path(path)

    def _render_messages(msgs_list: list[dict]) -> tuple[Path, list[int], str]:
        """Apply chat template to msgs_list and return (bin path, ids, raw prompt).

        The raw prompt is returned for spec-prefill: when compression fires we
        re-tokenise it with the drafter vocab.
        """
        prompt = tokenizer.apply_chat_template(
            msgs_list, tokenize=False, add_generation_prompt=True)
        ids = tokenizer.encode(prompt, add_special_tokens=False)
        return _ids_to_bin(ids), ids, prompt

    def _tokenize_prompt(req: ChatRequest) -> tuple[Path, list[int], list[dict]]:
        """Returns (bin path, ids, raw msgs). Does NOT yet apply prefill compression."""
        msgs = [{"role": m.role, "content": _anthropic_text_from_content(m.content)
                 if isinstance(m.content, list) else m.content}
                for m in req.messages]
        path, ids, _prompt = _render_messages(msgs)
        return path, ids, msgs

    def _maybe_compress(msgs: list[dict], prompt_bin: Path, prompt_ids: list[int]
                        ) -> tuple[Path, list[int]]:
        """Run pflash compression on the LAST user message if config + length
        thresholds say so. Returns the (possibly new) bin path + ids. Holds the
        daemon lock for the duration via the *outer* caller (callers call this
        from within ``async with daemon_lock``)."""
        if not prefill_cfg or not prefill_cfg.enabled:
            return prompt_bin, prompt_ids
        if not prefill_cfg.should_compress(len(prompt_ids)):
            return prompt_bin, prompt_ids
        if drafter_tokenizer is None:
            return prompt_bin, prompt_ids

        # Find the last user message (the long-context blob)
        last_user_idx = next((i for i in range(len(msgs) - 1, -1, -1)
                              if msgs[i]["role"] == "user"), None)
        if last_user_idx is None:
            return prompt_bin, prompt_ids
        long_text = msgs[last_user_idx]["content"]

        compressed_text = compress_text_via_daemon(
            daemon_stdin=daemon_proc.stdin,
            r_pipe=r_pipe,
            drafter_tokenizer=drafter_tokenizer,
            cfg=prefill_cfg,
            prompt_text=long_text,
        )

        new_msgs = list(msgs)
        new_msgs[last_user_idx] = {"role": "user", "content": compressed_text}
        new_bin, new_ids, _ = _render_messages(new_msgs)
        try: prompt_bin.unlink()
        except Exception: pass
        return new_bin, new_ids

    def _token_stream(r, n_gen):
        generated = 0
        hit_stop = False
        while True:
            b = os.read(r, 4)
            if not b or len(b) < 4:
                break
            tok_id = struct.unpack("<i", b)[0]
            if tok_id == -1:
                break
            if hit_stop:
                continue
            if tok_id in stop_ids:
                hit_stop = True
                continue
            generated += 1
            yield tok_id
            if generated >= n_gen:
                hit_stop = True

    @app.post("/v1/chat/completions")
    async def chat_completions(req: ChatRequest):
        prompt_bin, prompt_ids, raw_msgs = _tokenize_prompt(req)

        completion_id = "chatcmpl-" + uuid.uuid4().hex[:24]
        created = int(time.time())

        def _gen_len_for(prompt_len: int) -> int:
            return min(req.max_tokens, max_ctx - prompt_len - 20)

        if req.stream:
            async def sse() -> AsyncIterator[str]:
                async with daemon_lock:
                    cur_bin, cur_ids = await asyncio.to_thread(
                        _maybe_compress, raw_msgs, prompt_bin, prompt_ids)
                    prompt_len = len(cur_ids)
                    gen_len = _gen_len_for(prompt_len)
                    if gen_len <= 0:
                        try: cur_bin.unlink()
                        except Exception: pass
                        err = {"id": completion_id, "object": "chat.completion.chunk",
                               "created": created, "model": MODEL_NAME,
                               "choices": [{"index": 0, "delta": {},
                                            "finish_reason": "length"}]}
                        yield f"data: {json.dumps(err)}\n\n"
                        yield "data: [DONE]\n\n"
                        return
                    cmd_line = f"{cur_bin} {gen_len}\n"
                    daemon_proc.stdin.write(cmd_line.encode("utf-8"))
                    daemon_proc.stdin.flush()
                    head = {
                        "id": completion_id, "object": "chat.completion.chunk",
                        "created": created, "model": MODEL_NAME,
                        "choices": [{"index": 0,
                                      "delta": {"role": "assistant"},
                                      "finish_reason": None}],
                    }
                    yield f"data: {json.dumps(head)}\n\n"
                    try:
                        # Offload blocking os.read in _token_stream to a thread so
                        # SSE chunks flush progressively instead of after generation ends.
                        async for tok_id in iterate_in_threadpool(_token_stream(r_pipe, gen_len)):
                            chunk = {
                                "id": completion_id,
                                "object": "chat.completion.chunk",
                                "created": created, "model": MODEL_NAME,
                                "choices": [{"index": 0,
                                              "delta": {"content": tokenizer.decode([tok_id])},
                                              "finish_reason": None}],
                            }
                            yield f"data: {json.dumps(chunk)}\n\n"
                    finally:
                        try: cur_bin.unlink()
                        except Exception: pass
                    tail = {
                        "id": completion_id, "object": "chat.completion.chunk",
                        "created": created, "model": MODEL_NAME,
                        "choices": [{"index": 0, "delta": {},
                                      "finish_reason": "stop"}],
                    }
                    yield f"data: {json.dumps(tail)}\n\n"
                    yield "data: [DONE]\n\n"

            return StreamingResponse(sse(), media_type="text/event-stream")

        # Non-streaming: collect all tokens, return one response
        async with daemon_lock:
            cur_bin, cur_ids = await asyncio.to_thread(
                _maybe_compress, raw_msgs, prompt_bin, prompt_ids)
            prompt_len = len(cur_ids)
            gen_len = _gen_len_for(prompt_len)
            if gen_len <= 0:
                try: cur_bin.unlink()
                except Exception: pass
                return JSONResponse(
                    {"detail": f"Prompt length ({prompt_len}) exceeds max_ctx ({max_ctx})"},
                    status_code=400)
            cmd_line = f"{cur_bin} {gen_len}\n"
            daemon_proc.stdin.write(cmd_line.encode("utf-8"))
            daemon_proc.stdin.flush()
            tokens = list(_token_stream(r_pipe, gen_len))

        try: cur_bin.unlink()
        except Exception: pass
        text = tokenizer.decode(tokens, skip_special_tokens=True)
        return JSONResponse({
            "id": completion_id,
            "object": "chat.completion",
            "created": created,
            "model": MODEL_NAME,
            "choices": [{
                "index": 0,
                "message": {"role": "assistant", "content": text},
                "finish_reason": "stop",
            }],
            "usage": {"prompt_tokens": prompt_len,
                      "completion_tokens": len(tokens),
                      "total_tokens": prompt_len + len(tokens)},
        })

    # ── Anthropic Messages API ──────────────────────────────────────
    # Mirrors the OpenAI endpoint but formatted for the Anthropic SDK.
    # `?beta=true` (or any other query params) are accepted and ignored.

    def _anthropic_text_from_content(content) -> str:
        if isinstance(content, str):
            return content
        # list of blocks — concatenate the text blocks, ignore images/tools
        parts = []
        for b in content:
            if isinstance(b, dict) and b.get("type") == "text":
                parts.append(b.get("text", ""))
        return "".join(parts)

    def _tokenize_anthropic(req: AnthropicMessagesRequest
                            ) -> tuple[Path, list[int], list[dict]]:
        msgs = []
        system_text = _anthropic_text_from_content(req.system) if req.system else None
        if system_text:
            msgs.append({"role": "system", "content": system_text})
        for m in req.messages:
            msgs.append({"role": m.role,
                         "content": _anthropic_text_from_content(m.content)})
        path, ids, _prompt = _render_messages(msgs)
        return path, ids, msgs

    async def _astream_tokens(r, n_gen):
        """Yields one token at a time without blocking the event loop.
        Each 4-byte pipe read is dispatched to a worker thread."""
        generated = 0
        hit_stop = False
        while True:
            b = await asyncio.to_thread(os.read, r, 4)
            if not b or len(b) < 4:
                break
            tok_id = struct.unpack("<i", b)[0]
            if tok_id == -1:
                break
            if hit_stop:
                continue
            if tok_id in stop_ids:
                hit_stop = True
                continue
            generated += 1
            yield tok_id
            if generated >= n_gen:
                hit_stop = True

    @app.post("/v1/messages")
    async def anthropic_messages(req: AnthropicMessagesRequest):
        prompt_bin, prompt_ids, raw_msgs = _tokenize_anthropic(req)
        msg_id = "msg_" + uuid.uuid4().hex[:24]

        if req.stream:
            async def sse() -> AsyncIterator[str]:
                # Hold the lock across the ENTIRE read cycle so concurrent
                # requests don't interleave tokens through the shared pipe.
                async with daemon_lock:
                    cur_bin, cur_ids = await asyncio.to_thread(
                        _maybe_compress, raw_msgs, prompt_bin, prompt_ids)
                    prompt_len = len(cur_ids)
                    gen_len = min(req.max_tokens, max_ctx - prompt_len - 20)
                    if gen_len <= 0:
                        try: cur_bin.unlink()
                        except Exception: pass
                        err = {"type": "error",
                               "error": {"type": "invalid_request_error",
                                         "message": f"Prompt length ({prompt_len}) exceeds max_ctx ({max_ctx})"}}
                        yield f"event: error\ndata: {json.dumps(err)}\n\n"
                        return
                    message_start = {
                        "type": "message_start",
                        "message": {
                            "id": msg_id, "type": "message", "role": "assistant",
                            "model": req.model or MODEL_NAME,
                            "content": [], "stop_reason": None, "stop_sequence": None,
                            "usage": {"input_tokens": prompt_len, "output_tokens": 0},
                        },
                    }
                    yield f"event: message_start\ndata: {json.dumps(message_start)}\n\n"

                    cb_start = {
                        "type": "content_block_start", "index": 0,
                        "content_block": {"type": "text", "text": ""},
                    }
                    yield f"event: content_block_start\ndata: {json.dumps(cb_start)}\n\n"

                    cmd_line = f"{cur_bin} {gen_len}\n"
                    daemon_proc.stdin.write(cmd_line.encode("utf-8"))
                    daemon_proc.stdin.flush()

                    out_tokens = 0
                    try:
                        async for tok_id in _astream_tokens(r_pipe, gen_len):
                            out_tokens += 1
                            delta = {
                                "type": "content_block_delta", "index": 0,
                                "delta": {"type": "text_delta",
                                          "text": tokenizer.decode([tok_id])},
                            }
                            yield f"event: content_block_delta\ndata: {json.dumps(delta)}\n\n"
                    finally:
                        try: cur_bin.unlink()
                        except Exception: pass

                    yield f"event: content_block_stop\ndata: {json.dumps({'type': 'content_block_stop', 'index': 0})}\n\n"

                    msg_delta = {
                        "type": "message_delta",
                        "delta": {"stop_reason": "end_turn", "stop_sequence": None},
                        "usage": {"output_tokens": out_tokens},
                    }
                    yield f"event: message_delta\ndata: {json.dumps(msg_delta)}\n\n"
                    yield f"event: message_stop\ndata: {json.dumps({'type': 'message_stop'})}\n\n"

            return StreamingResponse(sse(), media_type="text/event-stream")

        # Non-streaming
        async with daemon_lock:
            cur_bin, cur_ids = await asyncio.to_thread(
                _maybe_compress, raw_msgs, prompt_bin, prompt_ids)
            prompt_len = len(cur_ids)
            gen_len = min(req.max_tokens, max_ctx - prompt_len - 20)
            if gen_len <= 0:
                try: cur_bin.unlink()
                except Exception: pass
                return JSONResponse(
                    {"type": "error",
                     "error": {"type": "invalid_request_error",
                               "message": f"Prompt length ({prompt_len}) exceeds max_ctx ({max_ctx})"}},
                    status_code=400)
            cmd_line = f"{cur_bin} {gen_len}\n"
            daemon_proc.stdin.write(cmd_line.encode("utf-8"))
            daemon_proc.stdin.flush()
            tokens = [t async for t in _astream_tokens(r_pipe, gen_len)]

        try: cur_bin.unlink()
        except Exception: pass
        text = tokenizer.decode(tokens, skip_special_tokens=True)
        return JSONResponse({
            "id": msg_id,
            "type": "message",
            "role": "assistant",
            "model": req.model or MODEL_NAME,
            "content": [{"type": "text", "text": text}],
            "stop_reason": "end_turn",
            "stop_sequence": None,
            "usage": {"input_tokens": prompt_len,
                      "output_tokens": len(tokens)},
        })

    return app


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--host", default="0.0.0.0")
    ap.add_argument("--port", type=int, default=8080)
    ap.add_argument("--target", type=Path, default=DEFAULT_TARGET)
    ap.add_argument("--draft",  type=Path, default=DEFAULT_DRAFT_ROOT)
    ap.add_argument("--bin",    type=Path, default=DEFAULT_BIN)
    ap.add_argument("--budget", type=int,  default=DEFAULT_BUDGET)
    # Attention compute currently scales with --max-ctx, not the actual
    # prompt+gen length (see https://github.com/Luce-Org/lucebox-hub/issues/10).
    # Default 16384 fits most API workloads without the 20×+ slowdown users
    # hit with --max-ctx=131072 on short requests. Bump via --max-ctx if you
    # actually need long-context serving.
    default_ctx = 16384
    ap.add_argument("--max-ctx", type=int, default=default_ctx,
                    help=f"Maximum context length (default: {default_ctx}; "
                         "oversizing this — e.g. 131072 on short prompts — "
                         "can slow attention 20×+ until issue #10 is fixed)")
    ap.add_argument("--kv-f16", action="store_true",
                    help="Force F16 KV cache. When --max-ctx > 6144 the server "
                         "auto-enables TQ3_0 KV to fit; pass --kv-f16 to opt out.")
    ap.add_argument("--cache-type-k", "--ctk", dest="cache_type_k", default=None,
                    choices=["f16","bf16","q4_0","q4_1","q5_0","q5_1","q8_0","tq3_0"],
                    help="K cache element type (overrides --kv-q4/--kv-tq3/--kv-f16 for K). "
                         "See kv_quant.cpp for supported (K,V) pairs.")
    ap.add_argument("--cache-type-v", "--ctv", dest="cache_type_v", default=None,
                    choices=["f16","bf16","q4_0","q4_1","q5_0","q5_1","q8_0","tq3_0"],
                    help="V cache element type (overrides --kv-q4/--kv-tq3/--kv-f16 for V).")
    ap.add_argument("--fa-window", type=int, default=None,
                    help="Sliding window for FA layers (KV positions). 0 = full "
                         "attention. Default 2048 (set in C++); only kicks in "
                         "once kv_cache > window. Trades attention range for "
                         "long-context decode speed.")
    ap.add_argument("--tokenizer", type=str, default=None,
                    help="HuggingFace tokenizer repo ID (default: auto-detect "
                         "from target GGUF basename; falls back to Qwen/Qwen3.5-27B)")
    ap.add_argument("--daemon", action="store_true", help="Run with persistent model daemon (now default)")
    add_cli_flags(ap)
    args = ap.parse_args()
    prefill_cfg = config_from_args(args)

    # Auto-enable TQ3_0 KV cache when the requested context exceeds what F16 fits.
    # Clients like Claude Code routinely send 10k+ token system prompts, so
    # 6144 is too tight for real-world use. setdefault so an explicit user
    # DFLASH27B_KV_TQ3=0 still wins.
    if args.cache_type_k:
        os.environ["DFLASH27B_KV_K"] = args.cache_type_k
    if args.cache_type_v:
        os.environ["DFLASH27B_KV_V"] = args.cache_type_v
    if args.max_ctx > 6144 and not args.kv_f16 and not args.cache_type_k and not args.cache_type_v:
        os.environ.setdefault("DFLASH27B_KV_TQ3", "1")

    if args.fa_window is not None:
        os.environ["DFLASH27B_FA_WINDOW"] = str(args.fa_window)

    # When pflash is on, the daemon needs the same memory-tight env the bench
    # harness uses (otherwise the LM-head dequant buffer fragments cudaMalloc
    # after the compress dance and the post-compress draft graph reserve
    # OOMs). setdefault so explicit user overrides still win.
    if args.prefill_compression != "off":
        os.environ.setdefault("DFLASH27B_LM_HEAD_FIX", "0")
        os.environ.setdefault("DFLASH27B_FA_WINDOW", "0")

    if not args.bin.is_file():
        raise SystemExit(f"binary not found at {args.bin}")
    if not args.target.is_file():
        raise SystemExit(f"target GGUF not found at {args.target}")
    draft = resolve_draft(args.draft) if args.draft.is_dir() else args.draft
    if not draft.is_file():
        raise SystemExit(f"draft safetensors not found at {args.draft}")

    tokenizer_id = args.tokenizer or _tokenizer_id_from_gguf(args.target)
    tokenizer = AutoTokenizer.from_pretrained(tokenizer_id, trust_remote_code=True)
    stop_ids = set()
    for s in ("<|im_end|>", "<|endoftext|>"):
        ids = tokenizer.encode(s, add_special_tokens=False)
        if ids: stop_ids.add(ids[0])

    drafter_tokenizer = None
    if prefill_cfg.enabled:
        drafter_tokenizer = AutoTokenizer.from_pretrained(
            prefill_cfg.drafter_tokenizer_id, trust_remote_code=True)

    app = build_app(args.target, draft, args.bin, args.budget, args.max_ctx,
                    tokenizer, stop_ids,
                    prefill_cfg=prefill_cfg if prefill_cfg.enabled else None,
                    drafter_tokenizer=drafter_tokenizer)

    import uvicorn
    print(f"Luce DFlash OpenAI server on http://{args.host}:{args.port}")
    print(f"  target    = {args.target}")
    print(f"  draft     = {draft}")
    print(f"  bin       = {args.bin}")
    print(f"  budget    = {args.budget}")
    print(f"  max_ctx   = {args.max_ctx}")
    print(f"  tokenizer = {tokenizer_id}")
    if prefill_cfg.enabled:
        print(f"  pflash    = {prefill_cfg.mode} · threshold={prefill_cfg.threshold} "
              f"keep={prefill_cfg.keep_ratio} drafter={prefill_cfg.drafter_gguf}")
    else:
        print("  pflash    = off")
    uvicorn.run(app, host=args.host, port=args.port, log_level="info")


if __name__ == "__main__":
    main()
