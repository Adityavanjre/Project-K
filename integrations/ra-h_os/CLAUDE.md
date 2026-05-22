# RA-OS

## What This Is
Open-source, local-first knowledge graph app with MCP integration.

## Core Stack
- Next.js 15 + TypeScript + Tailwind
- SQLite + sqlite-vec
- BYO API keys (OpenAI/Anthropic)

## Run Locally
```bash
git clone https://github.com/bradwmorris/ra-h_os.git
cd ra-h_os
npm install
npm run setup:local
npm run dev
```

## MCP Setup
```bash
npx -y ra-h-mcp-server@latest setup --client claude-code --yes
```

## Source of Truth for Workflow
- `AGENTS.md` - agent and contributor workflow
- `CONTRIBUTING.md` - PR and contribution policy

## Key Paths
- `src/services/database/` - data layer
- `src/tools/` - MCP tool implementations
- `src/config/skills/` - built-in skill content
- `app/api/` - API routes

## Docs
- `docs/README.md`
- `docs/0_overview.md`
- `docs/2_schema.md`
- `docs/4_tools-and-guides.md`
- `docs/6_ui.md`
- `docs/8_mcp.md` - includes MCP setup plus recommended memory-file guidance
