import { Scenario } from '../types';

export const scenario: Scenario = {
  id: 'create-node',
  name: 'Create node request',
  description: 'Create a new node via chat.',
  tools: ['createNode'],
  input: {
    message: 'Create a node titled "Eval: Test Node" with a short summary about evals.',
  },
  expect: {
    toolsCalledSoft: ['createNode'],
    responseContainsSoft: ['node', 'created', 'added'],
  },
};
