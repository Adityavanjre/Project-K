import { getSQLiteClient } from '@/services/database/sqlite-client';
import { NodeEmbedder } from '@/services/typescript/embed-nodes';
import { UniversalEmbedder } from '@/services/typescript/embed-universal';
import { getVectorBackendType } from '@/services/vectorBackend';

async function maybeRecreateQdrantCollections() {
  if (process.env.VECTOR_BACKEND !== 'qdrant' || process.env.QDRANT_RECREATE_COLLECTIONS !== 'true') {
    return;
  }

  const baseUrl = (process.env.QDRANT_URL || 'http://localhost:6333').replace(/\/+$/, '');
  const headers = process.env.QDRANT_API_KEY ? { 'api-key': process.env.QDRANT_API_KEY } : undefined;
  const collections = [
    process.env.QDRANT_CHUNKS_COLLECTION || 'rah_chunks',
    process.env.QDRANT_NODES_COLLECTION || 'rah_nodes',
  ];

  for (const collection of collections) {
    const response = await fetch(`${baseUrl}/collections/${encodeURIComponent(collection)}`, {
      method: 'DELETE',
      headers,
    });
    if (!response.ok && response.status !== 404) {
      const detail = await response.text().catch(() => response.statusText);
      throw new Error(`Failed to delete Qdrant collection ${collection}: ${detail}`);
    }
    console.log(`[rebuild-embeddings] Recreated Qdrant collection on next upsert: ${collection}`);
  }
}

async function main() {
  const sqlite = getSQLiteClient();
  await maybeRecreateQdrantCollections();
  if (getVectorBackendType() === 'sqlite-vec') {
    sqlite.recreateVectorTables();
    console.log('[rebuild-embeddings] Recreated sqlite-vec tables for the active embedding dimensions.');
  }
  const nodeRows = sqlite.query<{ id: number; source?: string | null }>(`
    SELECT id, source
    FROM nodes
    ORDER BY id
  `).rows;

  console.log(`[rebuild-embeddings] Rebuilding node embeddings for ${nodeRows.length} nodes`);
  const nodeEmbedder = new NodeEmbedder();
  try {
    await nodeEmbedder.embedNodes({ forceReEmbed: true, verbose: true });
  } finally {
    nodeEmbedder.close();
  }

  const sourceRows = nodeRows.filter((node) => typeof node.source === 'string' && node.source.trim().length > 0);
  console.log(`[rebuild-embeddings] Rebuilding chunk embeddings for ${sourceRows.length} nodes with source text`);

  const chunkEmbedder = new UniversalEmbedder();
  try {
    let processed = 0;
    for (const node of sourceRows) {
      await chunkEmbedder.processNode({ nodeId: node.id, verbose: false });
      processed += 1;
      if (processed % 10 === 0 || processed === sourceRows.length) {
        console.log(`[rebuild-embeddings] Chunked ${processed}/${sourceRows.length}`);
      }
    }
  } finally {
    chunkEmbedder.close();
  }

  sqlite.markEmbeddingProfileCurrent();
  console.log('[rebuild-embeddings] Active embedding/vector profile recorded.');
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
