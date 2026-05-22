# llama.cpp Local Profile

llama.cpp is the direct runtime path for users who want explicit model file and server control.

Run separate servers for chat and embeddings:

```bash
llama-server -m /models/qwen3-4b.gguf --port 8080
llama-server -m /models/qwen3-embedding-0.6b.gguf --embedding --port 8081
```

Configure RA-H:

```bash
npm run setup:local -- --profile llama-cpp
```

That writes this profile to `.env.local`:

```bash
LLM_PROFILE=openai-compatible
LLM_BASE_URL=http://127.0.0.1:8080/v1
LLM_MODEL=qwen3-4b

EMBEDDING_PROFILE=openai-compatible
EMBEDDING_BASE_URL=http://127.0.0.1:8081/v1
EMBEDDING_MODEL=qwen3-embedding-0.6b
EMBEDDING_DIMENSIONS=1024
```

Validate:

```bash
npm run doctor:local-ai
```

RA-H does not download GGUF files for you. Install llama.cpp, place model files on disk, start the server processes, then point RA-H at the `/v1` endpoints.
