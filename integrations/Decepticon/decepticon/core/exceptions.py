"""Decepticon exception hierarchy."""


class DecepticonError(Exception):
    """Base exception for all Decepticon errors."""


class ConfigError(DecepticonError):
    """Configuration errors (missing file, invalid YAML, etc.)."""


class LLMError(DecepticonError):
    """LLM-related errors (provider failure, model not found, etc.)."""


class SandboxError(DecepticonError):
    """Docker sandbox errors."""
