# RA-H Schema + Search

RA-H stores the graph in SQLite. SQLite is not just a file dump. It gives RA-H one local structured store for nodes, edges, source chunks, metadata, full-text indexes, and semantic-vector lookup tables.

That matters because an agent can ask the database for likely matches instead of rereading every markdown file from scratch on every turn.

## Core Mental Model

```
User source text
      |
      v
nodes row
  title, description, source, metadata
      |
      +--> nodes_fts      exact node text lookup
      +--> vec_nodes      whole-node semantic lookup
      |
      v
chunks rows
  readable source slices
      |
      +--> chunks_fts     exact passage lookup
      +--> vec_chunks     passage-level semantic lookup
```

## Core Tables

### `nodes`

One durable graph artifact: an idea, source, person, project, decision, transcript, note, or other atomic thing.

Important fields:
- `id`
- `title`
- `description`
- `source`
- `link`
- `metadata`
- `chunk_status`
- `event_date`
- `embedding`
- `embedding_updated_at`
- `embedding_text`
- `created_at`
- `updated_at`

`title` names the thing. `description` says what it is and why it belongs. `source` preserves the original or canonical long-form text.

### `edges`

Explicit relationships between nodes.

Important fields:
- `id`
- `from_node_id`
- `to_node_id`
- `explanation`
- `context`
- `source`
- `created_at`

`edges.explanation` is the human-readable reason the connection exists. `edges.context` is structured JSON metadata, not the main user-facing explanation.

### `chunks`

Readable slices of `nodes.source`.

Shape:
- `id`
- `node_id`
- `chunk_idx`
- `text`
- `embedding_type`
- `metadata`
- `created_at`

`chunks.text` is normal prose. A person can read it. For long source material like transcripts, books, articles, and PDFs, chunks let RA-H find the relevant passage instead of handing the whole source to the model.

### `vec_chunks`

Machine-readable semantic vectors for chunks.

Shape:
- `chunk_id`
- `embedding FLOAT[active embedding dimensions]`

`vec_chunks` is a separate sqlite-vec virtual table. It is table-like, but it is optimized for vector similarity search rather than normal text inspection.

The join point is:

```sql
chunks.id = vec_chunks.chunk_id
```

`chunks.text` is the readable passage. `vec_chunks.embedding` is a long numeric fingerprint of that passage's meaning. The raw vector is not useful prose for a normal user to read.

Concrete live example from the April 20 audit:
- node `5816`: `From IDEs to AI Agents with Steve Yegge`
- chunk `108055`: `chunk_idx = 0`
- chunk text starts with `[0.1s] Tell me about your levels.`
- `vec_chunks` has a matching row where `chunk_id = 108055`
- that row stores a numeric embedding for semantic comparison. OpenAI `text-embedding-3-small` defaults to 1536 dimensions; the supported local Qwen3 embedding profile uses 1024 dimensions.

### `vec_nodes`

Machine-readable semantic vectors for whole nodes.

Shape:
- `node_id`
- `embedding FLOAT[active embedding dimensions]`

The join point is:

```sql
nodes.id = vec_nodes.node_id
```

RA-H also stores node-level embedding data on the node row:
- `nodes.embedding`: the vector BLOB stored on the node
- `nodes.embedding_updated_at`: when the node embedding was last generated
- `nodes.embedding_text`: the readable text RA-H used to make that embedding

Current node-level embedding text includes:
- title
- description
- up to the first 6000 source characters
- a context placeholder, currently usually `none`
- optional AI-generated analysis

Node-level vector search finds likely relevant nodes as whole records. Chunk-level vector search finds likely relevant passages inside long source text.

### `nodes_fts` and `chunks_fts`

FTS means full-text search.

- `nodes_fts` indexes node title, description, and source.
- `chunks_fts` indexes chunk text.

Full-text search is good when the words matter: names, quotes, exact phrases, product names, error messages, or near-literal recall.

### `dimension_migration_snapshots`

Audit-only historical table for the old dimensions removal.

- It stores one-time snapshots of legacy dimension data before dropping old tables.
- It is not part of the live organizing model.

## Schema Diagram

```
nodes
  id
  title
  description
  source
  embedding_text
  embedding
  chunk_status
   |
   | nodes.id = edges.from_node_id / edges.to_node_id
   v
edges
  explanation

nodes.id --------------------> vec_nodes.node_id
                                 whole-node semantic vector

nodes.id --------------------> chunks.node_id
                                 readable source slices
                                  |
                                  | chunks.id = vec_chunks.chunk_id
                                  v
                                vec_chunks
                                  passage-level semantic vector

nodes -----------------------> nodes_fts
                                 title + description + source text index

chunks ----------------------> chunks_fts
                                 passage text index
```

## Ingestion And Indexing Flow

```
Save node
  |
  +--> store title, description, source, metadata in nodes
  |
  +--> update nodes_fts
  |
  +--> build node embedding input
  |       title + description + source preview + optional analysis
  |
  +--> write nodes.embedding + nodes.embedding_text
  |
  +--> write vec_nodes row
  |
  +--> split source into chunks
  |
  +--> write readable chunks rows
  |
  +--> update chunks_fts
  |
  +--> generate one embedding per chunk
  |
  +--> write vec_chunks rows
  |
  v
set chunk_status = chunked
```

Important distinction:
- `chunked` means readable chunk rows exist.
- `vectorized` means matching vector rows also exist in `vec_chunks`.

`chunk_status = 'chunked'` should not be documented as proof that every chunk has a matching vector row unless vector coverage has been checked.

## Search Methods

```
User asks something
  |
  +--> specific known node?
  |       use direct node lookup / queryNodes
  |
  +--> exact words, names, quotes, errors?
  |       use FTS over nodes_fts or chunks_fts
  |
  +--> similar meaning with different words?
  |       use vector search over vec_nodes or vec_chunks
  |
  +--> source passage question?
  |       search chunks, then ground answer in matching passages
  |
  v
combine the strongest evidence with graph neighbors when useful
```

RA-H uses more than one search path because the paths answer different questions.

Full-text search asks: "where do these words appear?"

Semantic search asks: "what has similar meaning even if the words differ?"

Graph traversal asks: "what is connected to this thing, and why?"

## Why SQLite Beats A Loose Markdown Folder For Retrieval

A markdown folder can be a useful source or export layer. It is not the same thing as an indexed local graph.

SQLite gives RA-H:
- one structured local store for nodes, edges, chunks, metadata, and indexes
- fast indexed lookup instead of scanning every file every time
- FTS for literal text and quote-like recall
- embeddings for conceptually similar retrieval
- edges for explicit graph context after retrieval
- integrity checks and repair surfaces for operational confidence

The practical difference: an agent can retrieve a small, relevant slice of the graph quickly, then reason over that slice. With loose markdown, the agent either guesses which files to read or spends tokens scanning too much raw text.

## Embedding Lifecycle

- `nodes.source` is the canonical long-form field for chunking and chunk embeddings.
- Creating or changing `nodes.source` puts the node back through the app-owned chunk pipeline.
- The app pipeline creates or refreshes `chunks`, `chunks_fts`, and `vec_chunks`.
- Standalone MCP can write `nodes.source`, but it does not directly create chunks or vector rows. The app later processes pending nodes.
- Node-level embeddings are separate from chunk embeddings and write to `nodes.embedding`, `nodes.embedding_text`, and `vec_nodes`.
- Deleting a node must remove dependent chunk rows and stale search/vector state.

## Current Live Coverage Caveat

The April 20 audit found current ingestion healthy for recent nodes, but historical vector-table coverage incomplete.

Current status to document carefully:
- recent nodes since `2026-04-16` that have chunks are represented in `vec_chunks`
- older rows can have chunks without matching `vec_chunks`
- some older nodes can have `nodes.embedding` without being present in `vec_nodes`
- successful transcript retrieval may come from vector search, FTS, or text fallback

Historical universal vector coverage is a separate backfill/repair task, not something this docs page should imply is already complete.

## Important Constraints

- `dimensions` and `node_dimensions` are no longer canonical tables.
- New installs should never create them.
- Existing installs migrate by snapshotting old dimension data, then dropping legacy tables.
- The removed `contexts` table and old context capsule are not live product doctrine.
- FTS repair and integrity handling are operational concerns. Do not describe automatic live rebuild behavior as normal product behavior.

## Common Queries

Most connected nodes:

```sql
SELECT n.id, n.title, COUNT(DISTINCT e.id) AS edge_count
FROM nodes n
LEFT JOIN edges e ON (e.from_node_id = n.id OR e.to_node_id = n.id)
GROUP BY n.id
ORDER BY edge_count DESC, n.updated_at DESC
LIMIT 10;
```

Recently updated nodes:

```sql
SELECT id, title, updated_at
FROM nodes
ORDER BY updated_at DESC
LIMIT 25;
```

Check chunk/vector coverage:

```sql
SELECT COUNT(*) AS missing_vectors
FROM chunks c
LEFT JOIN vec_chunks v ON v.chunk_id = c.id
WHERE v.chunk_id IS NULL;
```
