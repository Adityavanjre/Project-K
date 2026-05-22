# RA-H OS Documentation

```
 ██████╗  █████╗       ██╗  ██╗
 ██╔══██╗██╔══██╗      ██║  ██║
 ██████╔╝███████║█████╗███████║
 ██╔══██╗██╔══██║╚════╝██╔══██║
 ██║  ██║██║  ██║      ██║  ██║
 ╚═╝  ╚═╝╚═╝  ╚═╝      ╚═╝  ╚═╝
```

## Quick Links

| Doc | Description |
|-----|-------------|
| [Overview](./0_overview.md) | What RA-H OS is and what contract it shares with the main app |
| [Schema + Search](./2_schema.md) | Current SQLite contract, indexing, and retrieval surfaces |
| [Tools & Skills](./4_tools-and-guides.md) | MCP tools and skill system |
| [Logging & Evals](./5_logging-and-evals.md) | Logs, evals, and debugging surfaces |
| [UI](./6_ui.md) | Current pane and focus model |
| [MCP](./8_mcp.md) | Full standalone MCP install, behavior guide, and memory-file guidance |
| [Open Source](./9_open-source.md) | Scope, support boundary, contributor reality |
| [Full Local](./10_full-local.md) | Supported local path vs community patterns |
| [Local Models](../LOCAL-MODELS.md) | OpenAI-compatible local endpoint profile |
| [Qdrant](../QDRANT-DEPLOYMENT.md) | Optional vector sidecar for sqlite-vec-hostile environments |
| [Troubleshooting](./TROUBLESHOOTING.md) | Common issues and fixes |

## Start Here

If you just want RA-H OS working:
1. Use the OpenAI local app quick start if you want the simplest setup.
2. Use the local Qwen/Ollama quick start if you want local models with the least runtime work.
3. Use the local Qwen/llama.cpp quick start if you want to manage GGUF files and llama.cpp servers yourself.
4. Connect MCP after the app database exists if you want Claude Code, Codex, Cursor, or another agent to read/write the same graph.

Every app path uses a local SQLite database. OpenAI setup keeps the database local but sends utility-model and embedding requests to OpenAI. Local Qwen setup keeps the database local and runs both model roles on your device through Ollama or llama.cpp, so those model calls do not go to a hosted model API.

## Local App Quick Start: OpenAI

```bash
git clone https://github.com/bradwmorris/ra-h_os.git
cd ra-h_os
npm install
npm run setup:local -- --profile openai
npm run dev
```

Open http://localhost:3000 and add your OpenAI API key when prompted, or later in Settings -> API Keys.

## Local App Quick Start: Local Qwen/Ollama

Requires Ollama to be installed and running.

```bash
git clone https://github.com/bradwmorris/ra-h_os.git
cd ra-h_os
npm install
ollama pull qwen3:4b
ollama pull qwen3-embedding:0.6b
npm run setup:local -- --profile qwen-local
npm run dev
```

Open http://localhost:3000. Settings -> API Keys shows the active local model profile and disables OpenAI key entry.

## Local App Quick Start: Local Qwen/llama.cpp

Requires llama.cpp to be installed, compatible Qwen GGUF files to exist on disk, and separate OpenAI-compatible servers to be running.

Example servers:

```bash
llama-server -m /models/qwen3-4b.gguf --port 8080
llama-server -m /models/qwen3-embedding-0.6b.gguf --embedding --port 8081
```

Then set up RA-H:

```bash
git clone https://github.com/bradwmorris/ra-h_os.git
cd ra-h_os
npm install
npm run setup:local -- --profile llama-cpp
npm run dev
```

Open http://localhost:3000. Settings -> API Keys shows the active local model profile and disables OpenAI key entry.

Fresh app setup must choose `--profile openai`, `--profile qwen-local`, or `--profile llama-cpp` before vector tables are created. OpenAI embeddings use width `1536`; the supported Qwen embedding profiles use width `1024`.

## MCP Integration

Configure MCP after the app database exists. MCP should point at the same SQLite file as the app.

If you used the default database path:

```bash
npx -y ra-h-mcp-server@latest setup --client claude-code,codex --yes
```

If you set `SQLITE_DB_PATH` during app setup, pass that exact same path:

```bash
npx -y ra-h-mcp-server@latest setup \
  --client claude-code,codex \
  --yes \
  --db "/absolute/path/to/rah.sqlite"
```

Manual config is only for troubleshooting or unsupported clients:

```json
{
  "mcpServers": {
    "ra-h": {
      "command": "npx",
      "args": ["-y", "ra-h-mcp-server@latest"]
    }
  }
}
```

If you need a frozen version for release/debug work, pin it intentionally and restart the client.

The selected setup profile creates the default database if it does not exist. By default, that database is in the operating system's app-data folder, not inside the cloned repo:

```text
~/Library/Application Support/RA-H/db/rah.sqlite   # macOS
~/.local/share/RA-H/db/rah.sqlite                  # Linux
%APPDATA%/RA-H/db/rah.sqlite                       # Windows
```

Set `SQLITE_DB_PATH` before setup if you want a repo-local DB, demo DB, or any other separate location. If MCP should use that same non-default database, pass the same path to the MCP installer with `--db`.

The standalone MCP server can write nodes without the app running, but the app owns chunking and embedding from node source: readable `chunks`, full-text indexes, `vec_nodes`, and `vec_chunks`. See [MCP docs](./8_mcp.md) for the full install, verify, memory-file, and troubleshooting path.

## Questions?

Open an issue on [GitHub](https://github.com/bradwmorris/ra-h_os).
