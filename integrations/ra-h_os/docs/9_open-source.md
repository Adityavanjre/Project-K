# Open Source Surface

`ra-h_os` should match the main app contract wherever the underlying product behavior is shared.

That means the open-source docs should reflect:

- no runtime `dimensions` model,
- node quality driven by title, description, source, metadata, and edges.

It should also explain the open-source-specific reality clearly:
- no private-app-only promises
- a practical standalone MCP install path
- pinned package versions for external-agent setup
- clear verification and troubleshooting steps
- honest support boundaries for fully local or community setups

## Important App Routes

- `app/api/nodes/`
- `app/api/edges/`
- `app/api/rah/chat/`
- extraction routes
- eval / verification helpers

## Porting Rule

Main `ra-h` ships first.

`ra-h_os` is a required follow-up port of the same contract, not a place to preserve older taxonomy behavior.

## Required Docs Surfaces In `ra-h_os`

- `README.md` for terse install + MCP quickstart
- `docs/README.md` for the start-here path
- `docs/8_mcp.md` for the full MCP setup, verification, memory-file guidance, and troubleshooting path
- `docs/10_full-local.md` for clearly caveated local/community patterns
- `apps/mcp-server-standalone/README.md` for package-level install details that match the repo docs
