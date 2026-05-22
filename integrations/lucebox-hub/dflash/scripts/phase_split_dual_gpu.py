#!/usr/bin/env python3
"""Run the PFlash prefill phase through a persistent CUDA daemon.

This phase-split harness is intentionally PFlash-only. It keeps the Qwen3-0.6B
PFlash drafter resident in `pflash_daemon`, optionally on a different CUDA GPU
from the later target run, and writes compressed token/text outputs plus timing
and GPU resource reports. It measures the PFlash/prefill side only; decode is
outside this harness.
"""

from __future__ import annotations

import argparse
import json
import os
import queue
import struct
import subprocess
import sys
import threading
import time
from dataclasses import asdict, dataclass
from pathlib import Path
from statistics import mean
from typing import Iterable


ROOT = Path(__file__).resolve().parent.parent


def env_path(name: str, default: Path) -> Path:
    return Path(os.environ.get(name, str(default))).expanduser()


DEFAULT_BUILD = env_path("PFLASH_PHASE_BUILD_DIR", ROOT / "build")
DEFAULT_DRAFTER = env_path("PFLASH_PHASE_DRAFTER", ROOT / "models" / "Qwen3-0.6B-BF16.gguf")
DEFAULT_TOKENIZER = os.environ.get("PFLASH_PHASE_TOKENIZER", "Qwen/Qwen3-0.6B")


def write_counted_i32(path: Path, ids: Iterable[int]) -> None:
    values = [int(x) for x in ids]
    with path.open("wb") as f:
        f.write(struct.pack("<I", len(values)))
        if values:
            f.write(struct.pack("<" + "i" * len(values), *values))


def read_stream_until_sentinel(r_fd: int) -> list[int]:
    out: list[int] = []
    while True:
        raw = os.read(r_fd, 4)
        if not raw or len(raw) < 4:
            raise RuntimeError("pflash daemon stream closed before sentinel")
        tok = struct.unpack("<i", raw)[0]
        if tok == -1:
            return out
        out.append(tok)


class ProcessLog:
    def __init__(self, path: Path) -> None:
        self.path = path
        self.queue: queue.Queue[str] = queue.Queue()
        self._file = path.open("wb")
        self._thread: threading.Thread | None = None

    def attach(self, proc: subprocess.Popen[bytes]) -> None:
        def reader() -> None:
            assert proc.stdout is not None
            for raw in iter(proc.stdout.readline, b""):
                self._file.write(raw)
                self._file.flush()
                self.queue.put(raw.decode("utf-8", errors="replace").rstrip("\n"))
            self._file.close()

        self._thread = threading.Thread(target=reader, daemon=True)
        self._thread.start()

    def wait_for(self, needle: str, timeout_s: float) -> None:
        deadline = time.time() + timeout_s
        tail: list[str] = []
        while time.time() < deadline:
            try:
                line = self.queue.get(timeout=0.2)
                tail.append(line)
                if needle in line:
                    return
            except queue.Empty:
                pass
        raise TimeoutError(f"timed out waiting for {needle!r}; tail={tail[-12:]}")


class PFlashDaemon:
    def __init__(self, *, binary: Path, drafter: Path, gpu: int, log_path: Path,
                 env: dict[str, str]) -> None:
        self.binary = binary
        self.drafter = drafter
        self.gpu = gpu
        self.log = ProcessLog(log_path)
        self.env = env
        self.proc: subprocess.Popen[bytes] | None = None
        self.r_fd: int | None = None

    def start(self) -> float:
        r_fd, w_fd = os.pipe()
        env = os.environ.copy()
        env.update(self.env)
        env["CUDA_VISIBLE_DEVICES"] = str(self.gpu)
        cmd = [str(self.binary), str(self.drafter), f"--stream-fd={w_fd}"]
        t0 = time.perf_counter()
        self.proc = subprocess.Popen(
            cmd,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            pass_fds=(w_fd,),
            env=env,
            cwd=str(ROOT),
            bufsize=0,
        )
        os.close(w_fd)
        self.r_fd = r_fd
        self.log.attach(self.proc)
        self.log.wait_for("[pflash-daemon] ready", 180)
        return time.perf_counter() - t0

    def compress(self, counted_ids: Path, *, keep_ratio: float, lookahead: int,
                 chunk_size: int, pool_kernel: int) -> tuple[list[int], float]:
        if self.proc is None or self.proc.stdin is None or self.r_fd is None:
            raise RuntimeError("pflash daemon is not running")
        keep_x1000 = int(round(keep_ratio * 1000))
        cmd = f"compress {keep_x1000} {lookahead} {chunk_size} {pool_kernel} {counted_ids}\n"
        t0 = time.perf_counter()
        self.proc.stdin.write(cmd.encode("utf-8"))
        self.proc.stdin.flush()
        tokens = read_stream_until_sentinel(self.r_fd)
        return tokens, time.perf_counter() - t0

    def stop(self) -> None:
        if self.proc is None:
            return
        try:
            if self.proc.stdin:
                self.proc.stdin.write(b"quit\n")
                self.proc.stdin.flush()
                self.proc.stdin.close()
        except Exception:
            pass
        try:
            self.proc.wait(timeout=10)
        except subprocess.TimeoutExpired:
            self.proc.terminate()
            try:
                self.proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.proc.kill()
                self.proc.wait()
        if self.r_fd is not None:
            try:
                os.close(self.r_fd)
            except OSError:
                pass
        self.proc = None


class GpuMonitor:
    def __init__(self, path: Path) -> None:
        self.path = path
        self.phase = "init"
        self._lock = threading.Lock()
        self._stop = threading.Event()
        self._thread: threading.Thread | None = None

    def set_phase(self, phase: str) -> None:
        with self._lock:
            self.phase = phase

    def start(self) -> None:
        def phase() -> str:
            with self._lock:
                return self.phase

        def loop() -> None:
            fields = "index,temperature.gpu,fan.speed,power.draw,power.limit,memory.used,memory.total,utilization.gpu"
            with self.path.open("w") as f:
                f.write("ts,phase,index,temp_c,fan_pct,power_w,power_limit_w,mem_used_mib,mem_total_mib,util_pct\n")
                f.flush()
                while not self._stop.is_set():
                    ts = time.time()
                    try:
                        out = subprocess.check_output(
                            ["nvidia-smi", f"--query-gpu={fields}", "--format=csv,noheader,nounits"],
                            text=True,
                            stderr=subprocess.DEVNULL,
                            timeout=2,
                        )
                        for line in out.strip().splitlines():
                            parts = [p.strip() for p in line.split(",")]
                            if len(parts) == 8:
                                f.write(",".join([f"{ts:.3f}", phase()] + parts) + "\n")
                        f.flush()
                    except Exception as exc:
                        f.write(f"{ts:.3f},{phase()},ERR,,,,,,,{type(exc).__name__}\n")
                        f.flush()
                    self._stop.wait(1.0)

        self._thread = threading.Thread(target=loop, daemon=True)
        self._thread.start()

    def stop(self) -> None:
        self._stop.set()
        if self._thread:
            self._thread.join(timeout=3)

    def summarize_gpu(self, gpu: int) -> dict[str, float | int | None]:
        rows: list[dict[str, float | int]] = []
        if not self.path.exists():
            return {"samples": 0}
        for line in self.path.read_text().splitlines()[1:]:
            parts = line.split(",")
            if len(parts) != 10 or parts[2] == "ERR":
                continue
            try:
                idx = int(parts[2])
                if idx != gpu:
                    continue
                rows.append({
                    "temp": float(parts[3]),
                    "fan": float(parts[4]),
                    "power": float(parts[5]),
                    "mem": float(parts[7]),
                    "util": float(parts[9]),
                })
            except ValueError:
                pass
        if not rows:
            return {"samples": 0}
        return {
            "samples": len(rows),
            "mem_max_mib": max(float(r["mem"]) for r in rows),
            "temp_max_c": max(float(r["temp"]) for r in rows),
            "fan_max_pct": max(float(r["fan"]) for r in rows),
            "power_avg_w": mean(float(r["power"]) for r in rows),
            "power_max_w": max(float(r["power"]) for r in rows),
            "util_avg_pct": mean(float(r["util"]) for r in rows),
            "util_max_pct": max(float(r["util"]) for r in rows),
        }


@dataclass
class CompressionCase:
    name: str
    source_tokens: int
    compressed_tokens: int
    compress_wall_s: float
    compress_tok_s: float
    compression_ratio: float
    retained_key: bool | None = None
    retained_answer: bool | None = None


def load_tokenizer(args):
    from transformers import AutoTokenizer

    return AutoTokenizer.from_pretrained(
        args.tokenizer,
        trust_remote_code=True,
        local_files_only=bool(args.local_files_only),
    )


def make_niah_text(tokenizer, token_count: int, case_idx: int, needle_fraction: float) -> tuple[str, str, str, int]:
    key = f"keymark{case_idx}zeta"
    answer = f"04385{74 + case_idx:02d}"
    intro = "Below is a long passage. Keep important facts from the passage.\n\n"
    filler = "The grass is green. The sky is blue. The sun is yellow. Here we go. There and back again. "
    needle = f"The special magic {key} number is {answer}. Remember this exact number. "
    question = f"\n\nQuestion: What is the special magic {key} number?\n"

    def build(reps: int) -> str:
        pos = max(0, min(reps, int(reps * needle_fraction)))
        body = filler * pos + needle + filler * (reps - pos)
        return intro + body + question

    fixed = len(tokenizer.encode(intro + needle + question, add_special_tokens=False))
    filler_tokens = max(1, len(tokenizer.encode(filler, add_special_tokens=False)))
    lo = 0
    hi = max(8, (max(0, token_count - fixed) // filler_tokens) + 8)
    while len(tokenizer.encode(build(hi), add_special_tokens=False)) < token_count:
        hi *= 2
    while lo < hi:
        mid = (lo + hi + 1) // 2
        if len(tokenizer.encode(build(mid), add_special_tokens=False)) <= token_count:
            lo = mid
        else:
            hi = mid - 1
    text = build(lo)
    actual = len(tokenizer.encode(text, add_special_tokens=False))
    return text, key, answer, actual


def make_pflash_env(args) -> dict[str, str]:
    env = {"DFLASH_FP_ALPHA": str(args.pflash_alpha)}
    if args.pflash_use_bsa:
        env["DFLASH_FP_USE_BSA"] = "1"
    if args.pflash_k_type:
        env["DFLASH_PFLASH_K_TYPE"] = args.pflash_k_type
    return env


def fmt(value, nd: int = 2) -> str:
    if value is None:
        return "n/a"
    return f"{float(value):.{nd}f}"


def run_cases(args, cases: list[tuple[str, str, str | None, str | None]]) -> None:
    args.report_dir.mkdir(parents=True, exist_ok=True)
    tokenizer = load_tokenizer(args)
    monitor = GpuMonitor(args.report_dir / "gpu_monitor.csv")
    daemon = PFlashDaemon(
        binary=args.pflash_bin,
        drafter=args.pflash_drafter,
        gpu=args.pflash_gpu,
        log_path=args.report_dir / "pflash_daemon.log",
        env=make_pflash_env(args),
    )
    results: list[CompressionCase] = []
    try:
        monitor.start()
        monitor.set_phase("pflash_load")
        ready_s = daemon.start()
        for name, text, key, answer in cases:
            case_dir = args.report_dir / name
            case_dir.mkdir(parents=True, exist_ok=True)
            ids = tokenizer.encode(text, add_special_tokens=False)
            (case_dir / "prompt.txt").write_text(text, encoding="utf-8")
            counted = case_dir / "prompt_counted.bin"
            write_counted_i32(counted, ids)

            monitor.set_phase(name)
            kept, wall_s = daemon.compress(
                counted,
                keep_ratio=args.keep_ratio,
                lookahead=args.lookahead,
                chunk_size=args.chunk_size,
                pool_kernel=args.pool_kernel,
            )
            compressed_text = tokenizer.decode(kept, skip_special_tokens=True)
            (case_dir / "compressed.txt").write_text(compressed_text, encoding="utf-8")
            write_counted_i32(case_dir / "compressed_counted.bin", kept)

            results.append(CompressionCase(
                name=name,
                source_tokens=len(ids),
                compressed_tokens=len(kept),
                compress_wall_s=wall_s,
                compress_tok_s=len(ids) / wall_s if wall_s > 0 else 0.0,
                compression_ratio=(len(kept) / len(ids)) if ids else 0.0,
                retained_key=(key in compressed_text) if key else None,
                retained_answer=(answer in compressed_text) if answer else None,
            ))

        monitor.set_phase("cleanup")
        resource_summary = monitor.summarize_gpu(args.pflash_gpu)
        summary = {
            "date": time.strftime("%Y-%m-%d"),
            "mode": "dual_gpu_pflash_phase_split",
            "pflash_gpu": args.pflash_gpu,
            "pflash_daemon_ready_s": ready_s,
            "pflash_drafter": str(args.pflash_drafter),
            "tokenizer": args.tokenizer,
            "keep_ratio": args.keep_ratio,
            "lookahead": args.lookahead,
            "chunk_size": args.chunk_size,
            "pool_kernel": args.pool_kernel,
            "pflash_k_type": args.pflash_k_type or "compute",
            "cases": [asdict(c) for c in results],
            "resource_summary": resource_summary,
            "logs": {
                "pflash": str(args.report_dir / "pflash_daemon.log"),
                "monitor": str(args.report_dir / "gpu_monitor.csv"),
            },
        }
        (args.report_dir / "summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
        write_markdown(args.report_dir / "summary.md", summary)
        print(json.dumps(summary, indent=2))
    finally:
        monitor.stop()
        daemon.stop()


def write_markdown(path: Path, summary: dict) -> None:
    lines = [
        "# Dual-GPU PFlash Phase-Split Report",
        "",
        f"- PFlash GPU: `{summary['pflash_gpu']}`",
        f"- PFlash daemon ready: `{fmt(summary['pflash_daemon_ready_s'])} s`",
        f"- keep ratio: `{summary['keep_ratio']}`",
        f"- lookahead: `{summary['lookahead']}`",
        f"- PFlash K cache: `{summary.get('pflash_k_type', 'compute')}`",
        "",
        "## Resource Peak",
        "",
        "| gpu | samples | peak mem MiB | peak temp C | avg power W | peak power W | avg util % | peak util % |",
        "|---:|---:|---:|---:|---:|---:|---:|---:|",
    ]
    res = summary.get("resource_summary") or {}
    lines.append(
        "| {gpu} | {samples} | {mem} | {temp} | {pavg} | {pmax} | {uavg} | {umax} |".format(
            gpu=summary["pflash_gpu"],
            samples=res.get("samples", 0),
            mem=fmt(res.get("mem_max_mib")),
            temp=fmt(res.get("temp_max_c")),
            pavg=fmt(res.get("power_avg_w")),
            pmax=fmt(res.get("power_max_w")),
            uavg=fmt(res.get("util_avg_pct")),
            umax=fmt(res.get("util_max_pct")),
        )
    )
    lines.extend([
        "",
        "## Cases",
        "",
        "| case | source tokens | compressed tokens | ratio | PFlash s | PFlash tok/s | key retained | answer retained |",
        "|---|---:|---:|---:|---:|---:|:---:|:---:|",
    ])
    for case in summary["cases"]:
        key = case.get("retained_key")
        answer = case.get("retained_answer")
        lines.append(
            "| {name} | {source} | {compressed} | {ratio} | {secs} | {tps} | {key} | {answer} |".format(
                name=case["name"],
                source=case["source_tokens"],
                compressed=case["compressed_tokens"],
                ratio=fmt(case["compression_ratio"], 4),
                secs=fmt(case["compress_wall_s"]),
                tps=fmt(case["compress_tok_s"]),
                key="n/a" if key is None else ("yes" if key else "no"),
                answer="n/a" if answer is None else ("yes" if answer else "no"),
            )
        )
    lines.extend([
        "",
        "Files:",
    ])
    for key, value in summary["logs"].items():
        lines.append(f"- {key}: `{value}`")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def read_prompt_text(args) -> str:
    if args.prompt and args.prompt_file:
        raise SystemExit("use only one of --prompt or --prompt-file")
    if args.prompt_file:
        return args.prompt_file.read_text(encoding="utf-8")
    if args.prompt is not None:
        return args.prompt
    if not sys.stdin.isatty():
        return sys.stdin.read()
    raise SystemExit("provide --prompt, --prompt-file, or pipe prompt text on stdin")


def run_prompt(args) -> None:
    text = read_prompt_text(args)
    if not text.strip():
        raise SystemExit("prompt is empty")
    run_cases(args, [("prompt", text, None, None)])


def run_bench_niah(args) -> None:
    tokenizer = load_tokenizer(args)
    cases: list[tuple[str, str, str | None, str | None]] = []
    for idx, value in enumerate(x for x in args.contexts.split(",") if x.strip()):
        requested = int(value)
        text, key, answer, actual = make_niah_text(tokenizer, requested, idx, args.needle_fraction)
        cases.append((f"niah_ctx{actual}", text, key, answer))
    run_cases(args, cases)


def add_common_args(ap: argparse.ArgumentParser) -> None:
    ap.add_argument("--build-dir", type=Path, default=DEFAULT_BUILD)
    ap.add_argument("--pflash-bin", type=Path, default=None)
    ap.add_argument("--pflash-drafter", type=Path, default=DEFAULT_DRAFTER)
    ap.add_argument("--tokenizer", default=DEFAULT_TOKENIZER)
    ap.add_argument("--pflash-gpu", type=int, default=0)
    ap.add_argument("--local-files-only", action=argparse.BooleanOptionalAction, default=False)
    ap.add_argument("--keep-ratio", type=float, default=0.05)
    ap.add_argument("--lookahead", type=int, default=2)
    ap.add_argument("--chunk-size", type=int, default=32)
    ap.add_argument("--pool-kernel", type=int, default=13)
    ap.add_argument("--pflash-alpha", type=float, default=0.99)
    ap.add_argument("--pflash-use-bsa", action=argparse.BooleanOptionalAction, default=True)
    ap.add_argument("--pflash-k-type", default=None,
                    choices=["f16", "bf16", "q8_0", "q4_0", "q4_1"],
                    help="persistent PFlash drafter K cache type; default follows drafter compute type")
    ap.add_argument("--report-dir", type=Path, default=Path("reports/pflash_phase_split"))


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    sub = ap.add_subparsers(dest="cmd", required=True)

    prompt = sub.add_parser("run-prompt", help="run a prompt through the PFlash phase")
    add_common_args(prompt)
    prompt.add_argument("--prompt", default=None)
    prompt.add_argument("--prompt-file", type=Path, default=None)
    prompt.set_defaults(func=run_prompt)

    bench = sub.add_parser("bench-niah", help="compress synthetic NIAH prompts")
    add_common_args(bench)
    bench.add_argument("--contexts", default="4096,8192,16384")
    bench.add_argument("--needle-fraction", type=float, default=0.5)
    bench.set_defaults(func=run_bench_niah)

    args = ap.parse_args()
    args.pflash_bin = args.pflash_bin or (args.build_dir / "pflash_daemon")
    for path in (args.pflash_bin, args.pflash_drafter):
        if not Path(path).exists():
            raise SystemExit(f"missing required path: {path}")
    args.func(args)


if __name__ == "__main__":
    main()
