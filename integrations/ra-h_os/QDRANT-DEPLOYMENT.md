# Qdrant Deployment

Qdrant is the optional vector-search sidecar for environments where sqlite-vec is unavailable or unreliable.

Use Qdrant for:

- Alpine/musl Docker images
- Windows ARM64
- Linux ARM64 setups where sqlite-vec has not been validated
- any setup where sqlite-vec cannot be installed or loaded reliably

Qdrant is not required for local embeddings. The embedding model creates vectors; the vector backend stores and searches them.

## Start Qdrant

```bash
docker compose up -d qdrant
```

Configure RA-H:

```bash
VECTOR_BACKEND=qdrant
QDRANT_URL=http://localhost:6333
```

Validate:

```bash
npm run doctor:local-ai
```

## Rebuild

Switching from sqlite-vec to Qdrant, or changing embedding provider/model/dimensions, requires rebuilding vector indexes:

```bash
npm run rebuild:embeddings
```

If existing Qdrant collections have the wrong dimensions and you intentionally want to recreate them from SQLite source data:

```bash
QDRANT_RECREATE_COLLECTIONS=true npm run rebuild:embeddings
```

Nodes, edges, source text, chunks, and metadata remain in SQLite. Qdrant can be deleted and rebuilt from SQLite-derived source data.
