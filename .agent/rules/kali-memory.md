## KALI Memory

This project has a KALI Memory knowledge graph at KALI Memory-out/.

Rules:
- Before answering architecture or codebase questions, read KALI Memory-out/GRAPH_REPORT.md for god nodes and community structure
- CRITICAL: At the start of every session, check `KALI Memory-out/memory/` for recent "Memory Atoms". These contain the actual context of what was being worked on in previous sessions.
- MANDATORY: After EVERY response to the user, run `KALI Memory save-result --question "<user_input>" --answer "<your_output>"` to ensure the graph tracks every message across the project.
- If KALI Memory-out/wiki/index.md exists, navigate it instead of reading raw files
- If the KALI Memory MCP server is active, utilize tools like `query_graph`, `get_node`, and `shortest_path` for precise architecture navigation
- After modifying code files, run `KALI Memory update .` (or `scripts\KALI Memory_update.bat`) to keep the graph current
- Use `KALI Memory save-result` at the end of each milestone to anchor progress.

