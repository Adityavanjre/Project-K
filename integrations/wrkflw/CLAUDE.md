# wrkflw

## Codebase Navigation — MUST USE indxr MCP tools

An MCP server called `indxr` is available. **Always use indxr tools before the Read tool.** Do NOT read full source files as a first step — use the MCP tools to explore, then read only what you need.

### Token savings reference

| Action | Approx tokens | When to use |
|--------|--------------|-------------|
| `get_tree` | ~200-400 | First: understand directory layout |
| `get_file_summary` | ~200-400 | Understand a file without reading it |
| `batch_file_summaries` | ~400-1200 | Summarize multiple files in one call |
| `get_file_context` | ~400-600 | Understand dependencies and reverse deps |
| `lookup_symbol` | ~100-200 | Find a specific function/type across codebase |
| `search_signatures` | ~100-300 | Find functions by signature pattern |
| `search_relevant` | ~200-400 | Find files/symbols by concept or partial name (supports `kind` filter) |
| `explain_symbol` | ~100-300 | Everything to USE a symbol without reading its body |
| `get_public_api` | ~200-500 | Public API surface of a file or module |
| `get_callers` | ~100-300 | Who references this symbol (imports + signatures) |
| `get_related_tests` | ~100-200 | Find tests for a symbol by naming convention |
| `get_diff_summary` | ~200-500 | Structural changes since a git ref (vs reading raw diffs) |
| `get_hotspots` | ~200-500 | Most complex functions ranked by composite score |
| `get_health` | ~200-400 | Codebase health summary with aggregate complexity metrics |
| `get_type_flow` | ~200-500 | Track which functions produce/consume a type across the codebase |
| `read_source` (symbol) | ~50-300 | Read one function/struct. Supports `symbols` array and `collapse`. |
| `get_token_estimate` | ~100 | Check cost before reading. Supports `directory`/`glob`. |
| `Read` (full file) | **500-10000+** | ONLY when editing or need exact formatting |

### Exploration workflow (follow this order)

1. `search_relevant` — find files/symbols related to your task by concept, partial name, or type pattern. **Start here when you know what you're looking for but not where it is.**
2. `get_tree` — see directory/file layout. Use `path` param to scope to a subtree.
3. `get_file_summary` — get a complete overview of any file without reading it. Use `batch_file_summaries` for multiple files.
4. `get_file_context` — understand a file's reverse dependencies and related files.
5. `lookup_symbol` — find declarations by name across all indexed files.
6. `explain_symbol` — get full interface details for a symbol without reading its body.
7. `search_signatures` — find functions/methods by signature substring.
8. `get_callers` — find who references a symbol.
9. `get_token_estimate` — before deciding to `Read` a file, check how many tokens it costs.
10. `read_source` — read source code by symbol name or line range. Use `symbols` array to read multiple in one call.
11. `get_public_api` — get only public declarations with signatures for a file or directory.
12. `get_related_tests` — find test functions for a symbol.
13. `list_declarations` — list all declarations in a file.
14. `get_imports` — get import statements for a file.
15. `get_stats` — codebase stats: file count, line count, language breakdown.
16. `get_diff_summary` — get structural changes since a git ref.
17. `get_hotspots` — get the most complex functions ranked by composite score.
18. `get_health` — get codebase health summary: aggregate complexity, documentation coverage, test ratio.
19. `get_type_flow` — track where a type flows across function boundaries. Shows producers and consumers.
20. `regenerate_index` — re-index after code changes.

### When to use the Read tool instead
- You need to **edit** a file (Read is required before Edit)
- You need exact formatting/whitespace that `read_source` doesn't preserve
- The file is not a source file (e.g., config files, documentation)

### DO NOT
- Read full source files just to understand what's in them — use `get_file_summary`
- Read full source files to review code — use `get_file_summary` to triage, then `read_source` on specific symbols
- Dump all files into context — use MCP tools to be surgical
- Read a file without first checking `get_token_estimate` if you're unsure about its size
- Use `git diff` to understand changes — use `get_diff_summary` instead

### After making code changes
Run `regenerate_index` to keep INDEX.md current.
