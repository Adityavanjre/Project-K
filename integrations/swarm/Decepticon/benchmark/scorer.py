from __future__ import annotations

from datetime import datetime

from benchmark.schemas import BenchmarkReport, ChallengeResult


class Scorer:
    @staticmethod
    def score(
        results: list[ChallengeResult],
        provider_name: str,
        started_at: datetime,
        completed_at: datetime,
    ) -> BenchmarkReport:
        """Aggregate challenge results into a BenchmarkReport."""
        total = len(results)
        passed = sum(1 for r in results if r.passed)
        failed = total - passed
        pass_rate = passed / total if total > 0 else 0.0

        by_level: dict[int, dict] = {}
        for r in results:
            entry = by_level.setdefault(r.level, {"total": 0, "passed": 0})
            entry["total"] += 1
            if r.passed:
                entry["passed"] += 1
        for entry in by_level.values():
            entry["pass_rate"] = entry["passed"] / entry["total"] if entry["total"] > 0 else 0.0

        by_tag: dict[str, dict] = {}
        for r in results:
            for tag in r.tags:
                entry = by_tag.setdefault(tag, {"total": 0, "passed": 0})
                entry["total"] += 1
                if r.passed:
                    entry["passed"] += 1
        for entry in by_tag.values():
            entry["pass_rate"] = entry["passed"] / entry["total"] if entry["total"] > 0 else 0.0

        duration_seconds = (completed_at - started_at).total_seconds()

        return BenchmarkReport(
            provider_name=provider_name,
            total=total,
            passed=passed,
            failed=failed,
            pass_rate=pass_rate,
            by_level=by_level,
            by_tag=by_tag,
            results=results,
            started_at=started_at,
            completed_at=completed_at,
            duration_seconds=duration_seconds,
        )
