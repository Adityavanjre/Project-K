"""Lightweight Prometheus-compatible metrics registry.

Zero dependencies — just the std lib. Exposes Counter, Gauge, Histogram
with label support and a ``render()`` function that emits the standard
Prometheus text exposition format. The Decepticon HTTP server can wire
it up to ``/metrics`` without importing a client library.

API mirrors ``prometheus_client`` so future migration is trivial.
"""

from __future__ import annotations

import threading
from dataclasses import dataclass, field
from typing import Iterable

LabelTuple = tuple[tuple[str, str], ...]


def _normalise_labels(labels: dict[str, str] | None) -> LabelTuple:
    if not labels:
        return ()
    return tuple(sorted(labels.items()))


def _format_labels(labels: LabelTuple) -> str:
    if not labels:
        return ""
    inner = ",".join(f'{k}="{_escape(v)}"' for k, v in labels)
    return "{" + inner + "}"


def _escape(v: str) -> str:
    return v.replace("\\", "\\\\").replace("\n", "\\n").replace('"', '\\"')


@dataclass
class Counter:
    name: str
    help: str
    _values: dict[LabelTuple, float] = field(default_factory=dict)
    _lock: threading.Lock = field(default_factory=threading.Lock)

    def inc(self, amount: float = 1.0, **labels: str) -> None:
        key = _normalise_labels(labels)
        with self._lock:
            self._values[key] = self._values.get(key, 0.0) + amount

    def value(self, **labels: str) -> float:
        return self._values.get(_normalise_labels(labels), 0.0)

    def render(self) -> list[str]:
        lines = [f"# HELP {self.name} {self.help}", f"# TYPE {self.name} counter"]
        for key, val in self._values.items():
            lines.append(f"{self.name}{_format_labels(key)} {val}")
        return lines


@dataclass
class Gauge:
    name: str
    help: str
    _values: dict[LabelTuple, float] = field(default_factory=dict)
    _lock: threading.Lock = field(default_factory=threading.Lock)

    def set(self, value: float, **labels: str) -> None:
        key = _normalise_labels(labels)
        with self._lock:
            self._values[key] = value

    def inc(self, amount: float = 1.0, **labels: str) -> None:
        key = _normalise_labels(labels)
        with self._lock:
            self._values[key] = self._values.get(key, 0.0) + amount

    def dec(self, amount: float = 1.0, **labels: str) -> None:
        self.inc(-amount, **labels)

    def value(self, **labels: str) -> float:
        return self._values.get(_normalise_labels(labels), 0.0)

    def render(self) -> list[str]:
        lines = [f"# HELP {self.name} {self.help}", f"# TYPE {self.name} gauge"]
        for key, val in self._values.items():
            lines.append(f"{self.name}{_format_labels(key)} {val}")
        return lines


_DEFAULT_BUCKETS: tuple[float, ...] = (
    0.005,
    0.01,
    0.025,
    0.05,
    0.1,
    0.25,
    0.5,
    1.0,
    2.5,
    5.0,
    10.0,
    30.0,
    60.0,
    float("inf"),
)


@dataclass
class Histogram:
    name: str
    help: str
    buckets: tuple[float, ...] = _DEFAULT_BUCKETS
    _counts: dict[LabelTuple, list[int]] = field(default_factory=dict)
    _sums: dict[LabelTuple, float] = field(default_factory=dict)
    _totals: dict[LabelTuple, int] = field(default_factory=dict)
    _lock: threading.Lock = field(default_factory=threading.Lock)

    def observe(self, value: float, **labels: str) -> None:
        key = _normalise_labels(labels)
        with self._lock:
            counts = self._counts.setdefault(key, [0] * len(self.buckets))
            for i, upper in enumerate(self.buckets):
                if value <= upper:
                    counts[i] += 1
            self._sums[key] = self._sums.get(key, 0.0) + value
            self._totals[key] = self._totals.get(key, 0) + 1

    def render(self) -> list[str]:
        lines = [f"# HELP {self.name} {self.help}", f"# TYPE {self.name} histogram"]
        for key, counts in self._counts.items():
            for i, upper in enumerate(self.buckets):
                label_dict = dict(key) | {"le": "+Inf" if upper == float("inf") else str(upper)}
                lines.append(
                    f"{self.name}_bucket{_format_labels(_normalise_labels(label_dict))} {counts[i]}"
                )
            lines.append(f"{self.name}_sum{_format_labels(key)} {self._sums[key]}")
            lines.append(f"{self.name}_count{_format_labels(key)} {self._totals[key]}")
        return lines


Metric = Counter | Gauge | Histogram


@dataclass
class Registry:
    metrics: list[Metric] = field(default_factory=list)
    _by_name: dict[str, Metric] = field(default_factory=dict)

    def register(self, metric: Metric) -> None:
        if metric.name in self._by_name:
            raise ValueError(f"duplicate metric name: {metric.name}")
        self._by_name[metric.name] = metric
        self.metrics.append(metric)

    def counter(self, name: str, help: str) -> Counter:
        c = Counter(name=name, help=help)
        self.register(c)
        return c

    def gauge(self, name: str, help: str) -> Gauge:
        g = Gauge(name=name, help=help)
        self.register(g)
        return g

    def histogram(self, name: str, help: str, buckets: Iterable[float] | None = None) -> Histogram:
        h = Histogram(
            name=name,
            help=help,
            buckets=tuple(buckets) if buckets else _DEFAULT_BUCKETS,
        )
        self.register(h)
        return h


def render(registry: Registry) -> str:
    """Emit the full registry as Prometheus text-format."""
    lines: list[str] = []
    for metric in registry.metrics:
        lines.extend(metric.render())
    lines.append("")  # trailing newline for valid exposition
    return "\n".join(lines)


# Convenience module-level registry for the default decepticon process.
DEFAULT_REGISTRY = Registry()
