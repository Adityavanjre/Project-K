"""LiteLLM startup script — registers custom OAuth handlers before server start.

LiteLLM's YAML-based custom_provider_map registration is unreliable across
versions (litellm_settings may be skipped when database_url is configured).
This script registers handlers explicitly at module import time.

Usage in docker-compose.yml:
  command: ["python", "/app/litellm_startup.py", "--config", "/app/config.yaml", "--port", "4000"]
"""

from __future__ import annotations

import sys

# Register custom OAuth handler before LiteLLM processes the config
sys.path.insert(0, "/app")
import litellm  # noqa: E402
from claude_code_handler import claude_code_handler_instance  # noqa: E402

litellm.custom_provider_map = [
    {"provider": "auth", "custom_handler": claude_code_handler_instance},
]

# Run custom_llm_setup to wire up the provider routing
from litellm.utils import custom_llm_setup  # noqa: E402

custom_llm_setup()

print("[decepticon] auth handler registered", flush=True)

# Start LiteLLM server with remaining CLI args
# run_server() uses Click which reads sys.argv
sys.argv[0] = "litellm"

from litellm import run_server  # noqa: E402

sys.exit(run_server())
