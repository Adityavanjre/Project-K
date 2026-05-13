"""Tests for benchmark.scorer.Scorer."""

from __future__ import annotations

from datetime import datetime, timezone

from benchmark.schemas import ChallengeResult
from benchmark.scorer import Scorer


def _make_result(
    challenge_id: str,
    level: int,
    tags: list[str],
    passed: bool,
) -> ChallengeResult:
    return ChallengeResult(
        challenge_id=challenge_id,
        challenge_name=f"Challenge {challenge_id}",
        level=level,
        tags=tags,
        passed=passed,
    )


class TestScorer:
    def _times(self) -> tuple[datetime, datetime]:
        start = datetime(2026, 1, 1, tzinfo=timezone.utc)
        end = datetime(2026, 1, 1, 0, 10, tzinfo=timezone.utc)
        return start, end

    def test_score_mixed_results(self) -> None:
        """Mixed passed/failed results produce correct totals."""
        start, end = self._times()
        results = [
            _make_result("C-001", 1, ["xss"], True),
            _make_result("C-002", 1, ["sqli"], False),
            _make_result("C-003", 2, ["xss"], True),
        ]

        report = Scorer.score(results, "test", start, end)

        assert report.total == 3
        assert report.passed == 2
        assert report.failed == 1
        assert report.pass_rate == 2 / 3

    def test_score_by_level(self) -> None:
        """Verify by_level breakdown is computed correctly."""
        start, end = self._times()
        results = [
            _make_result("C-001", 1, ["xss"], True),
            _make_result("C-002", 1, ["sqli"], True),
            _make_result("C-003", 1, ["rce"], False),
            _make_result("C-004", 2, ["idor"], True),
        ]

        report = Scorer.score(results, "test", start, end)

        assert report.by_level[1]["total"] == 3
        assert report.by_level[1]["passed"] == 2
        assert report.by_level[1]["pass_rate"] == 2 / 3
        assert report.by_level[2]["total"] == 1
        assert report.by_level[2]["passed"] == 1
        assert report.by_level[2]["pass_rate"] == 1.0

    def test_score_by_tag(self) -> None:
        """Verify by_tag breakdown handles challenges with multiple tags."""
        start, end = self._times()
        results = [
            _make_result("C-001", 1, ["xss", "web"], True),
            _make_result("C-002", 1, ["sqli", "web"], False),
        ]

        report = Scorer.score(results, "test", start, end)

        assert report.by_tag["xss"]["total"] == 1
        assert report.by_tag["xss"]["passed"] == 1
        assert report.by_tag["xss"]["pass_rate"] == 1.0
        assert report.by_tag["sqli"]["total"] == 1
        assert report.by_tag["sqli"]["passed"] == 0
        assert report.by_tag["sqli"]["pass_rate"] == 0.0
        assert report.by_tag["web"]["total"] == 2
        assert report.by_tag["web"]["passed"] == 1
        assert report.by_tag["web"]["pass_rate"] == 0.5

    def test_score_empty_results(self) -> None:
        """Empty list produces report with total=0, pass_rate=0.0."""
        start, end = self._times()
        report = Scorer.score([], "test", start, end)

        assert report.total == 0
        assert report.passed == 0
        assert report.failed == 0
        assert report.pass_rate == 0.0
        assert report.by_level == {}
        assert report.by_tag == {}

    def test_score_all_passed(self) -> None:
        """All passed -> pass_rate=1.0."""
        start, end = self._times()
        results = [
            _make_result("C-001", 1, ["xss"], True),
            _make_result("C-002", 2, ["sqli"], True),
        ]

        report = Scorer.score(results, "test", start, end)

        assert report.pass_rate == 1.0
        assert report.passed == 2
        assert report.failed == 0

    def test_score_all_failed(self) -> None:
        """All failed -> pass_rate=0.0."""
        start, end = self._times()
        results = [
            _make_result("C-001", 1, ["xss"], False),
            _make_result("C-002", 2, ["sqli"], False),
        ]

        report = Scorer.score(results, "test", start, end)

        assert report.pass_rate == 0.0
        assert report.passed == 0
        assert report.failed == 2
