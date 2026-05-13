"""Regression tests for the StreamingRunnable no-state fallback.

Originally, when ``stream()``/``astream()`` yielded nothing, the wrapper
fell back to a full ``invoke()``/``ainvoke()`` of the sub-agent. For
tool-using agents that meant every bash call / graph write / HTTP
request fired twice — silent double side effects.

The fix surfaces the empty stream as an explicit error state. These
tests prove that path is no longer a double-execution landmine.
"""

from __future__ import annotations

from typing import Any

import pytest
from langchain_core.messages import AIMessage, HumanMessage

from decepticon.core.subagent_streaming import (
    StreamingRunnable,
    clear_subagent_renderer,
    set_subagent_renderer,
)


class CountingRunnable:
    """Minimal fake LangGraph runnable for side-effect counting."""

    def __init__(self, stream_items: list[Any], invoke_payload: Any | None = None):
        self._stream_items = stream_items
        self._invoke_payload = invoke_payload or {"messages": [AIMessage(content="plain")]}
        self.invoke_calls = 0
        self.ainvoke_calls = 0
        self.stream_calls = 0
        self.astream_calls = 0

    def stream(self, input: Any, config: Any = None, stream_mode: str = "values", **kwargs: Any):
        self.stream_calls += 1
        yield from self._stream_items

    async def astream(
        self, input: Any, config: Any = None, stream_mode: str = "values", **kwargs: Any
    ):
        self.astream_calls += 1
        for item in self._stream_items:
            yield item

    def invoke(self, input: Any, config: Any = None, **kwargs: Any) -> Any:
        self.invoke_calls += 1
        return self._invoke_payload

    async def ainvoke(self, input: Any, config: Any = None, **kwargs: Any) -> Any:
        self.ainvoke_calls += 1
        return self._invoke_payload


class DummyRenderer:
    """Minimal renderer shim so StreamingRunnable doesn't take the
    no-channels plain-invoke fast path."""

    def __init__(self) -> None:
        self.events: list[tuple[str, tuple[Any, ...]]] = []

    def on_subagent_start(self, name: str, prompt: str) -> None:
        self.events.append(("start", (name, prompt)))

    def on_subagent_end(
        self, name: str, elapsed: float, *, cancelled: bool = False, error: bool = False
    ) -> None:
        self.events.append(("end", (name, cancelled, error)))

    def on_subagent_message(self, name: str, text: str) -> None:
        self.events.append(("msg", (name, text)))

    def on_subagent_tool_call(self, name: str, tool: str, args: Any) -> None:  # pragma: no cover
        self.events.append(("tool_call", (name, tool, args)))

    def on_subagent_tool_result(self, *args: Any, **kwargs: Any) -> None:  # pragma: no cover
        self.events.append(("tool_result", args))


@pytest.fixture
def renderer():
    r = DummyRenderer()
    token = set_subagent_renderer(r)
    try:
        yield r
    finally:
        clear_subagent_renderer(token)


class TestInvokeNoStateReturnsErrorNotDoubleExec:
    """stream() yielding zero states MUST NOT fall back to invoke()."""

    def test_empty_stream_returns_error_message_without_reinvoking(
        self, renderer: DummyRenderer
    ) -> None:
        fake = CountingRunnable(stream_items=[])
        wrapper = StreamingRunnable(fake, "scanner")

        out = wrapper.invoke({"messages": [HumanMessage(content="scan")]})

        assert fake.stream_calls == 1
        assert fake.invoke_calls == 0, "fallback invoke() would double-execute tools"
        assert isinstance(out, dict)
        msgs = out.get("messages", [])
        assert msgs and isinstance(msgs[0], AIMessage)
        assert "produced no state" in str(msgs[0].content)
        assert "scanner" in str(msgs[0].content)

    def test_non_empty_stream_uses_last_state(self, renderer: DummyRenderer) -> None:
        state_final = {"messages": [AIMessage(content="done")]}
        fake = CountingRunnable(stream_items=[state_final])
        wrapper = StreamingRunnable(fake, "scanner")

        out = wrapper.invoke({"messages": [HumanMessage(content="scan")]})

        assert fake.stream_calls == 1
        assert fake.invoke_calls == 0
        assert out is state_final


@pytest.mark.asyncio
class TestAinvokeNoStateReturnsErrorNotDoubleExec:
    """astream() yielding zero states MUST NOT fall back to ainvoke()."""

    async def test_empty_astream_returns_error_without_reinvoking(
        self, renderer: DummyRenderer
    ) -> None:
        fake = CountingRunnable(stream_items=[])
        wrapper = StreamingRunnable(fake, "verifier")

        out = await wrapper.ainvoke({"messages": [HumanMessage(content="verify")]})

        assert fake.astream_calls == 1
        assert fake.ainvoke_calls == 0, "fallback ainvoke() would double-execute tools"
        msgs = out.get("messages", [])
        assert msgs and isinstance(msgs[0], AIMessage)
        assert "produced no state" in str(msgs[0].content)
        assert "verifier" in str(msgs[0].content)

    async def test_non_empty_astream_uses_last_state(self, renderer: DummyRenderer) -> None:
        state_final = {"messages": [AIMessage(content="done")]}
        fake = CountingRunnable(stream_items=[state_final])
        wrapper = StreamingRunnable(fake, "verifier")

        out = await wrapper.ainvoke({"messages": [HumanMessage(content="verify")]})

        assert fake.astream_calls == 1
        assert fake.ainvoke_calls == 0
        assert out is state_final
