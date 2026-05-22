# Documentation Process (RA-OS)

Docs should be short, accurate, and easy to scan. Prefer clarity over completeness.

## Where Things Live

- `README.md` — one-page product + quick start.
- `docs/README.md` — docs index (add new docs here).
- `docs/0_overview.md` — product overview + core concepts.
- `docs/4_tools-and-guides.md` — MCP tools + guides.
- `docs/8_mcp.md` — setup + troubleshooting for MCP.

## Update Rules

- If behavior changes, update the relevant doc and the docs index.
- If MCP tools change, update both the tools table and the schemas.
- If the UI changes meaningfully, update `docs/6_ui.md`.
- Keep naming consistent: **RA-OS** only.

## Style Guidelines

- Use short sections and bullets.
- Keep code blocks minimal and copy-pastable.
- Use ASCII art sparingly (hero or section headers only).
- Avoid hype and marketing tone in docs.

## Media

- Place screenshots/GIFs in `docs/assets/`.
- Keep GIFs under 5MB.
- Prefer static screenshots when possible.

## Docs QA

- Read each changed doc top-to-bottom.
- Verify all paths and commands.
- Ensure the quick start still works on a clean clone.
