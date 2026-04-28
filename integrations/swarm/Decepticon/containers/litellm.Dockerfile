FROM ghcr.io/berriai/litellm:main-v1.82.3-stable.patch.2

# xxhash is required for CCH (Claude Code Hash) request signing
RUN pip install --no-cache-dir xxhash

COPY config/claude_code_handler.py /app/claude_code_handler.py
COPY config/litellm_startup.py /app/litellm_startup.py
