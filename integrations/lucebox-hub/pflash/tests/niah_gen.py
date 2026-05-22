"""Generate NIAH single-needle test cases at any context size."""
import argparse, json, random
from transformers import AutoTokenizer

FILLER = ("The grass is green. The sky is blue. The sun is yellow. "
          "Here we go. There and back again. ")
NEEDLE_TMPL = "The special magic {key} number is: {value}."
QUESTION_TMPL = "What is the special magic {key} number? Answer in one short sentence."


def gen_one(seed: int, target_tokens: int, tokenizer):
    rng = random.Random(seed)
    key = "".join(rng.choices("abcdefghijklmnopqrstuvwxyz", k=8))
    value = "".join(rng.choices("0123456789", k=7))
    needle = NEEDLE_TMPL.format(key=key, value=value)
    question = QUESTION_TMPL.format(key=key)
    char_per_tok = 4.0  # rough
    target_chars = int(target_tokens * char_per_tok)
    filler = (FILLER * (target_chars // len(FILLER) + 1))[:target_chars]
    insert = rng.randint(target_chars // 4, 3 * target_chars // 4)
    body = filler[:insert] + " " + needle + " " + filler[insert:]
    prompt = (
        "Below is a long passage. Answer the question at the end based ONLY on information in the passage.\n\n"
        f"{body}\n\nQuestion: {question}\nAnswer:"
    )
    return {"prompt": prompt, "answer": value, "key": key}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--n", type=int, default=10)
    ap.add_argument("--ctx", type=int, default=8192)
    ap.add_argument("--out", required=True)
    ap.add_argument("--tokenizer", default="Qwen/Qwen3.6-27B")
    args = ap.parse_args()
    tok = AutoTokenizer.from_pretrained(args.tokenizer)
    with open(args.out, "w") as f:
        for i in range(args.n):
            ex = gen_one(seed=42 + i, target_tokens=args.ctx, tokenizer=tok)
            # plain encode keeps the bench harness torch-free; pyproject only
            # depends on transformers + tokenizers.
            ex["n_tokens"] = len(tok.encode(ex["prompt"]))
            f.write(json.dumps(ex) + "\n")
            print(f"  case {i}: ntok={ex['n_tokens']} key={ex['key']} ans={ex['answer']}")
    print(f"saved {args.n} cases to {args.out}")


if __name__ == "__main__":
    main()
