'use strict';

const nodeService = require('./nodeService');

const SEARCH_STOP_WORDS = new Set([
  'a', 'about', 'added', 'already', 'an', 'and', 'are', 'as', 'at', 'be', 'by',
  'can', 'created', 'do', 'find', 'for', 'from', 'hello', 'i', 'in', 'into', 'is',
  'it', 'just', 'look', 'me', 'my', 'node', 'of', 'on', 'or', 'pull', 'recent',
  'recently', 'saved', 'shared', 'show', 'some', 'stuff', 'term', 'that', 'the', 'this',
  'to', 'versus', 'were', 'what', 'with', 'wrote', 'you', 'doing', 'going', 'having',
]);

function normalizeSearchText(value) {
  return String(value || '')
    .toLowerCase()
    .replace(/\b([a-z0-9]{1,3})-([a-z0-9]{1,3})(?:-([a-z0-9]{1,3}))?\b/gi, (_match, a, b, c) => `${a}${b}${c || ''}`)
    .replace(/[^a-z0-9]+/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function singularizeTerm(term) {
  if (term.endsWith('ies') && term.length > 4) return `${term.slice(0, -3)}y`;
  if (term.endsWith('s') && term.length > 4 && !term.endsWith('ss') && !term.endsWith('us')) {
    return term.slice(0, -1);
  }
  return term;
}

function getHighSignalSearchTerms(query) {
  const seen = new Set();
  const terms = [];

  for (const rawTerm of normalizeSearchText(query).split(' ')) {
    const term = singularizeTerm(rawTerm.trim());
    if (!term || term.length < 3) continue;
    if (SEARCH_STOP_WORDS.has(term)) continue;
    if (seen.has(term)) continue;
    seen.add(term);
    terms.push(term);
  }

  return terms;
}

function countHighSignalQueryTermMatches(node, query) {
  const terms = getHighSignalSearchTerms(query);
  if (terms.length === 0) return 0;

  const haystack = [
    normalizeSearchText(node.title || ''),
    normalizeSearchText(node.description || ''),
    normalizeSearchText(node.source || ''),
  ].join(' ');

  return terms.filter(term => haystack.includes(term)).length;
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

function scoreNodeSearchMatch(node, query) {
  const normalizedQuery = normalizeSearchText(query);
  const normalizedTitle = normalizeSearchText(node.title || '');
  const normalizedDescription = normalizeSearchText(node.description || '');
  const normalizedSource = normalizeSearchText(node.source || '');
  const terms = getHighSignalSearchTerms(query);

  let score = 0;

  if (normalizedTitle === normalizedQuery) score += 2000;
  if (normalizedTitle.startsWith(normalizedQuery)) score += 1200;
  if (normalizedTitle.includes(normalizedQuery)) score += 700;
  if (orderedTermMatches(normalizedTitle, terms)) score += 500;
  if (terms.length > 0 && terms.every(term => normalizedTitle.includes(term))) score += 350;

  if (normalizedDescription.includes(normalizedQuery)) score += 180;
  if (orderedTermMatches(normalizedDescription, terms)) score += 120;
  if (normalizedSource.includes(normalizedQuery)) score += 90;

  const matchedTermCount = countHighSignalQueryTermMatches(node, query);
  score += matchedTermCount * 120;
  if (terms.length > 0 && matchedTermCount === terms.length) score += 300;

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

function hasStrongAnchorMatch(nodes, searchTerm) {
  if (!searchTerm || nodes.length === 0) return false;
  const highSignalTerms = getHighSignalSearchTerms(searchTerm);
  const requiredMatches = Math.min(2, highSignalTerms.length || 1);
  return nodes.some(node => countHighSignalQueryTermMatches(node, searchTerm) >= requiredMatches);
}

function directNodeLookup(input = {}) {
  const limit = Math.min(Math.max(input.limit || 10, 1), 50);
  const searchTerm = typeof input.search === 'string' ? input.search.trim() : '';

  if (searchTerm && /^\d+$/.test(searchTerm)) {
    const nodeId = Number(searchTerm);
    const node = nodeService.getNodeById(nodeId);
    return {
      nodes: node ? [node] : [],
      count: node ? 1 : 0,
      filtersApplied: {
        search: searchTerm,
        limit,
      },
    };
  }

  let safeNodes = nodeService.getNodes({
    search: searchTerm || undefined,
    limit,
    createdAfter: input.createdAfter,
    createdBefore: input.createdBefore,
    eventAfter: input.eventAfter,
    eventBefore: input.eventBefore,
  });

  const hadExtraFilters = Boolean(
    input.createdAfter ||
    input.createdBefore ||
    input.eventAfter ||
    input.eventBefore
  );

  if (searchTerm && hadExtraFilters && (safeNodes.length === 0 || !hasStrongAnchorMatch(safeNodes, searchTerm))) {
    console.warn(`directNodeLookupService falling back to plain literal search for "${searchTerm}" after filtered lookup missed a strong anchor match.`);
    safeNodes = nodeService.searchNodes({ search: searchTerm, limit });
  }

  if (searchTerm) {
    safeNodes = safeNodes
      .map(node => ({ node, score: scoreNodeSearchMatch(node, searchTerm) }))
      .sort((a, b) => b.score - a.score || String(b.node.updated_at || '').localeCompare(String(a.node.updated_at || '')))
      .slice(0, limit)
      .map(entry => entry.node);
  } else {
    safeNodes = safeNodes.slice(0, limit);
  }

  return {
    nodes: safeNodes,
    count: safeNodes.length,
    filtersApplied: {
      search: searchTerm || undefined,
      limit,
      createdAfter: input.createdAfter,
      createdBefore: input.createdBefore,
      eventAfter: input.eventAfter,
      eventBefore: input.eventBefore,
    },
  };
}

module.exports = {
  directNodeLookup,
};
