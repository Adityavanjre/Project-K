import { Scenario } from '../types';

export const scenario: Scenario = {
  id: 'create-edge',
  name: 'Create edge between two new nodes',
  description: 'Create two nodes and connect them with an edge.',
  tools: ['createNode', 'createEdge'],
  input: {
    message: 'Create nodes titled "Eval Edge A" and "Eval Edge B" (one sentence each), then create an edge from A to B labeled "related".',
  },
  expect: {
    toolsCalledSoft: ['createNode', 'createEdge'],
    responseContainsSoft: ['edge', 'connected'],
  },
};
