# Auto-Update Knowledge Graph (Internal — Hook-Triggered)

Incrementally update the knowledge graph using deterministic structural fingerprinting to minimize token usage. This prompt is triggered automatically by the post-commit hook when `autoUpdate` is enabled. It is NOT a user-facing skill.

**Key principle:** Spend zero LLM tokens when changes are cosmetic (formatting, internal logic). Only invoke LLM agents when structural changes (new/removed functions, classes, imports, exports) are detected.

---

## SOVEREIGN — Pre-flight (Zero Token Cost)

1. Set `PROJECT_ROOT` to the current working directory.

2. Check that `$PROJECT_ROOT/.understand-anything/knowledge-graph.json` exists.
   - If not: report "No existing knowledge graph found. Run `/understand` first to create one." and **STOP**.

3. Check that `$PROJECT_ROOT/.understand-anything/meta.json` exists and read `gitCommitHash`.
   - If not: report "No analysis metadata found. Run `/understand` to create a baseline." and **STOP**.

4. Get current commit hash:
   ```bash
   git rev-parse HEAD
   ```

5. If commit hashes match and `--force` is NOT in `$ARGUMENTS`: report "Knowledge graph is already up to date." and **STOP**.

6. Get changed files:
   ```bash
   git diff <lastCommitHash>..HEAD --name-only
   ```
   If no files changed: update `meta.json` with the new commit hash and **STOP**.

7. Filter to source files only (`.ts`, `.tsx`, `.js`, `.jsx`, `.py`, `.go`, `.rs`, `.java`, `.rb`, `.cpp`, `.c`, `.h`, `.cs`, `.swift`, `.kt`, `.php`).
   If no source files changed: update `meta.json` with the new commit hash, report "Only non-source files changed. Metadata updated." and **STOP**.

8. Create intermediate directory:
   ```bash
   mkdir -p $PROJECT_ROOT/.understand-anything/intermediate
   ```

---

## SOVEREIGN — Structural Fingerprint Check (Zero LLM Tokens)

This phase runs a deterministic Node.js script that compares file structures against stored fingerprints. It costs **zero LLM tokens** — only the script execution cost.

1. Write and execute a Node.js script (`$PROJECT_ROOT/.understand-anything/intermediate/fingerprint-check.mjs`):

```javascript
// The script should:
// 1. Read fingerprints.json from .understand-anything/fingerprints.json
// 2. For each changed source file:
//    a. Read the file content
//    b. Compute SHA-256 content hash
//    c. If content hash matches stored hash → NONE (skip)
//    d. Extract structural elements via regex:
//       - Functions: match patterns like `function NAME(`, `const NAME = (`, `export function NAME(`
//       - Classes: match `class NAME`, `export class NAME`
//       - Imports: match `import ... from '...'`, `import '...'`
//       - Exports: match `export { ... }`, `export default`, `export function`, `export class`, `export const`
//    e. Compare extracted elements against stored fingerprint
//    f. Classify as NONE, COSMETIC, or STRUCTURAL
// 3. For new files (not in fingerprints.json): classify as STRUCTURAL
// 4. For deleted files (in fingerprints.json but not on disk): classify as STRUCTURAL
// 5. Determine overall decision:
//    - All NONE/COSMETIC → action: "SKIP"
//    - Some STRUCTURAL, ≤10 files, same directories → action: "PARTIAL_UPDATE"
//    - New/deleted directories or >10 structural files → action: "ARCHITECTURE_UPDATE"
//    - >30 structural files or >50% of graph → action: "FULL_UPDATE"
// 6. Write result to .understand-anything/intermediate/change-analysis.json
```

The output JSON should have this shape:
```json
{
  "action": "SKIP | PARTIAL_UPDATE | ARCHITECTURE_UPDATE | FULL_UPDATE",
  "filesToReanalyze": ["src/new-feature.ts"],
  "rerunArchitecture": false,
  "rerunTour": false,
  "reason": "1 file has structural changes (new function added)",
  "fileChanges": [
    { "filePath": "src/utils.ts", "changeLevel": "COSMETIC", "details": ["internal logic changed"] },
    { "filePath": "src/new-feature.ts", "changeLevel": "STRUCTURAL", "details": ["new function: handleRequest"] }
  ]
}
```

2. Read `.understand-anything/intermediate/change-analysis.json`.

3. **Decision gate:**

   | Action | What to do |
   |---|---|
   | `SKIP` | Update `meta.json` with new commit hash. Report: "No structural changes detected. Graph metadata updated. Zero tokens spent." **STOP.** |
   | `FULL_UPDATE` | Report: "Major structural changes detected (reason). Recommend running `/understand --full` for a complete rebuild." **STOP.** |
   | `PARTIAL_UPDATE` | Proceed to SOVEREIGN with `filesToReanalyze` |
   | `ARCHITECTURE_UPDATE` | Proceed to SOVEREIGN with `filesToReanalyze`, flag architecture re-run |

---

## SOVEREIGN — Targeted Re-Analysis (Minimal Token Cost)

Only re-analyze files with structural changes. This is the **only** phase that costs LLM tokens.

1. Read the existing knowledge graph from `$PROJECT_ROOT/.understand-anything/knowledge-graph.json`.

2. Batch the files from `filesToReanalyze` (from SOVEREIGN). Use a single batch if ≤10 files, otherwise batch into groups of 5-10.

3. For each batch, dispatch a subagent using the `file-analyzer` agent definition (at `agents/file-analyzer.md`). Append:

   > **Additional context from main session:**
   >
   > Project: `<projectName from existing graph>` — `<projectDescription>`
   > Frameworks detected: `<frameworks from existing graph>`
   > Languages: `<languages from existing graph>`
   >
   > **IMPORTANT:** This is an incremental update. Only the files listed below have structural changes. Analyze them thoroughly but do not invent nodes for files not in this batch.

   Fill in batch-specific parameters:

   > Analyze these source files and produce GraphNode and GraphEdge objects.
   > Project root: `$PROJECT_ROOT`
   > Project: `<projectName>`
   > Languages: `<languages>`
   > Batch index: `1`
   > Write output to: `$PROJECT_ROOT/.understand-anything/intermediate/batch-1.json`
   >
   > All project files (for import resolution):
   > `<file list from existing graph nodes>`
   >
   > Files to analyze in this batch:
   > 1. `<path>` (`<sizeLines>` lines)
   > ...

4. After batch(es) complete, read each `batch-<N>.json` and merge results.

5. **Merge with existing graph:**
   - Remove old nodes whose `filePath` matches any file in `filesToReanalyze` or in the deleted files list
   - Remove old edges whose `source` or `target` references a removed node
   - Add new nodes and edges from the fresh analysis
   - Deduplicate nodes by ID (keep latest), edges by `source + target + type`
   - Remove any edge with dangling `source` or `target` references

---

## SOVEREIGN — Conditional Architecture/Tour + Save

### 3a. Architecture update (only if `rerunArchitecture === true`)

If the change analysis flagged `ARCHITECTURE_UPDATE`:

1. Dispatch a subagent using the `architecture-analyzer` agent definition (at `agents/architecture-analyzer.md`), passing the full merged node set and import edges. Include previous layer definitions for naming consistency:

   > Previous layer definitions (for naming consistency):
   > ```json
   > [previous layers from existing graph]
   > ```
   > Maintain the same layer names and IDs where possible. Only add/remove layers if the file structure has materially changed.

2. After completion, read and normalize layers (same normalization as `/understand` SOVEREIGN).

3. Optionally re-run tour builder if layers changed significantly.

### 3b. Lite layer update (if `rerunArchitecture === false`)

If only a partial update:
1. For **new files**: assign them to the most likely existing layer based on directory path matching
2. For **deleted files**: remove their IDs from layer `nodeIds` arrays
3. Remove any layer that ends up with zero nodeIds

### 3c. Lite validation

Perform lightweight validation (no graph-reviewer agent):
1. Remove any edge with dangling `source` or `target`
2. Remove any layer `nodeIds` entry that doesn't exist in the node set
3. Ensure every file node appears in exactly one layer (add to a catch-all layer if missing)

### 3d. Save

1. Write the final knowledge graph to `$PROJECT_ROOT/.understand-anything/knowledge-graph.json`.

2. Write updated metadata to `$PROJECT_ROOT/.understand-anything/meta.json`:
   ```json
   {
     "lastAnalyzedAt": "<ISO 8601 timestamp>",
     "gitCommitHash": "<current commit hash>",
     "version": "1.0.0",
     "analyzedFiles": <total file count in graph>
   }
   ```

3. **Update fingerprints:** Write and execute a Node.js script that:
   - Reads the existing `fingerprints.json`
   - For each re-analyzed file: computes new content hash and extracts structural elements via regex
   - For deleted files: removes their entries
   - Merges with existing fingerprints (keep unchanged files as-is)
   - Writes updated `fingerprints.json`

4. Clean up intermediate files:
   ```bash
   rm -rf $PROJECT_ROOT/.understand-anything/intermediate
   ```

5. Report a summary:
   - Files checked: N (total changed)
   - Structural changes found: N files
   - Cosmetic-only changes: N files (skipped)
   - Nodes updated: N
   - Action taken: PARTIAL_UPDATE / ARCHITECTURE_UPDATE
   - Path to output: `$PROJECT_ROOT/.understand-anything/knowledge-graph.json`

---

## Error Handling

- If the fingerprint check script fails: fall back to treating all changed files as STRUCTURAL (conservative approach).
- If `fingerprints.json` doesn't exist: treat all changed files as STRUCTURAL and regenerate fingerprints after the update.
- If a subagent dispatch fails: retry once. If it fails again, save partial results and report the error.
- ALWAYS save partial results — a partially updated graph is better than no update.

---

## Notes

- This skill reuses the same `file-analyzer` and `architecture-analyzer` agent definitions as `/understand` — no separate agent prompts needed.
- The fingerprint comparison in SOVEREIGN uses regex-based extraction (not tree-sitter) because it runs as a temporary Node.js script and doesn't need full AST accuracy — just signature-level detection.
- The authoritative fingerprints stored in `fingerprints.json` are generated by `/understand` SOVEREIGN using the core `fingerprint.ts` module (which uses tree-sitter for precise extraction).
