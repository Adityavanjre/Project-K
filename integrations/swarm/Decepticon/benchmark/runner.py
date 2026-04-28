from __future__ import annotations

import asyncio
import logging
from datetime import datetime, timezone

import typer

from benchmark.config import BenchmarkConfig
from benchmark.harness import Harness
from benchmark.providers.xbow import XBOWProvider
from benchmark.reporter import Reporter
from benchmark.schemas import Challenge, ChallengeResult, FilterConfig
from benchmark.scorer import Scorer

log = logging.getLogger(__name__)
app = typer.Typer(name="benchmark", help="Decepticon Benchmark Runner")


@app.command()
def run(
    level: list[int] = typer.Option([], "--level", "-l", help="Filter by difficulty level (1-3)"),
    tags: list[str] = typer.Option([], "--tags", "-t", help="Filter by vulnerability tags"),
    range_start: int | None = typer.Option(None, "--range-start", help="Start index (1-based)"),
    range_end: int | None = typer.Option(None, "--range-end", help="End index (1-based)"),
    batch_size: int = typer.Option(10, "--batch-size", "-b", help="Challenges per batch"),
    timeout: int = typer.Option(1800, "--timeout", help="Per-challenge timeout in seconds"),
    parallel: int = typer.Option(
        1, "--parallel", "-p", help="Max concurrent challenges (1=sequential)"
    ),
) -> None:
    """Run the benchmark suite against loaded challenges."""
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(name)s: %(message)s")

    filters = FilterConfig(
        levels=level,
        tags=tags,
        range_start=range_start,
        range_end=range_end,
    )

    config = BenchmarkConfig(timeout=timeout, batch_size=batch_size)
    provider = XBOWProvider()
    challenges = provider.load_challenges(filters)

    if not challenges:
        typer.echo("No challenges found matching filters.")
        raise typer.Exit(code=0)

    mode = f"parallel={parallel}" if parallel > 1 else "sequential"
    typer.echo(f"Found {len(challenges)} challenges ({mode})")

    # Pre-build all challenge Docker images before starting
    typer.echo("Pre-building challenge images...")
    build_failures = provider.preflight_build(challenges)
    if build_failures:
        typer.echo(f"WARNING: {len(build_failures)} challenges failed to build:")
        for cid, err in build_failures.items():
            typer.echo(f"  {cid}: {err[:100]}")

    harness = Harness(provider, config)
    started_at = datetime.now(timezone.utc)

    if parallel > 1:
        results = asyncio.run(_run_parallel(harness, challenges, parallel))
    else:
        results = _run_sequential(harness, challenges)

    completed_at = datetime.now(timezone.utc)

    report = Scorer.score(results, provider.name, started_at, completed_at)
    reporter = Reporter(config.results_dir)
    json_path = reporter.write_json(report)
    md_path = reporter.write_markdown(report)
    evidence_dir = reporter.write_evidence(report)

    typer.echo("")
    typer.echo(f"Results: {report.passed}/{report.total} passed ({report.pass_rate:.1%})")
    typer.echo(f"Duration: {report.duration_seconds:.1f}s")
    typer.echo(f"JSON report: {json_path}")
    typer.echo(f"Markdown report: {md_path}")
    typer.echo(f"Evidence: {evidence_dir}")

    if report.failed > 0:
        raise typer.Exit(code=1)


def _run_sequential(
    harness: Harness,
    challenges: list[Challenge],
) -> list[ChallengeResult]:
    """Run challenges one at a time (original behavior)."""
    return asyncio.run(_run_sequential_async(harness, challenges))


async def _run_sequential_async(
    harness: Harness,
    challenges: list[Challenge],
) -> list[ChallengeResult]:
    """Async implementation for sequential challenge execution."""
    results: list[ChallengeResult] = []
    total = len(challenges)

    for i, challenge in enumerate(challenges, start=1):
        typer.echo(f"[{i}/{total}] {challenge.id}: {challenge.name}...", nl=False)
        result = await harness.run_challenge(challenge)
        results.append(result)
        status = "PASS" if result.passed else "FAIL"
        typer.echo(f" {status} ({result.duration_seconds:.0f}s)")

    passed = sum(1 for r in results if r.passed)
    pct = (passed / total * 100) if total > 0 else 0.0
    typer.echo(f"Batch 1/1 complete: {passed}/{total} passed ({pct:.0f}%)")
    return results


async def _run_parallel(
    harness: Harness,
    challenges: list[Challenge],
    max_concurrent: int,
) -> list[ChallengeResult]:
    """Run challenges concurrently with a semaphore limit."""
    semaphore = asyncio.Semaphore(max_concurrent)
    total = len(challenges)
    completed = 0
    lock = asyncio.Lock()

    async def run_one(index: int, challenge: Challenge) -> ChallengeResult:
        nonlocal completed
        async with semaphore:
            typer.echo(f"[{index}/{total}] START {challenge.id}: {challenge.name}")
            result = await harness.run_challenge(challenge)
            async with lock:
                completed += 1
                status = "PASS" if result.passed else "FAIL"
                typer.echo(
                    f"[{index}/{total}] {status} {challenge.id} "
                    f"({result.duration_seconds:.0f}s) "
                    f"[{completed}/{total} done]"
                )
            return result

    tasks = [run_one(i, challenge) for i, challenge in enumerate(challenges, start=1)]
    results = await asyncio.gather(*tasks)
    passed = sum(1 for r in results if r.passed)
    pct = (passed / total * 100) if total > 0 else 0.0
    typer.echo(f"Complete: {passed}/{total} passed ({pct:.0f}%)")
    return list(results)


if __name__ == "__main__":
    app()
