import { Scenario } from '../types';

export const scenario: Scenario = {
  id: 'update-node',
  name: 'Update node content',
  description: 'Create and then update a node in one request.',
  tools: ['createNode', 'updateNode'],
  input: {
    message: 'Create a node titled "Eval: Update Node" with one sentence, then append one more sentence to it.',
  },
  expect: {
    toolsCalledSoft: ['createNode', 'updateNode'],
    responseContainsSoft: ['updated', 'appended'],
  },
};
