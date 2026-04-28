"""Tests for observability: metrics, activity log, tracing."""

from __future__ import annotations

import json
from pathlib import Path

from decepticon.observability.activity import ActivityLog
from decepticon.observability.metrics import Counter, Gauge, Histogram, Registry, render
from decepticon.observability.tracing import span


class TestMetrics:
    def test_counter_labeled(self) -> None:
        c = Counter(name="reqs", help="requests")
        c.inc(3, agent="recon")
        c.inc(2, agent="analyst")
        assert c.value(agent="recon") == 3
        assert c.value(agent="analyst") == 2

    def test_gauge_set_inc_dec(self) -> None:
        g = Gauge(name="queue", help="queue depth")
        g.set(5)
        g.inc(2)
        g.dec(1)
        assert g.value() == 6

    def test_histogram_buckets(self) -> None:
        h = Histogram(name="latency", help="latency")
        h.observe(0.01)
        h.observe(0.1)
        h.observe(0.5)
        h.observe(5.0)
        lines = h.render()
        assert any("latency_count" in line for line in lines)
        assert any("latency_sum" in line for line in lines)
        assert any("latency_bucket" in line for line in lines)

    def test_registry_render(self) -> None:
        r = Registry()
        c = r.counter("c", "c help")
        g = r.gauge("g", "g help")
        h = r.histogram("h", "h help", buckets=[0.1, 1.0, float("inf")])
        c.inc()
        g.set(3)
        h.observe(0.05)
        out = render(r)
        assert "# HELP c" in out
        assert "# TYPE c counter" in out
        assert "# TYPE g gauge" in out
        assert "# TYPE h histogram" in out

    def test_registry_duplicate_raises(self) -> None:
        r = Registry()
        r.counter("x", "")
        try:
            r.counter("x", "")
        except ValueError as e:
            assert "duplicate" in str(e)
        else:
            raise AssertionError("expected ValueError")


class TestActivityLog:
    def test_append_and_query(self, tmp_path: Path) -> None:
        log = ActivityLog(tmp_path / "a.jsonl")
        log.log("tool_call", "recon", "ran nmap")
        log.log("finding", "analyst", "found SSRF", target="/api", data={"severity": "high"})
        log.log("tool_call", "analyst", "semgrep")
        assert len(log.query(actor="analyst")) == 2
        assert len(log.query(kind="tool_call")) == 2
        assert log.query(target_substr="/api")[0].target == "/api"
        tail = log.tail(1)
        assert tail[0].message == "semgrep"

    def test_clear(self, tmp_path: Path) -> None:
        log = ActivityLog(tmp_path / "a.jsonl")
        log.log("x", "y", "z")
        log.clear()
        assert log.tail() == []

    def test_iter_events_skips_invalid(self, tmp_path: Path) -> None:
        path = tmp_path / "a.jsonl"
        path.write_text(
            json.dumps({"ts": 1.0, "kind": "k", "actor": "a", "message": "m"})
            + "\n"
            + "garbage\n"
            + "\n",
            encoding="utf-8",
        )
        log = ActivityLog(path)
        events = list(log.iter_events())
        assert len(events) == 1


class TestTracing:
    def test_span_noop_context_manager(self) -> None:
        with span("test.operation", user="alice") as s:
            # Always usable regardless of OTel presence
            s.set_attribute("key", "value")
            s.add_event("checkpoint")
