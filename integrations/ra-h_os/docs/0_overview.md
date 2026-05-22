# RA-H Overview

## What is RA-H?

RA-H is a local-first knowledge graph for durable thinking. It captures sources, ideas, people, decisions, and conversations into one graph on your machine, then lets you retrieve and extend that graph through the app and MCP.

**Website:** [ra-h.app](https://ra-h.app)
**Open Source:** [github.com/bradwmorris/ra-h_os](https://github.com/bradwmorris/ra-h_os)

**New here?** Open chat and say `let's get started` to run the onboarding skill.

## Design Philosophy

RA-H is built on the idea that capture quality matters more than taxonomy.

**Non-prescriptive** — RA-H does not require folders or dimensions. It pushes clearer nodes and clearer edges instead of category maintenance.

**Everything is connected** — Every piece of knowledge can potentially connect to any other. Connections aren't just links — they carry context, explanation, and meaning.

**Local-first** — Your knowledge network belongs to you, not a platform. Your thinking, research, and connections all belong to you in a portable format you control.

**Human + AI** — You guide, AI assists. Skills and graph quality shape behavior; the graph is not supposed to silently self-organize into truth without you.

## Tech Stack

- **Frontend:** Next.js 15, TypeScript, Tailwind CSS
- **Database:** SQLite + sqlite-vec (vector search)
- **AI Models:** Anthropic Claude + OpenAI GPT via Vercel AI SDK
- **Desktop:** Tauri (Mac app)
- **MCP Server:** Local connector for Claude Code and external agents

## Current Status

- **Version:** current internal product contract as of April 2026
- **Platforms:**
  - Mac app (download at [ra-h.app/download](https://ra-h.app/download))
  - Open source self-hosted (BYO API keys)
- **License:** MIT (open source version)

## Two Ways to Use RA-H

| Version | Best For | Get It |
|---------|----------|--------|
| **Mac App** | Most users. One-click install, auto-updates, optional subscription features | [ra-h.app/download](https://ra-h.app/download) |
| **Open Source** | Developers, self-hosters, contributors. BYO API keys, full control | [GitHub](https://github.com/bradwmorris/ra-h_os) |

Both versions follow the same core graph contract. The Mac app adds packaging, auth, voice, and subscription surfaces. `ra-h_os` keeps the local graph, UI, and MCP path.

## Key Features

- **Source-first graph:** node quality comes from title, description, source, metadata, and edges
- **Graph-first capture:** durable structure comes from nodes and edges, not category maintenance
- **Flexible pane system:** explicit `1 / 2 / 3` pane workspace with right-edge chat
- **Single assistant:** one built-in RA-H runtime grounded in your graph and skills
- **Retrieval split:** direct lookup for specific nodes, broader retrieval when the turn actually needs graph context
- **Indexed retrieval:** source text becomes readable chunks, full-text indexes, and semantic vectors
- **MCP server:** connect Claude Code and other external agents to the same graph
- **Skills:** markdown procedures that shape graph work and agent behavior
- **Extraction tools:** website, YouTube, and PDF ingestion paths

## Documentation

| Doc | Description |
|-----|-------------|
| [Architecture](./1_architecture.md) | Single-agent runtime, tools, and system design |
| [Schema + Search](./2_schema.md) | Database schema, indexing, and retrieval surfaces |
| [Grounding](./3_context.md) | How graph grounding flows through the system |
| [Tools & Skills](./4_tools-and-guides.md) | Available tools, skill system |
| [UI](./6_ui.md) | Component structure, panels, views |
| [Voice](./7_voice.md) | Voice interface (STT/TTS) |
| [MCP](./8_mcp.md) | External agent connector setup |
| [Open Source](./9_open-source.md) | Contributor and sync guide |
