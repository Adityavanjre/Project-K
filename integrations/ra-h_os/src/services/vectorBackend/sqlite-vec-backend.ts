import { getSQLiteClient } from '@/services/database/sqlite-client';
import { getEmbeddingProviderInfo } from '@/services/embedding/provider';
import type { Chunk } from '@/types/database';
import type { RankedChunk, RankedNode, VectorBackend, VectorBackendHealth } from './index';

function vectorLiteral(embedding: number[]): string {
  return `[${embedding.join(',')}]`;
}

export class SqliteVecBackend implements VectorBackend {
  async upsertChunk(chunkId: number, _nodeId: number, _chunkIndex: number, _text: string, embedding: number[]): Promise<void> {
    const sqlite = getSQLiteClient();
    sqlite.prepare('DELETE FROM vec_chunks WHERE chunk_id = ?').run(BigInt(chunkId));
    sqlite.prepare('INSERT OR REPLACE INTO vec_chunks (chunk_id, embedding) VALUES (?, ?)').run(BigInt(chunkId), vectorLiteral(embedding));
  }

  async upsertNode(nodeId: number, _text: string, embedding: number[]): Promise<void> {
    const sqlite = getSQLiteClient();
    sqlite.prepare('DELETE FROM vec_nodes WHERE node_id = ?').run(BigInt(nodeId));
    sqlite.prepare('INSERT OR REPLACE INTO vec_nodes (node_id, embedding) VALUES (?, ?)').run(BigInt(nodeId), vectorLiteral(embedding));
  }

  async searchChunks(
    queryEmbedding: number[],
    similarityThreshold: number,
    limit: number,
    nodeIds?: number[]
  ): Promise<RankedChunk[]> {
    const sqlite = getSQLiteClient();
    const vectorLimit = Math.max(limit * 10, 50);

    if (nodeIds && nodeIds.length > 0) {
      const result = sqlite.query<RankedChunk>(`
        SELECT c.*, (1.0 / (1.0 + v.distance)) AS similarity
        FROM (
          SELECT chunk_id, distance
          FROM vec_chunks
          WHERE embedding MATCH ?
          ORDER BY distance
          LIMIT ?
        ) v
        JOIN chunks c ON c.id = v.chunk_id
        WHERE c.node_id IN (${nodeIds.map(() => '?').join(',')})
          AND (1.0 / (1.0 + v.distance)) >= ?
        ORDER BY similarity DESC
        LIMIT ?
      `, [vectorLiteral(queryEmbedding), vectorLimit, ...nodeIds, similarityThreshold, limit]);
      return result.rows;
    }

    const result = sqlite.query<RankedChunk>(`
      WITH vector_results AS (
        SELECT chunk_id, distance
        FROM vec_chunks
        WHERE embedding MATCH ?
        ORDER BY distance
        LIMIT ?
      )
      SELECT c.*, (1.0 / (1.0 + vr.distance)) AS similarity
      FROM vector_results vr
      JOIN chunks c ON c.id = vr.chunk_id
      WHERE (1.0 / (1.0 + vr.distance)) >= ?
      ORDER BY similarity DESC
      LIMIT ?
    `, [vectorLiteral(queryEmbedding), vectorLimit, similarityThreshold, limit]);
    return result.rows;
  }

  async searchNodes(queryEmbedding: number[], limit: number): Promise<RankedNode[]> {
    const sqlite = getSQLiteClient();
    const result = sqlite.query<{ node_id: number; distance: number }>(`
      SELECT node_id, distance
      FROM vec_nodes
      WHERE embedding MATCH ?
      ORDER BY distance
      LIMIT ?
    `, [vectorLiteral(queryEmbedding), Math.max(limit * 2, 50)]);

    return result.rows.map((row) => ({
      nodeId: Number(row.node_id),
      score: 1.0 / (1.0 + Number(row.distance)),
    }));
  }

  async deleteChunksByNode(nodeId: number): Promise<void> {
    const sqlite = getSQLiteClient();
    const chunks = sqlite.query<Pick<Chunk, 'id'>>('SELECT id FROM chunks WHERE node_id = ?', [nodeId]).rows;
    for (const chunk of chunks) {
      sqlite.prepare('DELETE FROM vec_chunks WHERE chunk_id = ?').run(BigInt(chunk.id));
    }
  }

  async deleteNode(nodeId: number): Promise<void> {
    const sqlite = getSQLiteClient();
    await this.deleteChunksByNode(nodeId);
    sqlite.prepare('DELETE FROM vec_nodes WHERE node_id = ?').run(BigInt(nodeId));
  }

  async healthCheck(): Promise<VectorBackendHealth> {
    const sqlite = getSQLiteClient();
    const ok = await sqlite.checkVectorExtension();
    const expectedDimensions = getEmbeddingProviderInfo().dimensions;
    const tableDimensions = sqlite.getVectorTableDimensions();
    const mismatchedTables = Object.entries(tableDimensions)
      .filter(([, dimensions]) => dimensions !== null && dimensions !== expectedDimensions)
      .map(([table, dimensions]) => `${table}=${dimensions}`);

    if (mismatchedTables.length > 0) {
      return {
        ok: false,
        backend: 'sqlite-vec',
        dimensions: expectedDimensions,
        detail: `sqlite-vec table dimensions mismatch (${mismatchedTables.join(', ')}), expected ${expectedDimensions}. Run npm run rebuild:embeddings.`,
      };
    }

    return {
      ok,
      backend: 'sqlite-vec',
      dimensions: expectedDimensions,
      detail: ok ? 'sqlite-vec extension loaded' : 'sqlite-vec extension unavailable',
    };
  }
}
