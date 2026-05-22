# Local Models

RA-H does not run model weights directly. You run a local OpenAI-compatible model server, then RA-H calls that server over HTTP.

The supported local profile is intentionally narrow:

- Utility LLM: Qwen3 4B or the closest tested Qwen3 4B runtime equivalent
- Embeddings: Qwen3 Embedding 0.6B
- Embedding dimensions: `1024`
- Runtime options behind the same contract: Ollama or llama.cpp

OpenAI remains the default supported path. Local mode is for users who are comfortable installing a model runtime, pulling model weights, starting local server processes, and managing rebuilds when embedding settings change.

## Core Env

Ollama:

```bash
LLM_PROFILE=openai-compatible
LLM_BASE_URL=http://127.0.0.1:11434/v1
LLM_MODEL=qwen3:4b

EMBEDDING_PROFILE=openai-compatible
EMBEDDING_BASE_URL=http://127.0.0.1:11434/v1
EMBEDDING_MODEL=qwen3-embedding:0.6b
EMBEDDING_DIMENSIONS=1024
```

llama.cpp:

```bash
LLM_PROFILE=openai-compatible
LLM_BASE_URL=http://127.0.0.1:8080/v1
LLM_MODEL=qwen3-4b

EMBEDDING_PROFILE=openai-compatible
EMBEDDING_BASE_URL=http://127.0.0.1:8081/v1
EMBEDDING_MODEL=qwen3-embedding-0.6b
EMBEDDING_DIMENSIONS=1024
```

Run:

```bash
npm run doctor:local-ai
```

If you change embedding provider, model, dimensions, or vector backend after data exists, run:

```bash
npm run rebuild:embeddings
```

## Vector Storage

Qwen3 creates vectors. sqlite-vec or Qdrant stores and searches those vectors.

You do not need Qdrant just because models are local. Use Qdrant when sqlite-vec is unavailable or unreliable on your platform, especially Alpine/musl Docker images, Windows ARM64, or other native-extension-hostile environments.

SQLite remains the source-of-truth database. Qdrant stores only derived vector indexes.
