import { getSQLiteClient } from './sqlite-client';
import { Node, NodeFilters } from '@/types/database';
import { eventBroadcaster } from '../events';
import { EmbeddingService } from '@/services/embeddings';
import { getHighSignalSearchTerms, scoreNodeSearchMatch } from './searchRanking';
import { buildCanonicalNodeMetadata, mergeNodeMetadata } from '@/services/nodes/metadata';
import { getVectorBackend } from '@/services/vectorBackend/factory';

type NodeRow = Node;
type NodeSearchRow = NodeRow & { rank?: number; similarity?: number };

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
  return getHighSignalSearchTerms(query).slice(0, 8);
}

function reciprocalRankFuse<T extends { id: number }>(
  rankedLists: T[][],
  limit: number,
): T[] {
  const scores = new Map<number, { score: number; item: T }>();
  const k = 60;

  rankedLists.forEach((list) => {
    list.forEach((item, index) => {
      const existing = scores.get(item.id);
      const score = 1 / (k + index + 1);
      if (existing) {
        existing.score += score;
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

export class NodeService {
  async getNodes(filters: NodeFilters = {}): Promise<Node[]> {
    return this.getNodesSQLite(filters);
  }

  async countNodes(filters: NodeFilters = {}): Promise<number> {
    const {
      search,
      createdAfter,
      createdBefore,
      eventAfter,
      eventBefore,
      chunkStatus,
    } = filters;

    if (search?.trim()) {
      return this.countSearchNodesSQLite(filters);
    }

    const sqlite = getSQLiteClient();

    let query = `SELECT COUNT(*) as total FROM nodes n WHERE 1=1`;
    const params: any[] = [];

    if (search) {
      query += ` AND (n.title LIKE ? COLLATE NOCASE OR n.description LIKE ? COLLATE NOCASE OR n.source LIKE ? COLLATE NOCASE)`;
      params.push(`%${search}%`, `%${search}%`, `%${search}%`);
    }

    if (createdAfter) { query += ` AND n.created_at >= ?`; params.push(createdAfter); }
    if (createdBefore) { query += ` AND n.created_at < ?`; params.push(createdBefore); }
    if (eventAfter) { query += ` AND n.event_date >= ?`; params.push(eventAfter); }
    if (eventBefore) { query += ` AND n.event_date < ?`; params.push(eventBefore); }
    if (chunkStatus) { query += ` AND n.chunk_status = ?`; params.push(chunkStatus); }
    const result = sqlite.query<{ total: number }>(query, params);
    return result.rows[0]?.total ?? 0;
  }

  // PostgreSQL path removed in SQLite-only consolidation

  private async getNodesSQLite(filters: NodeFilters = {}): Promise<Node[]> {
    const {
      search,
      limit = 100,
      offset = 0,
      sortBy,
      createdAfter,
      createdBefore,
      eventAfter,
      eventBefore,
      chunkStatus,
    } = filters;

    if (search?.trim()) {
      return this.searchNodesSQLite(filters);
    }

    const sqlite = getSQLiteClient();
    
    let query = `
      SELECT n.id, n.title, n.description, n.source, n.link, n.event_date, n.metadata,
             n.chunk_status, n.embedding_updated_at, n.embedding_text,
             n.created_at, n.updated_at,
             (SELECT COUNT(*) FROM edges WHERE from_node_id = n.id OR to_node_id = n.id) as edge_count
      FROM nodes n
      WHERE 1=1
    `;
    const params: any[] = [];

    // Text search in title, description, and source (SQLite LIKE with COLLATE NOCASE)
    if (search) {
      query += ` AND (n.title LIKE ? COLLATE NOCASE OR n.description LIKE ? COLLATE NOCASE OR n.source LIKE ? COLLATE NOCASE)`;
      params.push(`%${search}%`, `%${search}%`, `%${search}%`);
    }

    // Temporal filters
    if (createdAfter) {
      query += ` AND n.created_at >= ?`;
      params.push(createdAfter);
    }
    if (createdBefore) {
      query += ` AND n.created_at < ?`;
      params.push(createdBefore);
    }
    if (eventAfter) {
      query += ` AND n.event_date >= ?`;
      params.push(eventAfter);
    }
    if (eventBefore) {
      query += ` AND n.event_date < ?`;
      params.push(eventBefore);
    }
    if (chunkStatus) {
      query += ` AND n.chunk_status = ?`;
      params.push(chunkStatus);
    }
    // Sorting logic
    if (search) {
      // For search queries, prioritize by relevance: exact title → starts with → contains in title → description → source
      query += ` ORDER BY
        CASE WHEN LOWER(n.title) = LOWER(?) THEN 1 ELSE 6 END,
        CASE WHEN LOWER(n.title) LIKE LOWER(?) THEN 2 ELSE 6 END,
        CASE WHEN n.title LIKE ? COLLATE NOCASE THEN 3 ELSE 6 END,
        CASE WHEN n.description LIKE ? COLLATE NOCASE THEN 4 ELSE 6 END,
        CASE WHEN n.source LIKE ? COLLATE NOCASE THEN 5 ELSE 6 END,
        n.updated_at DESC`;
      params.push(
        search,           // Exact match (case-insensitive)
        `${search}%`,     // Starts with search term
        `%${search}%`,    // Contains in title
        `%${search}%`,    // Contains in description
        `%${search}%`     // Contains in source
      );
    } else if (sortBy === 'edges') {
      // Sort by edge count (most connected first)
      query += ' ORDER BY edge_count DESC, n.updated_at DESC';
    } else if (sortBy === 'created') {
      query += ' ORDER BY n.created_at DESC';
    } else if (sortBy === 'event_date') {
      // Nodes with event_date first (DESC), then by updated_at for nulls
      query += ' ORDER BY n.event_date IS NULL, n.event_date DESC, n.updated_at DESC';
    } else {
      query += ' ORDER BY n.updated_at DESC';
    }

    if (limit) {
      query += ` LIMIT ?`;
      params.push(limit);
    }

    if (offset > 0) {
      query += ` OFFSET ?`;
      params.push(offset);
    }

    const result = sqlite.query<NodeRow>(query, params);
    
    // Parse metadata and normalize deprecated compatibility fields.
    return result.rows.map(row => this.mapNodeRow(row));
  }

  async getNodeById(id: number): Promise<Node | null> {
    return this.getNodeByIdSQLite(id);
  }

  // PostgreSQL path removed in SQLite-only consolidation

  private async getNodeByIdSQLite(id: number): Promise<Node | null> {
    const sqlite = getSQLiteClient();
    const query = `
      SELECT n.id, n.title, n.description, n.source, n.link, n.event_date, n.metadata,
             n.chunk_status, n.embedding_updated_at, n.embedding_text,
             n.created_at, n.updated_at
      FROM nodes n
      WHERE n.id = ?
    `;
    const result = sqlite.query<NodeRow>(query, [id]);
    
    if (result.rows.length === 0) return null;
    
    const row = result.rows[0];
    return this.mapNodeRow(row);
  }

  async createNode(nodeData: Partial<Node>): Promise<Node> {
    return this.createNodeSQLite(nodeData);
  }

  // PostgreSQL path removed in SQLite-only consolidation

  private async createNodeSQLite(nodeData: Partial<Node>): Promise<Node> {
    const {
      title,
      description,
      source,
      link,
      event_date,
      chunk_status,
      metadata = {},
    } = nodeData;
    const canonicalMetadata = buildCanonicalNodeMetadata({ metadata });
    const now = new Date().toISOString();
    const sqlite = getSQLiteClient();

    const nodeId = sqlite.transaction(() => {
      // Insert node using prepare/run for lastInsertRowid access
      const nodeResult = sqlite.prepare(`
        INSERT INTO nodes (title, description, source, link, event_date, metadata, chunk_status, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      `).run(
        title,
        description ?? null,
        source ?? null,
        link ?? null,
        event_date ?? null,
        JSON.stringify(canonicalMetadata),
        chunk_status ?? null,
        now,
        now
      );

      const id = Number(nodeResult.lastInsertRowid);

      return id; // Returns number directly
    });

    // Re-read the created node outside the transaction so callers get the canonical shape.
    const createdNode = await this.getNodeByIdSQLite(nodeId);
    if (!createdNode) {
      throw new Error('Failed to create node');
    }

    // Broadcast node creation event
    console.log('🚀 Broadcasting NODE_CREATED event for:', createdNode.title);
    eventBroadcaster.broadcast({
      type: 'NODE_CREATED',
      data: { node: createdNode }
    });

    return createdNode;
  }

  async updateNode(id: number, updates: Partial<Node>): Promise<Node> {
    return this.updateNodeSQLite(id, updates);
  }

  // PostgreSQL path removed in SQLite-only consolidation

  private async updateNodeSQLite(id: number, updates: Partial<Node>): Promise<Node> {
    const { title, description, source, link, event_date, metadata } = updates;
    const now = new Date().toISOString();
    const sqlite = getSQLiteClient();

    const existingRow = sqlite
      .query<{ id: number; metadata: string | null }>('SELECT id, metadata FROM nodes WHERE id = ?', [id])
      .rows[0];

    if (!existingRow) {
      throw new Error(`Node with ID ${id} not found`);
    }

    const mergedMetadata = metadata !== undefined
      ? mergeNodeMetadata(existingRow.metadata, metadata)
      : undefined;

    sqlite.transaction(() => {
      // Update node columns (only update provided fields)
      const setFields: string[] = [];
      const params: any[] = [];
      
      if (title !== undefined) { setFields.push('title = ?'); params.push(title); }
      if (description !== undefined) { setFields.push('description = ?'); params.push(description); }
      if (source !== undefined) { setFields.push('source = ?'); params.push(source); }
      if (link !== undefined) { setFields.push('link = ?'); params.push(link); }
      if (event_date !== undefined) { setFields.push('event_date = ?'); params.push(event_date); }
      if (Object.prototype.hasOwnProperty.call(updates, 'chunk_status')) {
        setFields.push('chunk_status = ?');
        params.push(updates.chunk_status ?? null);
      }
      if (mergedMetadata !== undefined) {
        setFields.push('metadata = ?'); 
        params.push(JSON.stringify(mergedMetadata));
      }
      
      // Always update timestamp
      setFields.push('updated_at = ?');
      params.push(now, id); // id for WHERE clause

      if (setFields.length > 1) { // More than just updated_at
        const stmt = sqlite.prepare(`UPDATE nodes SET ${setFields.join(', ')} WHERE id = ?`);
        stmt.run(...params);
      }

    });

    // Get updated node
    const updatedNode = await this.getNodeByIdSQLite(id);
    if (!updatedNode) {
      throw new Error(`Node with ID ${id} not found`);
    }

    // Broadcast node update event
    eventBroadcaster.broadcast({
      type: 'NODE_UPDATED',
      data: { nodeId: id, node: updatedNode }
    });

    return updatedNode;
  }

  async deleteNode(id: number): Promise<void> {
    return this.deleteNodeSQLite(id);
  }

  // PostgreSQL path removed in SQLite-only consolidation

  private async deleteNodeSQLite(id: number): Promise<void> {
    const sqlite = getSQLiteClient();

    try {
      const vectorBackend = await getVectorBackend();
      await vectorBackend.deleteNode(id);
    } catch (error) {
      console.warn(`[NodeService] Could not delete vectors for node ${id}:`, error);
    }
    
    const result = sqlite.query('DELETE FROM nodes WHERE id = ?', [id]);
    
    if (result.changes === 0) {
      throw new Error(`Node with ID ${id} not found`);
    }

    // Broadcast node deletion event
    eventBroadcaster.broadcast({
      type: 'NODE_DELETED',
      data: { nodeId: id }
    });
  }

  async searchNodes(searchTerm: string, limit = 50): Promise<Node[]> {
    return this.getNodes({ search: searchTerm, limit });
  }

  private mapNodeRow(row: NodeRow): Node {
    return {
      ...row,
      metadata: row.metadata ? (typeof row.metadata === 'string' ? JSON.parse(row.metadata) : row.metadata) : null,
    };
  }

  private buildNodeFilterClauses(filters: NodeFilters, alias = 'n'): { clauses: string[]; params: any[] } {
    const {
      createdAfter,
      createdBefore,
      eventAfter,
      eventBefore,
    } = filters;

    const clauses: string[] = [];
    const params: any[] = [];

    if (createdAfter) { clauses.push(`${alias}.created_at >= ?`); params.push(createdAfter); }
    if (createdBefore) { clauses.push(`${alias}.created_at < ?`); params.push(createdBefore); }
    if (eventAfter) { clauses.push(`${alias}.event_date >= ?`); params.push(eventAfter); }
    if (eventBefore) { clauses.push(`${alias}.event_date < ?`); params.push(eventBefore); }
    return { clauses, params };
  }

  private async searchNodesSQLite(filters: NodeFilters): Promise<Node[]> {
    const sqlite = getSQLiteClient();
    const search = filters.search?.trim();
    const limit = Math.min(Math.max(filters.limit ?? 100, 1), 100);
    const offset = Math.max(filters.offset ?? 0, 0);

    if (!search) {
      return [];
    }

    const searchLimit = Math.max(limit + offset, Math.min(limit * 20, 250));
    const candidateRows = new Map<number, NodeSearchRow>();

    for (const row of this.searchNodesFts(sqlite, search, filters, searchLimit)) {
      candidateRows.set(row.id, row);
    }

    for (const row of this.searchNodesLike(sqlite, search, filters, searchLimit)) {
      if (!candidateRows.has(row.id)) candidateRows.set(row.id, row);
    }

    for (const row of this.searchNodesLikeRelaxed(sqlite, search, filters, searchLimit)) {
      if (!candidateRows.has(row.id)) candidateRows.set(row.id, row);
    }

    let rankedRows = Array.from(candidateRows.values());

    if ((filters.searchMode ?? 'standard') === 'hybrid') {
      const vectorRows = await this.searchNodesVector(sqlite, search, filters, searchLimit);
      if (vectorRows.length > 0) {
        rankedRows = reciprocalRankFuse<NodeSearchRow>([rankedRows, vectorRows], searchLimit);
      }
    }

    rankedRows = rankedRows
      .map(row => ({ row, score: scoreNodeSearchMatch(row, search) }))
      .sort((a, b) => b.score - a.score)
      .map(entry => entry.row);

    return rankedRows
      .slice(offset, offset + limit)
      .map(row => this.mapNodeRow(row));
  }

  private countSearchNodesSQLite(filters: NodeFilters): number {
    const sqlite = getSQLiteClient();
    const search = filters.search?.trim();
    if (!search) return 0;

    const ftsQuery = sanitizeFtsQuery(search);
    const { clauses, params } = this.buildNodeFilterClauses(filters);

    if (sqlite.canUseFtsTable('nodes') && ftsQuery) {
      try {
        const whereClauses = clauses.length > 0 ? `WHERE ${clauses.join(' AND ')}` : '';
        const result = sqlite.query<{ total: number }>(`
          WITH matched_nodes AS (
            SELECT rowid
            FROM nodes_fts
            WHERE nodes_fts MATCH ?
          )
          SELECT COUNT(*) as total
          FROM matched_nodes mn
          JOIN nodes n ON n.id = mn.rowid
          ${whereClauses}
        `, [ftsQuery, ...params]);

        return Number(result.rows[0]?.total ?? 0);
      } catch (error) {
        sqlite.getIntegrityReport(true);
        console.warn('[NodeSearch] FTS count failed, falling back to LIKE count:', error);
      }
    }

    const words = search.split(/\s+/).filter(Boolean);
    let query = `SELECT COUNT(*) as total FROM nodes n WHERE 1=1`;
    const queryParams = [...params];

    if (clauses.length > 0) {
      query += ` AND ${clauses.join(' AND ')}`;
    }

    for (const word of words) {
      query += ` AND (n.title LIKE ? COLLATE NOCASE OR n.description LIKE ? COLLATE NOCASE OR n.source LIKE ? COLLATE NOCASE)`;
      queryParams.push(`%${word}%`, `%${word}%`, `%${word}%`);
    }

    const result = sqlite.query<{ total: number }>(query, queryParams);
    return Number(result.rows[0]?.total ?? 0);
  }

  private searchNodesFts(
    sqlite: ReturnType<typeof getSQLiteClient>,
    search: string,
    filters: NodeFilters,
    limit: number,
  ): NodeSearchRow[] {
    const ftsQuery = sanitizeFtsQuery(search);
    if (!ftsQuery) return [];

    if (!sqlite.canUseFtsTable('nodes')) return [];

    const { clauses, params } = this.buildNodeFilterClauses(filters);
    const whereClauses = clauses.length > 0 ? `WHERE ${clauses.join(' AND ')}` : '';

    try {
      const result = sqlite.query<NodeSearchRow>(`
        WITH fts_matches AS (
          SELECT rowid, rank
          FROM nodes_fts
          WHERE nodes_fts MATCH ?
          LIMIT ?
        )
        SELECT n.id, n.title, n.description, n.source, n.link, n.event_date, n.metadata,
               n.chunk_status, n.embedding_updated_at, n.embedding_text,
               n.created_at, n.updated_at,
               fm.rank
        FROM fts_matches fm
        JOIN nodes n ON n.id = fm.rowid
        ${whereClauses}
        ORDER BY fm.rank
        LIMIT ?
      `, [ftsQuery, Math.max(limit * 2, 50), ...params, limit]);

      return result.rows;
    } catch (error) {
      sqlite.getIntegrityReport(true);
      console.warn('[NodeSearch] FTS search failed, falling back to LIKE:', error);
      return [];
    }
  }

  private searchNodesLike(
    sqlite: ReturnType<typeof getSQLiteClient>,
    search: string,
    filters: NodeFilters,
    limit: number,
  ): NodeSearchRow[] {
    const words = search.split(/\s+/).filter(Boolean);
    const { clauses, params } = this.buildNodeFilterClauses(filters);
    let query = `
      SELECT n.id, n.title, n.description, n.source, n.link, n.event_date, n.metadata,
             n.chunk_status, n.embedding_updated_at, n.embedding_text,
             n.created_at, n.updated_at
      FROM nodes n
      WHERE 1=1
    `;
    const queryParams = [...params];

    if (clauses.length > 0) {
      query += ` AND ${clauses.join(' AND ')}`;
    }

    for (const word of words) {
      query += ` AND (n.title LIKE ? COLLATE NOCASE OR n.description LIKE ? COLLATE NOCASE OR n.source LIKE ? COLLATE NOCASE)`;
      queryParams.push(`%${word}%`, `%${word}%`, `%${word}%`);
    }

    query += ` ORDER BY
      CASE WHEN LOWER(n.title) = LOWER(?) THEN 1 ELSE 6 END,
      CASE WHEN LOWER(n.title) LIKE LOWER(?) THEN 2 ELSE 6 END,
      CASE WHEN n.title LIKE ? COLLATE NOCASE THEN 3 ELSE 6 END,
      CASE WHEN n.description LIKE ? COLLATE NOCASE THEN 4 ELSE 6 END,
      CASE WHEN n.source LIKE ? COLLATE NOCASE THEN 5 ELSE 6 END,
      n.updated_at DESC
      LIMIT ?`;

    queryParams.push(search, `${search}%`, `%${search}%`, `%${search}%`, `%${search}%`, limit);

    const result = sqlite.query<NodeSearchRow>(query, queryParams);
    return result.rows;
  }

  private searchNodesLikeRelaxed(
    sqlite: ReturnType<typeof getSQLiteClient>,
    search: string,
    filters: NodeFilters,
    limit: number,
  ): NodeSearchRow[] {
    const terms = extractRelaxedSearchTerms(search);
    if (terms.length === 0) return [];

    const { clauses, params } = this.buildNodeFilterClauses(filters);
    let query = `
      SELECT n.id, n.title, n.description, n.source, n.link, n.event_date, n.metadata,
             n.chunk_status, n.embedding_updated_at, n.embedding_text,
             n.created_at, n.updated_at
      FROM nodes n
      WHERE 1=1
    `;
    const queryParams = [...params];

    if (clauses.length > 0) {
      query += ` AND ${clauses.join(' AND ')}`;
    }

    const termClauses: string[] = [];
    for (const term of terms) {
      termClauses.push(`n.title LIKE ? COLLATE NOCASE`);
      termClauses.push(`n.description LIKE ? COLLATE NOCASE`);
      termClauses.push(`n.source LIKE ? COLLATE NOCASE`);
      queryParams.push(`%${term}%`, `%${term}%`, `%${term}%`);
    }

    query += ` AND (${termClauses.join(' OR ')})`;

    const scoreClauses: string[] = [];
    const scoreParams: string[] = [];
    for (const term of terms) {
      scoreClauses.push(`CASE WHEN n.title LIKE ? COLLATE NOCASE THEN 3 ELSE 0 END`);
      scoreClauses.push(`CASE WHEN n.description LIKE ? COLLATE NOCASE THEN 2 ELSE 0 END`);
      scoreClauses.push(`CASE WHEN n.source LIKE ? COLLATE NOCASE THEN 1 ELSE 0 END`);
      scoreParams.push(`%${term}%`, `%${term}%`, `%${term}%`);
    }

    query += ` ORDER BY
      (${scoreClauses.join(' + ')}) DESC,
      CASE WHEN LOWER(n.title) LIKE LOWER(?) THEN 0 ELSE 1 END,
      n.updated_at DESC
      LIMIT ?`;

    queryParams.push(...scoreParams, `%${search}%`, limit);

    const result = sqlite.query<NodeSearchRow>(query, queryParams);
    return result.rows;
  }

  private async searchNodesVector(
    sqlite: ReturnType<typeof getSQLiteClient>,
    search: string,
    filters: NodeFilters,
    limit: number,
  ): Promise<NodeSearchRow[]> {
    try {
      const embedding = await EmbeddingService.generateQueryEmbedding(search);
      if (!EmbeddingService.validateEmbedding(embedding)) {
        return [];
      }

      const { clauses, params } = this.buildNodeFilterClauses(filters);
      const extraClauses = clauses.length > 0 ? `AND ${clauses.join(' AND ')}` : '';
      const vectorBackend = await getVectorBackend();
      const matches = await vectorBackend.searchNodes(embedding, limit);
      if (matches.length === 0) return [];
      const matchIds = matches.map((match) => match.nodeId);
      const scoreById = new Map(matches.map((match) => [match.nodeId, match.score]));

      const result = sqlite.query<NodeSearchRow>(`
        SELECT n.id, n.title, n.description, n.source, n.link, n.event_date, n.metadata,
               n.chunk_status, n.embedding_updated_at, n.embedding_text,
               n.created_at, n.updated_at
        FROM nodes n
        WHERE n.id IN (${matchIds.map(() => '?').join(',')})
        ${extraClauses}
        LIMIT ?
      `, [...matchIds, ...params, limit]);

      return result.rows
        .map((row) => ({ ...row, similarity: scoreById.get(row.id) || 0 }))
        .sort((a, b) => Number(b.similarity || 0) - Number(a.similarity || 0));
    } catch (error) {
      console.warn('[NodeSearch] Vector search unavailable, continuing without it:', error);
      return [];
    }
  }

  async getNodeCount(): Promise<number> {
    const sqlite = getSQLiteClient();
    const result = sqlite.query('SELECT COUNT(*) as count FROM nodes');
    return Number(result.rows[0].count);
  }

  async bulkUpdateNodes(ids: number[], updates: Partial<Node>): Promise<Node[]> {
    if (ids.length === 0) {
      return [];
    }

    return this.bulkUpdateNodesSQLite(ids, updates);
  }

  // PostgreSQL path removed in SQLite-only consolidation

  private async bulkUpdateNodesSQLite(ids: number[], updates: Partial<Node>): Promise<Node[]> {
    // For now, just update one by one - could optimize later
    const updatedNodes: Node[] = [];
    for (const id of ids) {
      const updated = await this.updateNodeSQLite(id, updates);
      updatedNodes.push(updated);
    }
    return updatedNodes;
  }

  async getAllDimensions(): Promise<string[]> {
    return [];
  }

  async getDimensionStats(): Promise<{dimension: string, count: number}[]> {
    return [];
  }

}

// Export singleton instance
export const nodeService = new NodeService();

// Legacy export for backwards compatibility during migration
export const itemService = nodeService;
export const ItemService = NodeService;
