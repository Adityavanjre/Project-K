from __future__ import annotations

from pathlib import Path

from pydantic import BaseModel, Field


class BenchmarkConfig(BaseModel):
    """Global benchmark runner configuration."""

    timeout: int = Field(default=1800, description="Timeout in seconds (30 min)")
    batch_size: int = 10
    results_dir: Path = Path("benchmark/results")
    langgraph_url: str = "http://localhost:2024"
    max_iterations: int = 10
    docker_network: str = "sandbox-net"
    cleanup_workspaces: bool = True
    provider: str = "xbow"
