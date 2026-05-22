'use strict';

const { query, transaction, getDb } = require('./sqlite-client');

function sanitizeFtsQuery(input) {
  return String(input || '')
    .toLowerCase()
    .replace(/[^a-z0-9\s]+/g, ' ')
    .trim()
    .split(/\s+/)
    .filter(word => word.length > 0 && !/^(AND|OR|NOT|NEAR)$/i.test(word))
    .join(' ');
}

function extractRelaxedSearchTerms(queryText) {
  const stopWords = new Set([
    'a', 'an', 'and', 'are', 'as', 'at', 'be', 'by', 'can', 'do', 'find',
    'for', 'from', 'hello', 'i', 'in', 'is', 'it', 'me', 'my', 'of', 'on',
    'or', 'recent', 'stuff', 'term', 'that', 'the', 'this', 'to', 'with', 'you'
  ]);

  const rawTerms = String(queryText || '')
    .toLowerCase()
    .replace(/[^a-z0-9\s]+/g, ' ')
    .split(/\s+/)
    .map(term => term.trim())
    .filter(Boolean);

  const expanded = new Set();

  for (const term of rawTerms) {
    if (!stopWords.has(term) && term.length >= 3) {
      expanded.add(term);
    }

    const alphaParts = term.replace(/\d+/g, ' ').split(/\s+/).filter(Boolean);
    for (const part of alphaParts) {
      if (!stopWords.has(part) && part.length >= 3) {
        expanded.add(part);
      }
    }
  }

  return Array.from(expanded).slice(0, 8);
}

function normalizeSearchText(value) {
  return String(value || '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function getQueryTerms(queryText) {
  return normalizeSearchText(queryText).split(' ').filter(term => term.length > 0);
}

function countOccurrences(text, term) {
  if (!text || !term) return 0;
  const matches = text.match(new RegExp(`\\b${term.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}\\b`, 'g'));
  return matches ? matches.length : 0;
}

function orderedTermMatches(text, terms) {
  let position = 0;
  for (const term of terms) {
    const index = text.indexOf(term, position);
    if (index === -1) return false;
    position = index + term.length;
  }
  return terms.length > 0;
}

function scoreNodeSearchMatch(node, queryText) {
  const normalizedQuery = normalizeSearchText(queryText);
  const normalizedTitle = normalizeSearchText(node.title || '');
  const normalizedDescription = normalizeSearchText(node.description || '');
  const normalizedSource = normalizeSearchText(node.source || '');
  const terms = getQueryTerms(queryText);

  let score = 0;

  if (normalizedTitle === normalizedQuery) score += 2000;
  if (normalizedTitle.startsWith(normalizedQuery)) score += 1200;
  if (normalizedTitle.includes(normalizedQuery)) score += 700;
  if (orderedTermMatches(normalizedTitle, terms)) score += 500;
  if (terms.length > 0 && terms.every(term => normalizedTitle.includes(term))) score += 350;

  if (normalizedDescription.includes(normalizedQuery)) score += 180;
  if (orderedTermMatches(normalizedDescription, terms)) score += 120;
  if (normalizedSource.includes(normalizedQuery)) score += 90;

  for (const term of terms) {
    score += countOccurrences(normalizedTitle, term) * 40;
    score += countOccurrences(normalizedDescription, term) * 8;
    score += countOccurrences(normalizedSource, term) * 3;
  }

  if (node.updated_at) {
    score += new Date(node.updated_at).getTime() / 1e13;
  }

  return score;
}

function parseMetadata(metadata) {
  if (!metadata) return {};
  if (typeof metadata === 'string') {
    try {
      const parsed = JSON.parse(metadata);
      return parsed && typeof parsed === 'object' && !Array.isArray(parsed) ? { ...parsed } : {};
    } catch {
      return {};
    }
  }
  return metadata && typeof metadata === 'object' && !Array.isArray(metadata) ? { ...metadata } : {};
}

function normalizeString(value) {
  if (typeof value !== 'string') return undefined;
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}

function buildCanonicalMetadata({ existing, metadata }) {
  const prior = parseMetadata(existing);
  const incoming = parseMetadata(metadata);
  const sourceMetadata = {
    ...(prior.source_metadata && typeof prior.source_metadata === 'object' ? prior.source_metadata : {}),
    ...(incoming.source_metadata && typeof incoming.source_metadata === 'object' ? incoming.source_metadata : {}),
  };

  const merged = {
    ...prior,
    ...incoming,
    state: incoming.state === 'processed' ? 'processed' : (prior.state === 'processed' ? 'processed' : 'not_processed'),
    captured_by: incoming.captured_by || prior.captured_by || 'human',
    source_metadata: sourceMetadata,
  };

  const type = normalizeString(incoming.type) || normalizeString(prior.type);
  const capturedMethod = normalizeString(incoming.captured_method) || normalizeString(prior.captured_method);

  if (type) merged.type = type;
  else delete merged.type;

  if (capturedMethod) merged.captured_method = capturedMethod;
  else delete merged.captured_method;

  return merged;
}

function mapNodeRow(row) {
  return {
    ...row,
    metadata: row.metadata ? (typeof row.metadata === 'string' ? JSON.parse(row.metadata) : row.metadata) : null,
  };
}

function buildNodeFilterClauses(filters = {}, alias = 'n') {
  const clauses = [];
  const params = [];

  if (filters.createdAfter) {
    clauses.push(`${alias}.created_at >= ?`);
    params.push(filters.createdAfter);
  }
  if (filters.createdBefore) {
    clauses.push(`${alias}.created_at < ?`);
    params.push(filters.createdBefore);
  }
  if (filters.eventAfter) {
    clauses.push(`${alias}.event_date >= ?`);
    params.push(filters.eventAfter);
  }
  if (filters.eventBefore) {
    clauses.push(`${alias}.event_date < ?`);
    params.push(filters.eventBefore);
  }

  return { clauses, params };
}

function searchNodes(filters = {}) {
  const search = normalizeString(filters.search);
  const limit = Math.min(Math.max(filters.limit || 25, 1), 100);
  if (!search) return [];

  const rowsById = new Map();
  for (const row of searchNodesFts(search, filters, Math.max(limit * 2, 25))) {
    rowsById.set(row.id, row);
  }
  for (const row of searchNodesLike(search, filters, Math.max(limit * 2, 25))) {
    if (!rowsById.has(row.id)) rowsById.set(row.id, row);
  }
  for (const row of searchNodesLikeRelaxed(search, filters, Math.max(limit * 2, 25))) {
    if (!rowsById.has(row.id)) rowsById.set(row.id, row);
  }

  return Array.from(rowsById.values())
    .map(row => ({ row, score: scoreNodeSearchMatch(row, search) }))
    .sort((a, b) => b.score - a.score)
    .slice(0, limit)
    .map(entry => mapNodeRow(entry.row));
}

function searchNodesFts(search, filters, limit) {
  const db = getDb();
  const ftsQuery = sanitizeFtsQuery(search);
  if (!ftsQuery) return [];

  const ftsExists = db.prepare("SELECT 1 FROM sqlite_master WHERE type='table' AND name='nodes_fts'").get();
  if (!ftsExists) return [];

  const { clauses, params } = buildNodeFilterClauses(filters);
  const whereClause = clauses.length > 0 ? `WHERE ${clauses.join(' AND ')}` : '';

  try {
    return query(`
      WITH fts_matches AS (
        SELECT rowid, rank
        FROM nodes_fts
        WHERE nodes_fts MATCH ?
        LIMIT ?
      )
      SELECT n.id, n.title, n.description, n.source, n.link, n.event_date, n.metadata,
             n.created_at, n.updated_at,
             fm.rank
      FROM fts_matches fm
      JOIN nodes n ON n.id = fm.rowid
      ${whereClause}
      ORDER BY fm.rank
      LIMIT ?
    `, [ftsQuery, Math.max(limit * 2, 50), ...params, limit]);
  } catch {
    return [];
  }
}

function searchNodesLike(search, filters, limit) {
  const words = search.split(/\s+/).filter(Boolean);
  const { clauses, params } = buildNodeFilterClauses(filters);
  let sql = `
    SELECT n.id, n.title, n.description, n.source, n.link, n.event_date, n.metadata,
           n.created_at, n.updated_at
    FROM nodes n
    WHERE 1=1
  `;
  const queryParams = [...params];

  if (clauses.length > 0) {
    sql += ` AND ${clauses.join(' AND ')}`;
  }

  for (const word of words) {
    sql += ` AND (n.title LIKE ? COLLATE NOCASE OR n.description LIKE ? COLLATE NOCASE OR n.source LIKE ? COLLATE NOCASE)`;
    queryParams.push(`%${word}%`, `%${word}%`, `%${word}%`);
  }

  sql += ` ORDER BY
    CASE WHEN LOWER(n.title) = LOWER(?) THEN 1 ELSE 6 END,
    CASE WHEN LOWER(n.title) LIKE LOWER(?) THEN 2 ELSE 6 END,
    CASE WHEN n.title LIKE ? COLLATE NOCASE THEN 3 ELSE 6 END,
    CASE WHEN n.description LIKE ? COLLATE NOCASE THEN 4 ELSE 6 END,
    CASE WHEN n.source LIKE ? COLLATE NOCASE THEN 5 ELSE 6 END,
    n.updated_at DESC
    LIMIT ?`;

  queryParams.push(search, `${search}%`, `%${search}%`, `%${search}%`, `%${search}%`, limit);
  return query(sql, queryParams);
}

function searchNodesLikeRelaxed(search, filters, limit) {
  const terms = extractRelaxedSearchTerms(search);
  if (terms.length === 0) return [];

  const { clauses, params } = buildNodeFilterClauses(filters);
  let sql = `
    SELECT n.id, n.title, n.description, n.source, n.link, n.event_date, n.metadata,
           n.created_at, n.updated_at
    FROM nodes n
    WHERE 1=1
  `;
  const queryParams = [...params];

  if (clauses.length > 0) {
    sql += ` AND ${clauses.join(' AND ')}`;
  }

  const termClauses = [];
  for (const term of terms) {
    termClauses.push(`n.title LIKE ? COLLATE NOCASE`);
    termClauses.push(`n.description LIKE ? COLLATE NOCASE`);
    termClauses.push(`n.source LIKE ? COLLATE NOCASE`);
    queryParams.push(`%${term}%`, `%${term}%`, `%${term}%`);
  }

  sql += ` AND (${termClauses.join(' OR ')})`;

  const scoreClauses = [];
  const scoreParams = [];
  for (const term of terms) {
    scoreClauses.push(`CASE WHEN n.title LIKE ? COLLATE NOCASE THEN 3 ELSE 0 END`);
    scoreClauses.push(`CASE WHEN n.description LIKE ? COLLATE NOCASE THEN 2 ELSE 0 END`);
    scoreClauses.push(`CASE WHEN n.source LIKE ? COLLATE NOCASE THEN 1 ELSE 0 END`);
    scoreParams.push(`%${term}%`, `%${term}%`, `%${term}%`);
  }

  sql += ` ORDER BY
    (${scoreClauses.join(' + ')}) DESC,
    CASE WHEN LOWER(n.title) LIKE LOWER(?) THEN 0 ELSE 1 END,
    n.updated_at DESC
    LIMIT ?`;

  queryParams.push(...scoreParams, `%${search}%`, limit);
  return query(sql, queryParams);
}

/**
 * Get nodes with optional filtering.
 */
function getNodes(filters = {}) {
  const { search, limit = 100, offset = 0 } = filters;

  if (normalizeString(search)) {
    return searchNodes(filters);
  }

  let sql = `
    SELECT n.id, n.title, n.description, n.source, n.link, n.event_date, n.metadata,
           n.created_at, n.updated_at
    FROM nodes n
    WHERE 1=1
  `;
  const params = [];

  // Text search
  if (search) {
    sql += ` AND (n.title LIKE ? COLLATE NOCASE OR n.description LIKE ? COLLATE NOCASE OR n.source LIKE ? COLLATE NOCASE)`;
    params.push(`%${search}%`, `%${search}%`, `%${search}%`);
  }
  // Sort by search relevance or updated_at
  if (search) {
    sql += ` ORDER BY
      CASE WHEN LOWER(n.title) = LOWER(?) THEN 1 ELSE 6 END,
      CASE WHEN LOWER(n.title) LIKE LOWER(?) THEN 2 ELSE 6 END,
      CASE WHEN n.title LIKE ? COLLATE NOCASE THEN 3 ELSE 6 END,
      CASE WHEN n.description LIKE ? COLLATE NOCASE THEN 4 ELSE 6 END,
      n.updated_at DESC`;
    params.push(search, `${search}%`, `%${search}%`, `%${search}%`);
  } else {
    sql += ' ORDER BY n.updated_at DESC';
  }

  sql += ` LIMIT ?`;
  params.push(limit);

  if (offset > 0) {
    sql += ` OFFSET ?`;
    params.push(offset);
  }

  const rows = query(sql, params);

  return rows.map(mapNodeRow);
}

/**
 * Get a single node by ID.
 */
function getNodeById(id) {
  const sql = `
    SELECT n.id, n.title, n.description, n.source, n.link, n.event_date, n.metadata,
           n.created_at, n.updated_at
    FROM nodes n
    WHERE n.id = ?
  `;

  const rows = query(sql, [id]);
  if (rows.length === 0) return null;

  const row = rows[0];
  return mapNodeRow(row);
}

/**
 * Sanitize title — strip extraction artifacts.
 */
function sanitizeTitle(title) {
  let clean = title.trim();
  if (clean.startsWith('Title: ')) clean = clean.slice(7);
  if (clean.endsWith(' / X')) clean = clean.slice(0, -4);
  clean = clean.replace(/\s+/g, ' ');
  return clean.slice(0, 160);
}

function getChunkStatusForSource(sourceText) {
  return normalizeString(sourceText) ? 'not_chunked' : null;
}

/**
 * Create a new node.
 */
function createNode(nodeData) {
  const {
    title: rawTitle,
    description,
    source,
    link,
    event_date,
    metadata = {}
  } = nodeData;

  const title = sanitizeTitle(rawTitle);

  const canonicalMetadata = buildCanonicalMetadata({ metadata });
  const now = new Date().toISOString();
  const db = getDb();

  const sourceToStore = source ?? ([title, description].filter(Boolean).join('\n\n').trim() || null);
  const chunkStatus = getChunkStatusForSource(sourceToStore);

  const nodeId = transaction(() => {
    const stmt = db.prepare(`
      INSERT INTO nodes (title, description, source, link, event_date, metadata, chunk_status, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `);

    const result = stmt.run(
      title,
      description ?? null,
      sourceToStore,
      link ?? null,
      event_date ?? null,
      JSON.stringify(canonicalMetadata),
      chunkStatus,
      now,
      now
    );

    return Number(result.lastInsertRowid);
  });

  return getNodeById(nodeId);
}

/**
 * Update an existing node.
 */
function updateNode(id, updates, options = {}) {
  const { title, description, source, link, event_date, metadata } = updates;
  const now = new Date().toISOString();
  const db = getDb();

  // Check node exists
  const existing = getNodeById(id);
  if (!existing) {
    throw new Error(`Node with ID ${id} not found. Use rah_search_nodes to find nodes by keyword.`);
  }

  const mergedMetadata = metadata !== undefined
    ? buildCanonicalMetadata({ existing: existing.metadata, metadata })
    : undefined;
  const sourceWasProvided = Object.prototype.hasOwnProperty.call(updates, 'source');
  const normalizedSource = sourceWasProvided ? normalizeString(source) : undefined;

  transaction(() => {
    const setFields = [];
    const params = [];

    if (title !== undefined) {
      setFields.push('title = ?');
      params.push(title);
    }
    if (description !== undefined) {
      setFields.push('description = ?');
      params.push(description);
    }
    if (source !== undefined) {
      setFields.push('source = ?');
      params.push(source);
    }
    if (link !== undefined) {
      setFields.push('link = ?');
      params.push(link);
    }
    if (event_date !== undefined) {
      setFields.push('event_date = ?');
      params.push(event_date);
    }
    if (sourceWasProvided) {
      setFields.push('chunk_status = ?');
      params.push(getChunkStatusForSource(normalizedSource));
    }
    if (mergedMetadata !== undefined) {
      setFields.push('metadata = ?');
      params.push(JSON.stringify(mergedMetadata));
    }

    // Always update timestamp
    setFields.push('updated_at = ?');
    params.push(now);
    params.push(id);

    if (setFields.length > 1) {
      const stmt = db.prepare(`UPDATE nodes SET ${setFields.join(', ')} WHERE id = ?`);
      stmt.run(...params);
    }

  });

  return getNodeById(id);
}

/**
 * Delete a node.
 */
function deleteNode(id) {
  const result = query('DELETE FROM nodes WHERE id = ?', [id]);
  if (result.changes === 0) {
    throw new Error(`Node with ID ${id} not found. Use rah_search_nodes to find nodes by keyword.`);
  }
  return true;
}

/**
 * Get node count.
 */
function getNodeCount() {
  const rows = query('SELECT COUNT(*) as count FROM nodes');
  return Number(rows[0].count);
}

/**
 * Get knowledge graph context overview.
 * Returns stats, hub nodes, and recent activity.
 */
function getContext() {
  const nodeCount = query('SELECT COUNT(*) as count FROM nodes')[0].count;
  const edgeCount = query('SELECT COUNT(*) as count FROM edges')[0].count;

  const recentNodes = query(`
    SELECT n.id, n.title, n.description
    FROM nodes n
    ORDER BY n.created_at DESC
    LIMIT 5
  `);

  const hubNodes = query(`
    SELECT n.id, n.title, n.description, COUNT(e.id) as edge_count
    FROM nodes n
    LEFT JOIN edges e ON n.id = e.from_node_id OR n.id = e.to_node_id
    GROUP BY n.id
    ORDER BY edge_count DESC
    LIMIT 10
  `);

  return {
    stats: { nodeCount, edgeCount, dimensionCount: 0 },
    recentNodes,
    hubNodes
  };
}

module.exports = {
  getNodes,
  searchNodes,
  getNodeById,
  createNode,
  updateNode,
  deleteNode,
  getNodeCount,
  getContext
};
