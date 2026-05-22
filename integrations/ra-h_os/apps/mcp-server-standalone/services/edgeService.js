'use strict';

const { query, getDb, runWithBusyRetry } = require('./sqlite-client');

/**
 * Get all edges.
 */
function getEdges(filters = {}) {
  const { nodeId, limit = 50 } = filters;

  let sql = 'SELECT * FROM edges';
  const params = [];

  if (nodeId) {
    sql += ' WHERE from_node_id = ? OR to_node_id = ?';
    params.push(nodeId, nodeId);
  }

  sql += ' ORDER BY created_at DESC LIMIT ?';
  params.push(limit);

  const rows = query(sql, params);

  return rows.map(formatEdgeRow);
}

/**
 * Get edge by ID.
 */
function getEdgeById(id) {
  const rows = query('SELECT * FROM edges WHERE id = ?', [id]);
  if (rows.length === 0) return null;

  return formatEdgeRow(rows[0]);
}

/**
 * Create a new edge.
 * Note: This is a simplified version without AI inference.
 * The main app handles edge type inference.
 */
function createEdge(edgeData) {
  const { from_node_id, to_node_id, explanation, source = 'mcp' } = edgeData;
  const now = new Date().toISOString();
  const db = getDb();

  if (!from_node_id || !to_node_id) {
    throw new Error('from_node_id and to_node_id are required');
  }

  if (!explanation || !explanation.trim()) {
    throw new Error('Edge explanation is required');
  }

  const cleanExplanation = explanation.trim();

  // Simple context without AI inference
  // The main app can re-infer types when it loads
  const context = {
    type: 'related_to',
    confidence: 0.5,
    inferred_at: now,
    explanation: cleanExplanation,
    created_via: 'mcp'
  };

  const stmt = db.prepare(`
    INSERT INTO edges (from_node_id, to_node_id, context, source, created_at, explanation)
    VALUES (?, ?, ?, ?, ?, ?)
  `);

  const result = runWithBusyRetry(() => stmt.run(
      from_node_id,
      to_node_id,
      JSON.stringify(context),
      source,
      now,
      cleanExplanation
    ),
    'createEdge'
  );

  const edgeId = Number(result.lastInsertRowid);
  return getEdgeById(edgeId);
}

/**
 * Update an edge.
 */
function updateEdge(id, updates) {
  const { explanation, context: contextUpdates } = updates;
  const db = getDb();

  const existing = getEdgeById(id);
  if (!existing) {
    throw new Error(`Edge with ID ${id} not found. Use rah_query_edges to find edges by node ID.`);
  }

  const cleanExplanation = typeof explanation === 'string' ? explanation.trim() : '';

  // If explanation changed, update both the normal field and the compatibility copy.
  if (cleanExplanation) {
    const now = new Date().toISOString();
    const newContext = {
      ...existing.context,
      explanation: cleanExplanation,
      inferred_at: now,
      created_via: 'mcp'
    };

    const stmt = db.prepare('UPDATE edges SET context = ?, explanation = ? WHERE id = ?');
    runWithBusyRetry(() => stmt.run(JSON.stringify(newContext), cleanExplanation, id), 'updateEdge');
  } else if (contextUpdates) {
    const contextExplanation = typeof contextUpdates.explanation === 'string'
      ? contextUpdates.explanation.trim()
      : '';
    const newContext = {
      ...existing.context,
      ...contextUpdates,
      ...(contextExplanation ? { explanation: contextExplanation } : {})
    };
    if (contextExplanation) {
      const stmt = db.prepare('UPDATE edges SET context = ?, explanation = ? WHERE id = ?');
      runWithBusyRetry(() => stmt.run(JSON.stringify(newContext), contextExplanation, id), 'updateEdge');
    } else {
      const stmt = db.prepare('UPDATE edges SET context = ? WHERE id = ?');
      runWithBusyRetry(() => stmt.run(JSON.stringify(newContext), id), 'updateEdge');
    }
  }

  return getEdgeById(id);
}

/**
 * Delete an edge.
 */
function deleteEdge(id) {
  const result = query('DELETE FROM edges WHERE id = ?', [id]);
  if (result.changes === 0) {
    throw new Error(`Edge with ID ${id} not found. Use rah_query_edges to find edges by node ID.`);
  }
  return true;
}

/**
 * Get connections for a node.
 */
function getNodeConnections(nodeId) {
  const sql = `
    SELECT
      e.*,
      CASE
        WHEN e.from_node_id = ? THEN n_to.id
        ELSE n_from.id
      END as connected_node_id,
      CASE
        WHEN e.from_node_id = ? THEN n_to.title
        ELSE n_from.title
      END as connected_node_title,
      CASE
        WHEN e.from_node_id = ? THEN n_to.description
        ELSE n_from.description
      END as connected_node_description,
      CASE
        WHEN e.from_node_id = ? THEN n_to.link
        ELSE n_from.link
      END as connected_node_link,
      CASE
        WHEN e.from_node_id = ? THEN n_to.source
        ELSE n_from.source
      END as connected_node_source,
      CASE
        WHEN e.from_node_id = ? THEN n_to.updated_at
        ELSE n_from.updated_at
      END as connected_node_updated_at,
      CASE
        WHEN e.from_node_id = ? THEN n_to.metadata
        ELSE n_from.metadata
      END as connected_node_metadata
    FROM edges e
    LEFT JOIN nodes n_from ON e.from_node_id = n_from.id
    LEFT JOIN nodes n_to ON e.to_node_id = n_to.id
    WHERE e.from_node_id = ? OR e.to_node_id = ?
    ORDER BY e.created_at DESC
  `;

  const rows = query(sql, [nodeId, nodeId, nodeId, nodeId, nodeId, nodeId, nodeId, nodeId, nodeId]);

  return rows.map(row => ({
    edgeId: row.id,
    from_node_id: row.from_node_id,
    to_node_id: row.to_node_id,
    context: parseContext(row.context),
    connected_node: {
      id: row.connected_node_id,
      title: row.connected_node_title,
      description: row.connected_node_description,
      link: row.connected_node_link,
      source: row.connected_node_source,
      updated_at: row.connected_node_updated_at,
      metadata: parseContext(row.connected_node_metadata)
    }
  }));
}

/**
 * Get edge count.
 */
function getEdgeCount() {
  const rows = query('SELECT COUNT(*) as count FROM edges');
  return Number(rows[0].count);
}

function formatEdgeRow(row) {
  const context = parseContext(row.context);
  return {
    ...row,
    context,
    explanation: row.explanation || context?.explanation || null
  };
}

/**
 * Parse context JSON safely.
 */
function parseContext(context) {
  if (!context) return null;
  if (typeof context === 'object') return context;
  try {
    return JSON.parse(context);
  } catch {
    return context;
  }
}

module.exports = {
  getEdges,
  getEdgeById,
  createEdge,
  updateEdge,
  deleteEdge,
  getNodeConnections,
  getEdgeCount
};
