"""JSONL activity log — every meaningful event as a structured record.

The agent writes one JSON object per line to a file so post-hoc
analysis tools (BigQuery, DuckDB, ``jq``) can consume it without
custom parsers. Rotation / max-size handling is intentionally absent
so the caller controls lifecycle; at most one file per engagement is
expected.

Events follow a stable schema:

    {
      "ts": 1700000000.123,
      "kind": "tool_call" | "finding" | "agent_step" | "note",
      "actor": "recon" | "analyst" | "user" | ...,
      "target": optional string,
      "message": free text,
      "data": optional JSON blob
    }
"""

from __future__ import annotations

import json
import threading
import time
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any, Callable, Iterable


@dataclass
class LogEvent:
    ts: float
    kind: str
    actor: str
    message: str
    target: str | None = None
    data: dict[str, Any] = field(default_factory=dict)

    @classmethod
    def from_dict(cls, raw: dict[str, Any]) -> LogEvent:
        return cls(
            ts=float(raw.get("ts", time.time())),
            kind=str(raw.get("kind", "note")),
            actor=str(raw.get("actor", "unknown")),
            target=raw.get("target"),
            message=str(raw.get("message", "")),
            data=dict(raw.get("data", {})),
        )

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


class ActivityLog:
    """Append-only JSONL log with thread-safe write + query helpers."""

    def __init__(self, path: str | Path) -> None:
        self.path = Path(path)
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self._lock = threading.Lock()

    def log(
        self,
        kind: str,
        actor: str,
        message: str,
        *,
        target: str | None = None,
        data: dict[str, Any] | None = None,
    ) -> LogEvent:
        event = LogEvent(
            ts=time.time(),
            kind=kind,
            actor=actor,
            target=target,
            message=message,
            data=data or {},
        )
        payload = json.dumps(event.to_dict(), separators=(",", ":"), ensure_ascii=False)
        with self._lock:
            with self.path.open("a", encoding="utf-8") as fh:
                fh.write(payload + "\n")
        return event

    # ── Query ──────────────────────────────────────────────────────────

    def iter_events(self) -> Iterable[LogEvent]:
        if not self.path.exists():
            return
        with self.path.open("r", encoding="utf-8") as fh:
            for line in fh:
                line = line.strip()
                if not line:
                    continue
                try:
                    yield LogEvent.from_dict(json.loads(line))
                except json.JSONDecodeError:
                    continue

    def query(
        self,
        *,
        kind: str | None = None,
        actor: str | None = None,
        target_substr: str | None = None,
        message_substr: str | None = None,
        since: float | None = None,
        until: float | None = None,
        predicate: Callable[[LogEvent], bool] | None = None,
        limit: int | None = None,
    ) -> list[LogEvent]:
        out: list[LogEvent] = []
        for event in self.iter_events():
            if kind is not None and event.kind != kind:
                continue
            if actor is not None and event.actor != actor:
                continue
            if target_substr and (event.target is None or target_substr not in event.target):
                continue
            if message_substr and message_substr not in event.message:
                continue
            if since is not None and event.ts < since:
                continue
            if until is not None and event.ts > until:
                continue
            if predicate is not None and not predicate(event):
                continue
            out.append(event)
            if limit and len(out) >= limit:
                break
        return out

    def tail(self, n: int = 50) -> list[LogEvent]:
        all_events = list(self.iter_events())
        return all_events[-n:]

    def clear(self) -> None:
        with self._lock:
            self.path.write_text("", encoding="utf-8")
