import { getSQLiteClient } from './sqlite-client';
import { Chunk, ChunkData } from '@/types/database';
import { getVectorBackendType } from '@/services/vectorBackend';
import { getVectorBackend } from '@/services/vectorBackend/factory';

type RankedChunk = Chunk & { similarity: number };

function sanitizeFtsQuery(input: string): string {
  return input
    .toLowerCase()
    .replace(/[^a-z0-9\s]+/g, ' ')
    .trim()
    .split(/\s+/)
    .filter(word => word.length > 0 && !/^(AND|OR|NOT|NEAR)$/i.test(word))
    .join(' ');
}

function extractRelaxedSearchTerms(query: string): string[] {
  const stopWords = new Set([
    'a', 'an', 'and', 'are', 'as', 'at', 'be', 'being', 'briefly', 'by', 'find',
    'focused', 'for', 'from', 'in', 'inside', 'is', 'it', 'me', 'my', 'of', 'on',
    'or', 'quote', 'search', 'solutions', 'specific', 'that', 'the', 'then', 'this',
    'to', 'transcript', 'with'
  ]);

  const rawTerms = query
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, ' ')
    .split(/\s+/)
    .map(term => term.trim())
    .filter(term => term.length >= 4 && !stopWords.has(term));

  const expanded = new Set<string>();
  for (const term of rawTerms) {
    expanded.add(term);
    if (term.length >= 6) {
      expanded.add(term.slice(0, 5));
      expanded.add(term.slice(0, 6));
    }
    if (term.endsWith('ing') && term.length > 6) {
      expanded.add(term.slice(0, -3));
    }
    if (term.endsWith('tion') && term.length > 7) {
      expanded.add(term.slice(0, -4));
    }
    if (term.endsWith('ions') && term.length > 7) {
      expanded.add(term.slice(0, -4));
    }
  }

  return Array.from(expanded).slice(0, 12);
}

function reciprocalRankFuse<T extends { id: number }>(rankedLists: T[][], limit: number): T[] {
  const scores = new Map<number, { score: number; item: T }>();
  const k = 60;

  rankedLists.forEach((list) => {
    list.forEach((item, index) => {
      const entry = scores.get(item.id);
      const score = 1 / (k + index + 1);
      if (entry) {
        entry.score += score;
      } else {
        scores.set(item.id, { score, item });
      }
    });
  });

  return Array.from(scores.values())
    .sort((a, b) => b.score - a.score)
    .slice(0, limit)
    .map(entry => entry.item);
}

export class ChunkService {
  async getChunksByNodeId(nodeId: number): Promise<Chunk[]> {
    const sqlite = getSQLiteClient();
    const result = sqlite.query<Chunk>('SELECT * FROM chunks WHERE node_id = ? ORDER BY chunk_idx ASC', [nodeId]);
    return result.rows;
  }

  async getChunkById(id: number): Promise<Chunk | null> {
    const sqlite = getSQLiteClient();
    const result = sqlite.query<Chunk>('SELECT * FROM chunks WHERE id = ?', [id]);
    return result.rows[0] || null;
  }

  async createChunk(chunkData: ChunkData): Promise<Chunk> {
    return this.createChunkSQLite(chunkData);
  }

  // PostgreSQL path removed in SQLite-only consolidation

  private async createChunkSQLite(chunkData: ChunkData): Promise<Chunk> {
    const now = new Date().toISOString();
    const sqlite = getSQLiteClient();
    
    const result = sqlite.prepare(`
      INSERT INTO chunks (node_id, chunk_idx, text, embedding, embedding_type, metadata, created_at)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `).run(
      chunkData.node_id,
      chunkData.chunk_idx || null,
      chunkData.text,
      chunkData.embedding || null,
      chunkData.embedding_type,
      chunkData.metadata ? JSON.stringify(chunkData.metadata) : null,
      now
    );

    const chunkId = Number(result.lastInsertRowid);
    const createdChunk = await this.getChunkById(chunkId);
    
    if (!createdChunk) {
      throw new Error('Failed to create chunk');
    }

    return createdChunk;
  }

  async createChunks(chunksData: ChunkData[]): Promise<Chunk[]> {
    if (chunksData.length === 0) {
      return [];
    }

    return this.createChunksSQLite(chunksData);
  }

  // PostgreSQL path removed in SQLite-only consolidation

  private async createChunksSQLite(chunksData: ChunkData[]): Promise<Chunk[]> {
    const sqlite = getSQLiteClient();
    const now = new Date().toISOString();
    const createdChunks: Chunk[] = [];

    // Use transaction for bulk insert
    sqlite.transaction(() => {
      const stmt = sqlite.prepare(`
        INSERT INTO chunks (node_id, chunk_idx, text, embedding, embedding_type, metadata, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?)
      `);

      for (const chunk of chunksData) {
        stmt.run(
          chunk.node_id,
          chunk.chunk_idx || null,
          chunk.text,
          chunk.embedding || null,
          chunk.embedding_type,
          chunk.metadata ? JSON.stringify(chunk.metadata) : null,
          now
        );
      }
    });

    // Get all created chunks by node_id (since we know they were just created)
    const nodeIds = [...new Set(chunksData.map(c => c.node_id))];
    for (const nodeId of nodeIds) {
      const chunks = await this.getChunksByNodeId(nodeId);
      createdChunks.push(...chunks.filter(c => c.created_at === now));
    }

    return createdChunks;
  }

  async updateChunk(id: number, updates: Partial<Chunk>): Promise<Chunk> {
    return this.updateChunkSQLite(id, updates);
  }

  // PostgreSQL path removed in SQLite-only consolidation

  private async updateChunkSQLite(id: number, updates: Partial<Chunk>): Promise<Chunk> {
    const sqlite = getSQLiteClient();
    const updateFields: string[] = [];
    const params: any[] = [];

    // Build dynamic update query
    Object.entries(updates).forEach(([key, value]) => {
      if (key !== 'id' && key !== 'created_at' && value !== undefined) {
        updateFields.push(`${key} = ?`);
        if (key === 'metadata') {
          params.push(typeof value === 'object' ? JSON.stringify(value) : value);
        } else {
          params.push(value);
        }
      }
    });

    if (updateFields.length === 0) {
      throw new Error('No valid fields to update');
    }

    params.push(id); // Add ID for WHERE clause

    const query = `UPDATE chunks SET ${updateFields.join(', ')} WHERE id = ?`;
    const result = sqlite.query(query, params);
    
    if (result.changes === 0) {
      throw new Error(`Chunk with ID ${id} not found`);
    }

    const updatedChunk = await this.getChunkById(id);
    if (!updatedChunk) {
      throw new Error(`Failed to retrieve updated chunk with ID ${id}`);
    }

    return updatedChunk;
  }

  async deleteChunk(id: number): Promise<void> {
    const sqlite = getSQLiteClient();
    const result = sqlite.query('DELETE FROM chunks WHERE id = ?', [id]);
    if ((result.changes || 0) === 0) {
      throw new Error(`Chunk with ID ${id} not found`);
    }
  }

  async deleteChunksByNodeId(nodeId: number): Promise<void> {
    const sqlite = getSQLiteClient();
    sqlite.query('DELETE FROM chunks WHERE node_id = ?', [nodeId]);
  }

  async searchChunks(
    queryEmbedding: number[], 
    similarityThreshold = 0.5, 
    matchCount = 5,
    nodeIds?: number[],
    fallbackQuery?: string
  ): Promise<Array<Chunk & { similarity: number }>> {
    try {
      const vectorResults = await this.searchChunksSQLite(queryEmbedding, similarityThreshold, matchCount, nodeIds);

      if (!fallbackQuery) {
        return vectorResults;
      }

      const textResults = await this.textSearchFallback(fallbackQuery, matchCount, nodeIds);
      if (textResults.length === 0) {
        return vectorResults;
      }

      return reciprocalRankFuse<RankedChunk>([vectorResults, textResults], matchCount);
    } catch (error) {
      console.warn('Vector search failed, attempting text fallback:', error);
      if (fallbackQuery) {
        return await this.textSearchFallback(fallbackQuery, matchCount, nodeIds);
      }
      throw error;
    }
  }

  // PostgreSQL path removed in SQLite-only consolidation

  private async searchChunksSQLite(
    queryEmbedding: number[],
    similarityThreshold = 0.5,
    matchCount = 5,
    nodeIds?: number[]
  ): Promise<Array<Chunk & { similarity: number }>> {
    const startTime = Date.now();
    const vectorBackend = await getVectorBackend();

    if (nodeIds && nodeIds.length > 0) {
      const sqlite = getSQLiteClient();
      const chunkCountQuery = `SELECT COUNT(*) AS count FROM chunks WHERE node_id IN (${nodeIds.map(() => '?').join(',')})`;
      const chunkCountResult = sqlite.query<{ count: number }>(chunkCountQuery, nodeIds);
      const chunkCount = Number(chunkCountResult.rows[0]?.count ?? 0);

      if (chunkCount === 0) {
        console.log(`🔍 Node-scoped search: no chunks found for nodes ${nodeIds.join(', ')}`);
        return [];
      }

      console.log(`🔍 Node-scoped search: ${chunkCount} chunks in nodes ${nodeIds.join(', ')}`);
      const rows = await vectorBackend.searchChunks(queryEmbedding, similarityThreshold, matchCount, nodeIds);
      const searchTime = Date.now() - startTime;

      console.log(`📊 Vector search (${getVectorBackendType()}, node-scoped): ${rows.length} chunks, threshold=${similarityThreshold}, time=${searchTime}ms`);
      if (rows.length > 0) {
        console.log(`🎯 Top result: chunk ${rows[0].id} (similarity: ${rows[0].similarity.toFixed(3)})`);
      }

      return rows;
    }

    const rows = await vectorBackend.searchChunks(queryEmbedding, similarityThreshold, matchCount);
    const searchTime = Date.now() - startTime;

    console.log(`📊 Vector search (${getVectorBackendType()}, global): ${rows.length} chunks, threshold=${similarityThreshold}, time=${searchTime}ms`);
    if (rows.length > 0) {
      console.log(`🎯 Top result: chunk ${rows[0].id} (similarity: ${rows[0].similarity.toFixed(3)})`);
    }

    return rows;
  }

  async textSearchFallback(
    query: string,
    matchCount = 5,
    nodeIds?: number[]
  ): Promise<Array<Chunk & { similarity: number }>> {
    const sqlite = getSQLiteClient();
    const startTime = Date.now();
    const ftsResults = this.ftsSearchChunks(sqlite, query, matchCount, nodeIds);
    if (ftsResults.length > 0) {
      const searchTime = Date.now() - startTime;
      console.log(`📝 Text fallback (FTS): ${ftsResults.length} chunks found, time=${searchTime}ms`);
      return ftsResults;
    }
    
    // Clean query for LIKE search
    const cleanQuery = query.trim().toLowerCase();
    const searchTerms = cleanQuery.split(/\s+/).filter(term => term.length > 2);
    
    if (searchTerms.length === 0) {
      return [];
    }
    
    // Build LIKE conditions for each term
    const likeConditions = searchTerms.map(() => 'LOWER(text) LIKE ?').join(' AND ');
    const likeParams = searchTerms.map(term => `%${term}%`);
    
    let textQuery = `
      SELECT *, 0.8 as similarity
      FROM chunks 
      WHERE ${likeConditions}
    `;
    
    const params = [...likeParams];
    
    // Add node filter if provided
    if (nodeIds && nodeIds.length > 0) {
      textQuery += ` AND node_id IN (${nodeIds.map(() => '?').join(',')})`;
      params.push(...nodeIds.map(String));
    }
    
    textQuery += ` ORDER BY LENGTH(text) ASC LIMIT ?`;
    params.push(String(matchCount));
    
    const result = sqlite.query<RankedChunk>(textQuery, params);
    const searchTime = Date.now() - startTime;
    
    console.log(`📝 Text fallback: ${result.rows.length} chunks found, time=${searchTime}ms`);
    if (result.rows.length > 0) {
      return result.rows;
    }

    const relaxedTerms = extractRelaxedSearchTerms(query);
    if (relaxedTerms.length === 0) {
      return [];
    }

    const scoreClauses = relaxedTerms.map(() => 'CASE WHEN LOWER(text) LIKE ? THEN 1 ELSE 0 END');
    const scoreParams = relaxedTerms.map(term => `%${term}%`);
    const relaxedParams = [...scoreParams];

    let relaxedQuery = `
      SELECT *,
        (${scoreClauses.join(' + ')}) * 0.7 AS similarity
      FROM chunks
      WHERE (${scoreClauses.join(' + ')}) > 0
    `;

    if (nodeIds && nodeIds.length > 0) {
      relaxedQuery += ` AND node_id IN (${nodeIds.map(() => '?').join(',')})`;
      relaxedParams.push(...nodeIds.map(String));
    }

    relaxedQuery += ' ORDER BY similarity DESC, chunk_idx ASC LIMIT ?';
    relaxedParams.push(String(matchCount));

    const relaxedResult = sqlite.query<RankedChunk>(
      relaxedQuery,
      [...scoreParams, ...relaxedParams]
    );
    const relaxedSearchTime = Date.now() - startTime;
    console.log(`📝 Text fallback (relaxed): ${relaxedResult.rows.length} chunks found, time=${relaxedSearchTime}ms`);

    return relaxedResult.rows;
  }

  private ftsSearchChunks(
    sqlite: ReturnType<typeof getSQLiteClient>,
    query: string,
    matchCount: number,
    nodeIds?: number[]
  ): RankedChunk[] {
    if (!sqlite.canUseFtsTable('chunks')) return [];

    const ftsQuery = sanitizeFtsQuery(query);
    if (!ftsQuery) return [];

    try {
      if (nodeIds && nodeIds.length > 0) {
        const result = sqlite.query<RankedChunk>(`
          SELECT c.*, 0.85 as similarity
          FROM chunks c
          WHERE c.node_id IN (${nodeIds.map(() => '?').join(',')})
          AND c.id IN (
            SELECT rowid
            FROM chunks_fts
            WHERE chunks_fts MATCH ?
          )
          ORDER BY c.chunk_idx ASC
          LIMIT ?
        `, [...nodeIds, ftsQuery, matchCount]);

        return result.rows;
      }

      const result = sqlite.query<RankedChunk>(`
        WITH fts_matches AS (
          SELECT rowid, rank
          FROM chunks_fts
          WHERE chunks_fts MATCH ?
          LIMIT ?
        )
        SELECT c.*, 0.85 as similarity
        FROM fts_matches fm
        JOIN chunks c ON c.id = fm.rowid
        ORDER BY fm.rank
      `, [ftsQuery, matchCount]);

      return result.rows;
    } catch (error) {
      console.warn('[ChunkSearch] FTS chunk search failed, falling back to LIKE:', error);
      return [];
    }
  }

  async getChunkCount(): Promise<number> {
    const sqlite = getSQLiteClient();
    const result = sqlite.query('SELECT COUNT(*) as count FROM chunks');
    return Number(result.rows[0].count);
  }

  async getChunkCountByNodeId(nodeId: number): Promise<number> {
    const sqlite = getSQLiteClient();
    const result = sqlite.query('SELECT COUNT(*) as count FROM chunks WHERE node_id = ?', [nodeId]);
    return Number(result.rows[0].count);
  }

  async getNodesWithChunks(): Promise<Array<{ node_id: number; chunk_count: number }>> {
    const sqlite = getSQLiteClient();
    const result = sqlite.query(`
      SELECT node_id, COUNT(*) as chunk_count
      FROM chunks 
      GROUP BY node_id
      ORDER BY chunk_count DESC
    `);
    return result.rows.map((row: any) => ({
      node_id: Number(row.node_id),
      chunk_count: Number(row.chunk_count)
    }));
  }

  async getChunksWithoutEmbeddings(): Promise<Chunk[]> {
    if (getVectorBackendType() === 'qdrant') {
      return [];
    }

    // In SQLite, chunk vectors live in vec_chunks; report chunks without corresponding vector rows
    const sqlite = getSQLiteClient();
    const result = sqlite.query<Chunk>(`
      SELECT c.*
      FROM chunks c
      LEFT JOIN vec_chunks v ON v.chunk_id = c.id
      WHERE v.chunk_id IS NULL
      ORDER BY c.created_at ASC
    `);
    return result.rows;
  }
}

// Export singleton instance
export const chunkService = new ChunkService();
