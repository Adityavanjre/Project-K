import { Scenario } from '../types';

export const scenario: Scenario = {
  id: 'chunk-quote-insight',
  name: 'Chunk quote to insight',
  description: 'Search a focused transcript for a specific quote, then create a grounded insight node from it.',
  tools: ['searchContentEmbeddings', 'createNode', 'createEdge'],
  input: {
    message: 'Search inside this focused transcript for a quote about verification being harder than generating solutions. Quote it briefly, then create a new insight node titled "Lange on verification difficulty" and connect it back to this transcript with explanation "Insight extracted from quoted passage."',
    focusedNodeQuery: { titleContains: 'When AI Discovers the Next Transformer' },
  },
  expect: {
    toolsCalledSoft: ['searchContentEmbeddings', 'createNode', 'createEdge'],
    responseContainsSoft: ['Lange on verification difficulty'],
    maxLatencyMs: 35000,
    maxTotalTokens: 14000,
    maxEstimatedCostUsd: 0.14,
  },
};
