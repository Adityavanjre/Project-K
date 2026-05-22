import { Scenario } from '../types';

export const scenario: Scenario = {
  id: 'node-index-search',
  name: 'Node index search',
  description: 'Simple lookup should stay in node search and avoid chunk retrieval.',
  tools: ['queryNodes'],
  input: {
    message: 'Find me the node about Plaintext Productivity. Just return the matching node.',
  },
  expect: {
    toolsCalledSoft: ['queryNodes'],
    toolsNotCalledSoft: ['searchContentEmbeddings', 'readSkill'],
    responseContainsSoft: ['Plaintext Productivity'],
    maxLatencyMs: 15000,
    maxTotalTokens: 7000,
    maxEstimatedCostUsd: 0.06,
  },
};
