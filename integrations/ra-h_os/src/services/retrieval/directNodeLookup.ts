import { nodeService } from '@/services/database/nodes';
import { countHighSignalQueryTermMatches, getHighSignalSearchTerms, scoreNodeSearchMatch } from '@/services/database/searchRanking';
import type { Node } from '@/types/database';

export interface DirectNodeLookupInput {
  search?: string;
  limit?: number;
  createdAfter?: string;
  createdBefore?: string;
  eventAfter?: string;
  eventBefore?: string;
}

export interface DirectNodeLookupResult {
  nodes: Node[];
  count: number;
  filtersApplied: {
    search?: string;
    limit: number;
    createdAfter?: string;
    createdBefore?: string;
    eventAfter?: string;
    eventBefore?: string;
  };
}

function hasStrongAnchorMatch(nodes: Node[], searchTerm: string): boolean {
  if (!searchTerm || nodes.length === 0) return false;
  const highSignalTerms = getHighSignalSearchTerms(searchTerm);
  const requiredMatches = Math.min(2, highSignalTerms.length || 1);
  return nodes.some(node => countHighSignalQueryTermMatches(node, searchTerm) >= requiredMatches);
}

export async function directNodeLookup(input: DirectNodeLookupInput): Promise<DirectNodeLookupResult> {
  const limit = Math.min(Math.max(input.limit ?? 10, 1), 50);
  const searchTerm = input.search?.trim();

  if (searchTerm && /^\d+$/.test(searchTerm)) {
    const nodeId = Number(searchTerm);
    const node = await nodeService.getNodeById(nodeId);
    return {
      nodes: node ? [node] : [],
      count: node ? 1 : 0,
      filtersApplied: {
        search: searchTerm,
        limit,
      },
    };
  }

  const effectiveFilters = {
    search: searchTerm,
    limit,
    searchMode: 'standard' as const,
    createdAfter: input.createdAfter,
    createdBefore: input.createdBefore,
    eventAfter: input.eventAfter,
    eventBefore: input.eventBefore,
  };

  let safeNodes = await nodeService.getNodes(effectiveFilters);

  const hadExtraFilters = Boolean(
    effectiveFilters.createdAfter ||
    effectiveFilters.createdBefore ||
    effectiveFilters.eventAfter ||
    effectiveFilters.eventBefore
  );

  if (searchTerm && hadExtraFilters && (safeNodes.length === 0 || !hasStrongAnchorMatch(safeNodes, searchTerm))) {
    console.warn(`directNodeLookup falling back to plain literal search for "${searchTerm}" after filtered lookup missed a strong anchor match.`);
    safeNodes = await nodeService.searchNodes(searchTerm, limit);
  }

  if (searchTerm) {
    safeNodes = safeNodes
      .map(node => ({ node, score: scoreNodeSearchMatch(node, searchTerm) }))
      .sort((a, b) => b.score - a.score || b.node.updated_at.localeCompare(a.node.updated_at))
      .slice(0, limit)
      .map(entry => entry.node);
  } else {
    safeNodes = safeNodes.slice(0, limit);
  }

  return {
    nodes: safeNodes,
    count: safeNodes.length,
    filtersApplied: {
      search: searchTerm,
      limit,
      createdAfter: input.createdAfter,
      createdBefore: input.createdBefore,
      eventAfter: input.eventAfter,
      eventBefore: input.eventBefore,
    },
  };
}
