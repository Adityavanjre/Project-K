# Ollama Local Profile

Ollama is the convenience runtime path for the supported local profile.

Start Ollama and pull the supported model pair:

```bash
ollama serve
ollama pull qwen3:4b
ollama pull qwen3-embedding:0.6b
```

Configure RA-H:

```bash
LLM_PROFILE=openai-compatible
LLM_BASE_URL=http://127.0.0.1:11434/v1
LLM_MODEL=qwen3:4b

EMBEDDING_PROFILE=openai-compatible
EMBEDDING_BASE_URL=http://127.0.0.1:11434/v1
EMBEDDING_MODEL=qwen3-embedding:0.6b
EMBEDDING_DIMENSIONS=1024
```

Validate:

```bash
npm run doctor:local-ai
```

Changing `EMBEDDING_MODEL`, `EMBEDDING_DIMENSIONS`, `EMBEDDING_PROFILE`, or `VECTOR_BACKEND` requires a vector rebuild:

```bash
npm run rebuild:embeddings
```

Local utility LLM quality can affect descriptions, extraction summaries, transcript summaries, and edge inference. Keep custom model overrides experimental until they pass your own workflow checks.
