import time
"""C++-only NIAH bench: daemon compress + generate, no Python drafter."""
import argparse, json, sys, time, os
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from transformers import AutoTokenizer
from pflash.dflash_client import DflashClient


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--cases", required=True)
    ap.add_argument("--n", type=int, default=1)
    ap.add_argument("--bin", default="/home/lucebox/lucebox-hub/dflash/build/test_dflash")
    ap.add_argument("--target", default="/opt/lucebox/models/Qwen3.6-27B-Q4_K_M.gguf")
    ap.add_argument("--draft-spec", default="/home/lucebox/lucebox-hub/dflash/models/draft/model.safetensors",
                    help="draft model used for spec decoding (NOT drafter scorer)")
    ap.add_argument("--drafter-gguf", default="/home/lucebox/lucebox-hub/dflash/models/Qwen3-0.6B-BF16.gguf",
                    help="C++ drafter scorer GGUF (Qwen3-0.6B BF16)")
    ap.add_argument("--target-tokenizer", default="Qwen/Qwen3.6-27B")
    ap.add_argument("--drafter-tokenizer", default="Qwen/Qwen3-0.6B")
    ap.add_argument("--max-ctx", type=int, default=16384,
                    help="daemon KV cache max ctx; sized for compressed prompt+gen, NOT source")
    ap.add_argument("--keep-ratio", type=float, default=0.020)
    ap.add_argument("--n-gen", type=int, default=64)
    args = ap.parse_args()

    target_tok = AutoTokenizer.from_pretrained(args.target_tokenizer)
    drafter_tok = AutoTokenizer.from_pretrained(args.drafter_tokenizer)
    cases = [json.loads(l) for l in open(args.cases)][:args.n]

    print(f"[init] spawning daemon: {args.bin}", flush=True)
    dflash = DflashClient(args.bin, args.target, args.draft_spec, max_ctx=args.max_ctx)

    correct = 0
    for i, case in enumerate(cases):
        prompt = case["prompt"]
        # Drafter tokenizes prompt, daemon scores+compresses, returns drafter ids.
        ids = drafter_tok(prompt, return_tensors="pt")["input_ids"][0].tolist()
        S = len(ids)
        print(f"[case {i}] src={S} keep={args.keep_ratio}", flush=True)

        t0 = time.time()
        compressed_ids = dflash.compress(ids, args.keep_ratio, args.drafter_gguf)
        t_score = time.time() - t0
        comp = len(compressed_ids)
        print(f"[case {i}] compressed={comp} ratio={S/max(comp,1):.1f}x score_s={t_score:.1f}", flush=True)

        # Decode compressed ids with DRAFTER tokenizer, re-encode with TARGET + chat template.
        comp_text = drafter_tok.decode(compressed_ids, skip_special_tokens=True)
        user_msg = comp_text + "\n\nAnswer the user question based on the above context."
        chat = target_tok.apply_chat_template(
            [{"role": "user", "content": user_msg}],
            tokenize=False, add_generation_prompt=True)
        target_ids = target_tok(chat, return_tensors="pt")["input_ids"][0].tolist()

        # Free drafter (1.2GB), restore target+spec_draft for target gen.
        dflash.free_drafter()
        dflash.unpark_target()
        dflash.unpark_draft()

        t0 = time.time()
        out_ids = dflash.generate(target_ids, args.n_gen)
        t_gen = time.time() - t0
        # Re-park for next iter (drafter scoring).
        dflash.park_draft()
        print(f"[case {i}] raw out_ids ({len(out_ids)}): {out_ids[:20]}", flush=True)
        out_text = target_tok.decode(out_ids, skip_special_tokens=True)
        out_text_keep = target_tok.decode(out_ids, skip_special_tokens=False)
        print(f"[case {i}] out_with_special: {out_text_keep!r}", flush=True)

        ok = case["answer"] in out_text
        if ok:
            correct += 1
        ttft = t_score + t_gen  # rough; gen includes ttft
        print(f"[case {i}] gen_s={t_gen:.1f} ttft={ttft:.1f} ok={ok} ans={case['answer']}", flush=True)
        print(f"[case {i}] out: {out_text!r}", flush=True)

    print(f"\naccuracy: {correct}/{len(cases)}", flush=True)
    dflash.close()


if __name__ == "__main__":
    main()
