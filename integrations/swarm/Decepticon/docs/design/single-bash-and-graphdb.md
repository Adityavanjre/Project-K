# Decepticon Core Direction: Single Bash Tool + Graph DB Memory

## Why "single bash tool"

Decepticon's offensive execution surface should mirror real operators:

- One command execution primitive (`bash`)
- Real attacker tradecraft expressed as shell command sequences
- Less tool-selection confusion for models
- Better transferability across environments and toolchains

Specialized wrappers (e.g., Kali binary wrappers) are considered **legacy
compatibility layers** and should not be in primary agent tool lists.

## Operational rule

For recon/exploit/postexploit/ad/cloud lanes:

- Use `bash` for security tooling execution (`nmap`, `ffuf`, `sqlmap`, `impacket`, etc.)
- Keep non-exec domain tools only when they provide value that is *not*
  equivalent to command execution (e.g., graph-native reasoning, CVE ranking,
  parser/analysis utilities)

## Knowledge graph migration strategy

Default remains JSON for simplicity and portability:

- `DECEPTICON_KG_BACKEND=json` (default)
- `DECEPTICON_KG_PATH=/workspace/kg.json`

Optional Neo4j backend for larger engagements and multi-agent concurrency:

- `DECEPTICON_KG_BACKEND=neo4j`
- `DECEPTICON_NEO4J_URI=bolt://localhost:7687`
- `DECEPTICON_NEO4J_USER=neo4j`
- `DECEPTICON_NEO4J_PASSWORD=...`
- `DECEPTICON_NEO4J_DATABASE=neo4j` (optional)

Operational notes:
- `docker-compose.yml` includes a `neo4j` service and wires LangGraph to it.
- `scripts/init_neo4j.cypher` provides schema constraints/indexes bootstrap.

The current migration implementation keeps the same in-memory graph model and
switches persistence backend under the `kg_*` tools.

## Differentiating edge (security-focused AGI direction)

Decepticon's unique direction is not "chat UX" — it is **autonomous adversary
execution under constraints**:

1. **Realistic execution substrate**: commands run in isolated Kali sandbox,
   preserving attacker workflow fidelity.
2. **Persistent exploit memory**: graph-backed state survives fresh-agent turns,
   enabling multi-step chain reasoning.
3. **Chain-native planning**: findings are modeled as nodes/edges so campaigns
   optimize for path reachability to crown jewels, not isolated CVEs.
4. **Operational guardrails**: scope/RoE + objective tracking enforce safer,
   auditable autonomy.

This combination moves Decepticon toward a security AGI operator that behaves
closer to real red teams than generic coding assistants.
