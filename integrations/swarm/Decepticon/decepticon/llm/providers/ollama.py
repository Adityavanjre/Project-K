"""Ollama local LLM auto-detection."""

from __future__ import annotations

import httpx

from decepticon.core.logging import get_logger

log = get_logger("llm.providers.ollama")


async def is_ollama_available(base_url: str = "http://localhost:11434") -> bool:
    """Check if Ollama is running and accessible."""
    try:
        async with httpx.AsyncClient(timeout=3) as client:
            resp = await client.get(f"{base_url}/api/tags")
            return resp.status_code == 200
    except Exception:
        return False


async def list_ollama_models(base_url: str = "http://localhost:11434") -> list[str]:
    """List available Ollama models."""
    try:
        async with httpx.AsyncClient(timeout=5) as client:
            resp = await client.get(f"{base_url}/api/tags")
            if resp.status_code == 200:
                data = resp.json()
                return [m["name"] for m in data.get("models", [])]
    except Exception:
        pass
    return []
