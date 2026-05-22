'use strict';

const { getDb, query } = require('./sqlite-client');
const nodeService = require('./nodeService');
const edgeService = require('./edgeService');

const LOW_SIGNAL_PATTERNS = [
  /^(yes|yeah|yep|no|nope|nah|ok|okay|cool|great|nice|thanks|thank you|sure|sounds good|go ahead|do it)[.!]?$/i,
  /^(hi|hello|hey)[.!]?$/i,
  /^(test|testing)[.!]?$/i,
];

const FOCUSED_SOURCE_PATTERN = /\b(this|focused|current)\s+(node|source|transcript|paper|article|video|document|note)\b|\b(inside|within|in)\s+(this|focused|current)\s+(node|source|transcript|paper|article|video|document|note)\b/i;
const SOURCE_DETAIL_PATTERN = /\b(quote|quotes|exact|specific|where|search|find|what did|what does|say|inside|within|transcript|paper|article|source|document|video)\b/i;
const USER_RECALL_PATTERN = /\b(what were (they|those)|what was (it|that)|what did i|what was my|what were my|do you remember|remind me)\b/i;
const FIRST_PERSON_PATTERN = /\b(i|my|me)\b/i;
const FIRST_PERSON_SHARE_PATTERN = /\b(i|my|me)\b.*\b(shared|mentioned|talked about|spoke about|said|posted)\b|\b(shared|mentioned|talked about|spoke about|said|posted)\b.*\b(i|my|me)\b/i;
const LOOKUP_PATTERN = /\b(find|look|search|show|get|pull)\b/i;
const EXPLICIT_HISTORY_QUERY_PATTERN = /\b(what have i said about|what did i say about)\b/i;
const DIRECT_NODE_TYPE_PATTERN = /\b(node|podcast|article|paper|video|note|idea|project|person|reflection|post|thread)\b/i;
const NOTE_HINT_PATTERN = /\b(idea|ideas|insight|insights|note|notes|thought|thoughts|reflection|reflections|realisation|realization|observation|observations|writing)\b/i;
const RECENT_REFERENCE_PATTERN = /\b(recent|recently|today|this morning|earlier|just)\b/i;
const NOTE_TERMS = new Set([
  'idea',
  'insight',
  'note',
  'node',
  'thought',
  'reflection',
  'realisation',
  'realization',
  'observation',
  'writing',
]);
const HIGH_SIGNAL_STOP_WORDS = new Set([
  'a', 'about', 'added', 'already', 'an', 'and', 'are', 'as', 'at', 'be', 'created',
  'db', 'did', 'do', 'does', 'earlier', 'find', 'for', 'from', 'get', 'had',
  'have', 'i', 'if', 'in', 'into', 'is', 'it', 'just', 'look', 'me', 'my',
  'being', 'said', 'going', 'having', 'node', 'of', 'on', 'pull', 'recent',
  'recently', 'search', 'shared', 'show', 'some', 'that', 'the', 'they', 'this',
  'those', 'to', 'today', 'user', 'versus', 'was', 'were', 'what', 'with', 'doing',
]);

function normalizeWhitespace(value) {
  return String(value || '').replace(/\s+/g, ' ').trim();
}

function collapseCompactHyphenatedTerms(value) {
  return String(value || '').replace(/\b([a-z0-9]{1,3})-([a-z0-9]{1,3})(?:-([a-z0-9]{1,3}))?\b/gi, (_match, a, b, c) => {
    return `${a}${b}${c || ''}`;
  });
}

function truncateText(value, maxLength = 180) {
  const text = normalizeWhitespace(value);
  if (!text) return '';
  if (text.length <= maxLength) return text;
  return `${text.slice(0, maxLength - 1)}…`;
}

function queryTermCount(queryText) {
  return normalizeWhitespace(queryText).split(' ').filter(Boolean).length;
}

function singularizeTerm(term) {
  if (term.endsWith('ies') && term.length > 4) {
    return `${term.slice(0, -3)}y`;
  }
  if (term.endsWith('s') && term.length > 4 && !term.endsWith('ss') && !term.endsWith('us')) {
    return term.slice(0, -1);
  }
  return term;
}

function normalizeRecallText(value) {
  return collapseCompactHyphenatedTerms(normalizeWhitespace(value || ''))
    .toLowerCase()
    .replace(/[^a-z0-9\s]+/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function normalizeSearchText(value) {
  return normalizeRecallText(value);
}

function extractHighSignalTerms(queryText) {
  const rawTerms = collapseCompactHyphenatedTerms(normalizeWhitespace(queryText))
    .toLowerCase()
    .replace(/[^a-z0-9\s]+/g, ' ')
    .split(/\s+/)
    .map((term) => singularizeTerm(term.trim()))
    .filter(Boolean);

  const seen = new Set();
  const result = [];

  for (const term of rawTerms) {
    if (term.length < 3) continue;
    if (HIGH_SIGNAL_STOP_WORDS.has(term)) continue;
    if (seen.has(term)) continue;
    seen.add(term);
    result.push(term);
  }

  return result;
}

function extractRecallPhraseVariants(queryText) {
  const normalized = collapseCompactHyphenatedTerms(normalizeWhitespace(queryText))
    .toLowerCase()
    .replace(/[^a-z0-9\s]+/g, ' ');
  const variants = [];
  const tokens = normalized.split(/\s+/).filter(Boolean);

  const pushVariant = (value) => {
    const compact = normalizeWhitespace(value);
    if (!compact || variants.includes(compact)) return;
    variants.push(compact);
  };

  if (/\ball\s+in\b/.test(normalized)) {
    pushVariant('all in');
  }

  if (/\bbackup(?:\s+plan)?\b/.test(normalized)) {
    pushVariant('backup plan');
    pushVariant('backup');
  }

  for (let index = 0; index < tokens.length - 1; index += 1) {
    const first = singularizeTerm(tokens[index]);
    const second = singularizeTerm(tokens[index + 1]);
    if (!first || !second) continue;

    const firstAllowed = first.length >= 4 && !HIGH_SIGNAL_STOP_WORDS.has(first);
    const secondAllowed = second.length >= 4 && !HIGH_SIGNAL_STOP_WORDS.has(second);
    if (firstAllowed && secondAllowed) {
      pushVariant(`${first} ${second}`);
    }
  }

  return variants.slice(0, 6);
}

function buildRecallSearchVariants(queryText) {
  const terms = extractHighSignalTerms(queryText);
  if (terms.length === 0) return [];

  const topicalTerms = terms.filter((term) => !NOTE_TERMS.has(term));
  const noteTerms = terms.filter((term) => NOTE_TERMS.has(term));
  const phraseVariants = extractRecallPhraseVariants(queryText);
  const variants = [];

  const pushVariant = (value) => {
    const normalized = normalizeWhitespace(value);
    if (!normalized || variants.includes(normalized)) return;
    variants.push(normalized);
  };

  phraseVariants.forEach(pushVariant);

  if (phraseVariants.includes('all in') && topicalTerms.includes('backup')) {
    pushVariant('all in backup');
  }

  if (topicalTerms.length > 0 && noteTerms.length > 0) {
    pushVariant(`${topicalTerms.join(' ')} ${noteTerms[0]}`);
    pushVariant(`${topicalTerms[topicalTerms.length - 1]} ${noteTerms[0]}`);
  }
  if (topicalTerms.length >= 2) {
    pushVariant(topicalTerms.slice(0, 2).join(' '));
    pushVariant(topicalTerms.slice(-2).join(' '));
  }
  if (topicalTerms.length > 0) {
    pushVariant(topicalTerms.join(' '));
    const lastTopicalTerm = topicalTerms[topicalTerms.length - 1];
    if (lastTopicalTerm.length >= 6) {
      pushVariant(lastTopicalTerm);
    }
  }
  if (terms.length > 1) {
    pushVariant(terms.join(' '));
  }

  return variants.slice(0, 6);
}

function buildDirectSearchVariants(queryText) {
  const variants = [normalizeWhitespace(queryText), ...buildRecallSearchVariants(queryText)];
  return variants.filter((value, index) => value && variants.indexOf(value) === index).slice(0, 6);
}

function isFocusedSourceRequest(queryText) {
  return FOCUSED_SOURCE_PATTERN.test(queryText);
}

function isLikelyUserNoteRecallQuery(queryText) {
  const normalized = normalizeWhitespace(queryText);
  if (!normalized) return false;

  const explicitRecall = USER_RECALL_PATTERN.test(normalized);
  const firstPersonRecall = FIRST_PERSON_PATTERN.test(normalized) && /\bwhat\b/i.test(normalized);
  const explicitLookup = LOOKUP_PATTERN.test(normalized)
    && (FIRST_PERSON_PATTERN.test(normalized) || /\b(created|saved|wrote|added)\b/i.test(normalized));
  const firstPersonShareRecall = FIRST_PERSON_SHARE_PATTERN.test(normalized);
  const noteHint = NOTE_HINT_PATTERN.test(normalized);
  const recentHint = RECENT_REFERENCE_PATTERN.test(normalized);

  return (explicitRecall || firstPersonRecall || explicitLookup || firstPersonShareRecall) && (noteHint || recentHint);
}

function isDirectNodeRetrievalQuery(queryText) {
  const normalized = normalizeWhitespace(queryText);
  if (!normalized) return false;

  const explicitHistoryQuery = EXPLICIT_HISTORY_QUERY_PATTERN.test(normalized);
  const explicitLookup = LOOKUP_PATTERN.test(normalized)
    && (FIRST_PERSON_PATTERN.test(normalized) || DIRECT_NODE_TYPE_PATTERN.test(normalized) || RECENT_REFERENCE_PATTERN.test(normalized));

  return explicitHistoryQuery
    || explicitLookup
    || FIRST_PERSON_SHARE_PATTERN.test(normalized)
    || isLikelyUserNoteRecallQuery(normalized);
}

function shouldRetrieveForQuery(queryText) {
  const trimmed = normalizeWhitespace(queryText);
  if (!trimmed) return false;
  if (LOW_SIGNAL_PATTERNS.some((pattern) => pattern.test(trimmed))) return false;
  if (isFocusedSourceRequest(trimmed)) return true;
  if (SOURCE_DETAIL_PATTERN.test(trimmed)) return true;
  return trimmed.length >= 12 || queryTermCount(trimmed) >= 3;
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
  const terms = extractHighSignalTerms(queryText);

  let score = 0;

  if (normalizedTitle === normalizedQuery) score += 2000;
  if (normalizedTitle.startsWith(normalizedQuery)) score += 1200;
  if (normalizedTitle.includes(normalizedQuery)) score += 700;
  if (orderedTermMatches(normalizedTitle, terms)) score += 500;
  if (terms.length > 0 && terms.every((term) => normalizedTitle.includes(term))) score += 350;

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

function countHighSignalQueryTermMatches(node, queryText) {
  const terms = extractHighSignalTerms(queryText);
  if (terms.length === 0) return 0;
  const combined = normalizeRecallText(`${node.title || ''} ${node.description || ''} ${node.source || ''}`);
  return terms.filter((term) => combined.includes(term)).length;
}

function isLikelyUserAuthoredNote(node) {
  return !node.link && node.metadata && node.metadata.captured_by === 'human';
}

function scoreRecallMatch(node, queryText) {
  const normalizedTitle = normalizeRecallText(node.title);
  const normalizedDescription = normalizeRecallText(node.description);
  const normalizedSource = normalizeRecallText(node.source);
  const combined = `${normalizedTitle} ${normalizedDescription} ${normalizedSource}`.trim();
  const terms = extractHighSignalTerms(queryText);
  const phraseVariants = extractRecallPhraseVariants(queryText);

  let score = 0;

  if (isLikelyUserAuthoredNote(node)) score += 800;
  if (!node.link) score += 150;

  for (const phrase of phraseVariants) {
    const normalizedPhrase = normalizeRecallText(phrase);
    if (!normalizedPhrase) continue;

    if (normalizedTitle === normalizedPhrase) score += 2500;
    if (normalizedTitle.includes(normalizedPhrase)) score += 1400;
    if (normalizedDescription.includes(normalizedPhrase)) score += 700;
    if (normalizedSource.includes(normalizedPhrase)) score += 900;
  }

  const titleTermMatches = terms.filter((term) => normalizedTitle.includes(term)).length;
  const totalTermMatches = terms.filter((term) => combined.includes(term)).length;

  score += titleTermMatches * 250;
  score += totalTermMatches * 120;

  if (terms.length > 0 && titleTermMatches === terms.length) score += 1200;
  if (terms.length > 0 && totalTermMatches === terms.length) score += 700;

  if (node.updated_at) {
    score += new Date(node.updated_at).getTime() / 1e13;
  }

  return score;
}

function hasStrongRecallMatch(nodes, queryText) {
  return nodes.some((node) => scoreRecallMatch(node, queryText) >= 1800);
}

function addNodeWithReason(target, node, input) {
  if (!node) return;

  const existing = target.get(node.id);
  if (existing) {
    if (input.kind === 'focused' && existing.kind !== 'focused') {
      existing.kind = 'focused';
    }
    if (!existing.reason.includes(input.reason)) {
      existing.reason = `${existing.reason} ${input.reason}`.trim();
    }
    if (input.seedNodeId && !existing.seed_node_id) {
      existing.seed_node_id = input.seedNodeId;
    }
    if (typeof input.searchRank === 'number') {
      existing.search_rank = typeof existing.search_rank === 'number'
        ? Math.min(existing.search_rank, input.searchRank)
        : input.searchRank;
    }
    return;
  }

  target.set(node.id, {
    id: node.id,
    title: node.title,
    description: node.description || null,
    link: node.link || null,
    updated_at: node.updated_at || '',
    kind: input.kind,
    reason: input.reason,
    seed_node_id: input.seedNodeId,
    search_rank: input.searchRank,
  });
}

function rankRetrievedNodes(nodes) {
  const kindWeight = {
    focused: 4,
    query_match: 3,
    context_hint: 2,
    neighbor: 1,
  };

  return [...nodes].sort((a, b) => {
    const kindDiff = kindWeight[b.kind] - kindWeight[a.kind];
    if (kindDiff !== 0) return kindDiff;
    const rankA = typeof a.search_rank === 'number' ? a.search_rank : Number.POSITIVE_INFINITY;
    const rankB = typeof b.search_rank === 'number' ? b.search_rank : Number.POSITIVE_INFINITY;
    if (rankA !== rankB) return rankA - rankB;
    return String(b.updated_at || '').localeCompare(String(a.updated_at || ''));
  });
}

function rankDirectQueryMatches(nodes, queryText, directNodeRetrieval) {
  return [...nodes].sort((a, b) => {
    const scoreDiff = directNodeRetrieval
      ? scoreRecallMatch(b, queryText) - scoreRecallMatch(a, queryText)
      : scoreNodeSearchMatch(b, queryText) - scoreNodeSearchMatch(a, queryText);
    if (scoreDiff !== 0) return scoreDiff;
    return String(b.updated_at || '').localeCompare(String(a.updated_at || ''));
  });
}

function findDirectQueryMatches(queryText, limit) {
  const variants = buildDirectSearchVariants(queryText);
  const matches = [];
  const seen = new Set();

  for (const variant of variants) {
    const rows = nodeService.searchNodes({ search: variant, limit: Math.max(limit, 8) });
    for (const node of rows) {
      if (seen.has(node.id)) continue;
      seen.add(node.id);
      matches.push(node);
    }
  }

  return matches;
}

function sanitizeFtsQuery(input) {
  return String(input || '')
    .toLowerCase()
    .replace(/[^a-z0-9\s]+/g, ' ')
    .trim()
    .split(/\s+/)
    .filter((word) => word.length > 0 && !/^(AND|OR|NOT|NEAR)$/i.test(word))
    .join(' ');
}

function searchChunks(queryText, nodeIds, limit) {
  if (!nodeIds || nodeIds.length === 0) return [];

  const db = getDb();
  const ftsExists = db.prepare("SELECT 1 FROM sqlite_master WHERE type='table' AND name='chunks_fts'").get();
  const ftsQuery = sanitizeFtsQuery(queryText);

  if (ftsExists && ftsQuery) {
    try {
      return query(`
        SELECT c.id, c.node_id, c.chunk_idx, c.text, 0.85 as similarity
        FROM chunks c
        WHERE c.node_id IN (${nodeIds.map(() => '?').join(',')})
          AND c.id IN (
            SELECT rowid
            FROM chunks_fts
            WHERE chunks_fts MATCH ?
          )
        ORDER BY c.chunk_idx ASC
        LIMIT ?
      `, [...nodeIds, ftsQuery, limit]);
    } catch {
      // Fall through to LIKE search.
    }
  }

  const terms = normalizeWhitespace(queryText).split(' ').filter((term) => term.length > 2);
  if (terms.length === 0) return [];

  let sql = `
    SELECT c.id, c.node_id, c.chunk_idx, c.text, 0.75 as similarity
    FROM chunks c
    WHERE c.node_id IN (${nodeIds.map(() => '?').join(',')})
  `;
  const params = [...nodeIds];

  for (const term of terms) {
    sql += ' AND LOWER(c.text) LIKE ?';
    params.push(`%${term.toLowerCase()}%`);
  }

  sql += ' ORDER BY c.chunk_idx ASC LIMIT ?';
  params.push(limit);
  return query(sql, params);
}

function retrieveQueryContext(input = {}) {
  const queryText = normalizeWhitespace(input.query || '');
  const focusedNodeId = input.focused_node_id ?? null;
  const limit = Math.min(Math.max(input.limit || 6, 1), 12);
  const shouldRetrieve = shouldRetrieveForQuery(queryText);

  if (!shouldRetrieve) {
    return {
      query: queryText,
      shouldRetrieve: false,
      mode: 'skip',
      reason: 'Query is too lightweight or conversational to justify retrieval.',
      focused_node_id: focusedNodeId,
      nodes: [],
      chunks: [],
    };
  }

  const focusedRequest = isFocusedSourceRequest(queryText);
  const directNodeRetrieval = isDirectNodeRetrievalQuery(queryText);
  const nodesById = new Map();

  const focusedNode = focusedNodeId ? nodeService.getNodeById(focusedNodeId) : null;
  const focusedOverlap = focusedNode ? countHighSignalQueryTermMatches(focusedNode, queryText) : 0;
  if (focusedNode && (focusedRequest || focusedOverlap >= 2)) {
    addNodeWithReason(nodesById, focusedNode, {
      kind: 'focused',
      reason: focusedRequest
        ? 'Focused node is the primary source for this request.'
        : 'Focused node strongly overlaps the user query and should be considered first.',
    });
  }

  const searchLimit = Math.max(limit * 2, 8);
  const directQueryMatches = rankDirectQueryMatches(
    findDirectQueryMatches(queryText, searchLimit),
    queryText,
    directNodeRetrieval
  );
  const strongRecallMatch = directNodeRetrieval && hasStrongRecallMatch(directQueryMatches, queryText);

  directQueryMatches.forEach((node, index) => {
    addNodeWithReason(nodesById, node, {
      kind: 'query_match',
      reason: directNodeRetrieval
        ? 'Matched the query through direct graph search for a specific existing node.'
        : 'Matched the query through direct graph search.',
      searchRank: index,
    });
  });

  if (!strongRecallMatch) {
    const rankedSeedNodes = rankRetrievedNodes(Array.from(nodesById.values())).slice(0, Math.max(3, limit));
    rankedSeedNodes.slice(0, 3).forEach((seed) => {
      const connections = edgeService.getNodeConnections(seed.id);
      connections.slice(0, 2).forEach((connection) => {
        addNodeWithReason(nodesById, connection.connected_node, {
          kind: 'neighbor',
          reason: `Connected to [NODE:${seed.id}:"${seed.title}"] via graph edges.`,
          seedNodeId: seed.id,
        });
      });
    });
  }

  const finalNodes = rankRetrievedNodes(Array.from(nodesById.values())).slice(0, limit);
  const chunkScopeNodeIds = focusedRequest && focusedNodeId
    ? [focusedNodeId]
    : SOURCE_DETAIL_PATTERN.test(queryText)
      ? finalNodes.slice(0, 3).map((node) => node.id)
      : [];

  const chunks = searchChunks(queryText, chunkScopeNodeIds, Math.min(4, limit)).map((chunk) => {
    const owner = finalNodes.find((node) => node.id === chunk.node_id)
      || directQueryMatches.find((node) => node.id === chunk.node_id);
    return {
      id: chunk.id,
      node_id: chunk.node_id,
      node_title: owner ? owner.title : `Node ${chunk.node_id}`,
      preview: truncateText(chunk.text, 220),
      similarity: chunk.similarity,
    };
  });

  return {
    query: queryText,
    shouldRetrieve: true,
    mode: focusedRequest ? 'focused' : 'query',
    reason: focusedRequest
      ? 'Focused-source request: use the focused node first, then broaden only if needed.'
      : directNodeRetrieval
        ? 'Direct node retrieval query: search the graph directly first and broaden only if needed.'
        : 'Substantive query: search the graph directly, then pull additional supporting context if helpful.',
    focused_node_id: focusedNodeId,
    nodes: finalNodes,
    chunks,
  };
}

module.exports = {
  retrieveQueryContext,
  shouldRetrieveForQuery,
};
