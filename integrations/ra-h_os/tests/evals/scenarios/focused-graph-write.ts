import { Scenario } from '../types';

export const scenario: Scenario = {
  id: 'focused-graph-write',
  name: 'Focused graph write',
  description: 'Create one new node from the focused transcript and connect it back without unnecessary retrieval.',
  tools: ['createNode', 'createEdge'],
  input: {
    message: 'Create a new node titled "Lange: Verification bottleneck" for the claim that generating many solutions is easier than verifying them, then connect it to this focused transcript with explanation "Claim extracted from this transcript source."',
    focusedNodeQuery: { titleContains: 'When AI Discovers the Next Transformer' },
  },
  expect: {
    toolsCalledSoft: ['createNode', 'createEdge'],
    toolsNotCalledSoft: ['readSkill', 'queryNodes', 'searchContentEmbeddings'],
    responseContainsSoft: ['Lange: Verification bottleneck'],
    maxLatencyMs: 25000,
    maxTotalTokens: 9000,
    maxEstimatedCostUsd: 0.08,
  },
};
