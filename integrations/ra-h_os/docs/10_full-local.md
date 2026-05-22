# Fully Local / Community Patterns

This page is for users who want to stay as local as possible without pretending every local-first stack is equally supported.

## 1. What "Fully Local" Means In RA-H Terms

In RA-H terms, "fully local" usually means:
- your graph lives in local SQLite
- the UI runs locally
- your MCP server runs locally
- you avoid shipping graph data to hosted backends where possible

That does not automatically mean every part of the stack is equally local. Model choice, embeddings, and alternate vector backends change that.

## 2. The Supported Baseline Local Stack

Supported core path:
- RA-H OS app
- local SQLite DB
- standard standalone MCP server
- documented repo install flow
- OpenAI model APIs by default, or the documented OpenAI-compatible local endpoint profile

This is the path the core docs and troubleshooting are written for.

Supported local model profile:
- RA-H calls a local OpenAI-compatible HTTP endpoint
- the local runtime can be Ollama or llama.cpp after you start it yourself
- the initial local model pair is Qwen3 4B plus Qwen3 Embedding 0.6B
- embedding dimensions are 1024 unless a tested runtime proves a different supported dimension is needed

Start with [Local Models](../LOCAL-MODELS.md).

## 3. Where Local-First Starts Getting Experimental

Local-first gets more experimental when you change:
- model provider
- embedding provider
- vector backend
- deployment target
- chat/agent client beyond the documented MCP path

That does not make those setups bad. It just changes the support boundary.

## 4. Supported Local Model Profile + RA-H MCP

Supported app utility/embedding pattern:
- keep RA-H OS local
- keep SQLite local
- run a local OpenAI-compatible model server for app utility LLM calls and embeddings
- connect a local-model-capable external client to RA-H through MCP if you want local agent runtime too

Honest caveat:
- tool-calling quality depends heavily on the model/runtime
- smaller local models may perform materially worse than stronger hosted tool-use models
- "fully local" can reduce privacy concerns and improve offline control, but it can also degrade reliability

## 5. Community Pattern: AnythingLLM As Alternate Local Chat / Agent Surface

Based on current public docs:
- AnythingLLM has MCP compatibility
- AnythingLLM supports local-model paths
- Intelligent Tool Selection exists and may matter for local-model performance

This makes it a plausible alternate local chat/agent surface for RA-H MCP.

Caveat:
- MCP support alone does not guarantee strong tool use
- weaker local models can still underperform badly even with a solid MCP integration

References:
- https://docs.anythingllm.com/mcp-compatibility/overview
- https://docs.anythingllm.com/agent/intelligent-tool-selection

## 6. Qdrant Sidecar For `sqlite-vec`-Hostile Environments

Qdrant is a supported optional vector sidecar when:
- `sqlite-vec` is unavailable or unreliable on the target platform
- Alpine/musl, Windows ARM64, or uncertain ARM64 environments make native extensions awkward
- you want Qdrant's vector index while keeping SQLite as the source-of-truth database

Important boundary:
- Qdrant is not required for local embeddings
- Qdrant does not replace SQLite as the app database
- the Nathan Maine repo is a community reference, not the current implementation contract

Start with [Qdrant Deployment](../QDRANT-DEPLOYMENT.md).

References:
- https://qdrant.tech/documentation/quickstart/
- https://github.com/NathanMaine/rah-qdrant-integration

## 7. Honest Tradeoffs

- more local privacy can be better
- offline control can be better
- maintenance burden is usually higher
- tool quality can get worse fast with weaker local models
- troubleshooting becomes more user-owned as you move away from the baseline path

## 8. Support Boundary

Supported core path:
- repo install flow
- SQLite
- documented standalone MCP setup
- OpenAI default AI profile
- documented OpenAI-compatible local endpoint profile
- sqlite-vec default vector backend
- Qdrant fallback backend for sqlite-vec-hostile environments

Reasonable community pattern:
- alternate local chat surface that still respects the MCP contract

Experimental / user-owned:
- arbitrary custom model/provider choices outside the tested local profile
- unsupported runtime targets
- heavily modified inference stacks
