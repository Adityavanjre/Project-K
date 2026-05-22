# MCP Surface

RA-H exposes MCP tools for direct graph work against the local database or app API.

## Quick Install

For normal users, configure MCP through the published package:

```bash
npx -y ra-h-mcp-server@latest setup --client claude-code --yes
```

Other clients:

```bash
npx -y ra-h-mcp-server@latest setup --client cursor --yes
npx -y ra-h-mcp-server@latest setup --client codex --yes
npx -y ra-h-mcp-server@latest setup --client claude-code,codex --yes
```

`--client` accepts a single client or comma-separated clients. `--yes` lets the installer write supported client config automatically. Codex uses TOML config, so the installer writes `CODEX_HOME/config.toml` or `~/.codex/config.toml`.

Verify the install:

```bash
npx -y ra-h-mcp-server@latest doctor
```

Manual JSON/TOML config should be treated as troubleshooting or unsupported-client fallback. Public docs should not point users at stale pinned versions; use `@latest` by default and pin exact versions only for release/debug reproducibility.

For demo isolation or a separate DB:

```bash
npx -y ra-h-mcp-server@latest setup \
  --client claude-code,codex \
  --yes \
  --install-rules \
  --target "$HOME/Desktop/ra-h_os-demo" \
  --db "$HOME/Desktop/ra-h_os-demo-data/rah.sqlite"
```

Important runtime distinction:

- the app MCP surface talks to the running app/API
- the standalone MCP surface talks directly to an existing SQLite DB file
- standalone MCP can read and write nodes/edges without the app running, but it does not own chunking or embedding
- if standalone MCP writes `nodes.source` while the app is closed, the app later processes that node through startup recovery
- external MCP agent model choice is separate from RA-H app utility model choice; app utility LLMs and embeddings use `LLM_PROFILE` and `EMBEDDING_PROFILE`

## WAL / Multi-Surface Safety

- RA-H uses SQLite WAL as the normal local multi-surface model.
- The app, standalone MCP, Claude/Codex, and normal reads can coexist.
- Normal writes should be short; lock collisions wait through SQLite `busy_timeout` plus retry/backoff where supported.
- Standalone MCP remains first-class and does not require the app to be open.
- Dangerous maintenance is different from normal reads/writes: restore, DB replacement, checkpoint/truncate, and deleting `rah.sqlite-wal` / `rah.sqlite-shm` require all app/dev/MCP DB owners to be closed first.
- Use `scripts/database/rah-db-owners.sh "$HOME/Library/Application Support/RA-H/db/rah.sqlite"` before destructive maintenance.

## Core MCP Contract

- `queryNodes` is the primary tool for direct node retrieval when the user is trying to find a specific existing node.
- `retrieveQueryContext` is the primary retrieval entrypoint for substantive current-turn work when the agent needs graph context to support a broader answer.
- `getContext` returns graph orientation: stats, hubs, and skills.
- `createEdge` is a post-confirmation execution tool. Agents should propose likely edges first and only write them after the user explicitly confirms.
- `queryNodes` searches title, description, and source.
- `dimensions` are removed from the MCP contract.
- `contexts` and context-capsule tools are removed from the MCP contract.

## Behavior Split

Internal app MCP surfaces:
- talk to the running app/API
- can participate in the live app runtime and UI refresh model

Standalone MCP:
- talks directly to an existing SQLite DB
- can read and write nodes, edges, and skills without the app running
- does not own chunking, vector generation, or schema migration on a live existing DB
- relies on the app to process pending `nodes.source` work later

## Main Tools

Read:
- `retrieveQueryContext`
- `getContext`
- `queryNodes`
- `getNodesById`
- `queryEdge`
- `listSkills`
- `readSkill`
- `searchContentEmbeddings`
- `sqliteQuery`

Write:
- `createNode`
- `updateNode`
- `createEdge`
- `updateEdge`
- `writeSkill`
- `deleteSkill`

## Tool Behavior

- Always search before creating.
- If the user is trying to find a specific existing node, use `queryNodes` first.
- If the user is asking a broader question that would benefit from graph context, use `retrieveQueryContext`.
- Optional user memory reinforcement can help, but the MCP tools, instructions, skills, and docs should be enough for the core retrieval and writeback contract to work.
- If the user explicitly asked to save or update something and the target artifact is clear, the agent can write after duplicate/update checks.
- If the agent is only suggesting a save, it should propose the node first and wait for confirmation.
- When obvious relationships appear, propose candidate edges briefly rather than writing them automatically.
- Judge graph quality by node quality and edges, not taxonomy completeness.
- Keep writeback prompts terse and selective. The goal is not to ask constantly whether every useful sentence should be saved.
- Do not assume MCP node creation immediately produces chunks or embeddings. The canonical contract is:
  - write node data first
  - app-owned pipeline later creates readable chunks, FTS rows, `vec_nodes`, and `vec_chunks`
- Do not use `chunk_status = 'chunked'` as a promise that every chunk has a row in `vec_chunks`. Chunking and vector coverage are related but distinct.

## Search And Indexing Notes

MCP users should understand the same retrieval split as the app:

- direct node lookup searches node title, description, and source
- full-text search can match literal words in nodes or chunks
- chunk search can find passages inside long source text
- `vec_nodes` can find semantically similar whole nodes when node-level vectors exist
- `vec_chunks` can find semantically similar passages when chunk-level vectors exist
- standalone MCP does not generate embeddings itself
- with the local model profile, the app later calls your configured OpenAI-compatible endpoints for descriptions, summaries, and embeddings

If an external agent creates or updates a node through standalone MCP while the app is closed, the node can exist before its chunks and vectors do. The app-owned pipeline processes that later.

## Memory-File Rule

Optional assistant memory files can reinforce good behavior, but they are not supposed to be the hidden dependency that makes RA-H work.

Current rule:
- MCP tools, server instructions, skills, and docs should be enough for the base contract
- optional reinforcement can still improve consistency
- keep one canonical memory file when possible
- avoid contradictory instruction files across `CLAUDE.md`, `AGENTS.md`, and other client-specific memory surfaces

Recommended guidance:
- keep the language short and simple
- focus on graph behavior, not tool micromanagement
- prefer one shared snippet over separate client-specific doctrines

Suggested memory-file snippet:

```md
## RA-H Graph Memory

You are helping build a thoughtful graph of atomic units of context.

- Use `queryNodes` for direct lookup of a specific existing node.
- Use `retrieveQueryContext` when broader graph context would help with the current turn.
- Search before creating. Prefer updating the same artifact when it is clearly the same thing.
- `description` should state plainly what the thing is first, then why it belongs and current status.
- Preserve the user's wording in `source` for user-authored ideas unless they explicitly want a rewrite.
```

The installer can add or refresh this section without replacing the rest of the memory file:

```bash
npx -y ra-h-mcp-server@latest install-rules --client claude-code,codex --target . --yes
```
