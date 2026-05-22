import { Scenario } from '../types';

export const scenario: Scenario = {
  id: 'dimension-lifecycle',
  name: 'Dimension lifecycle (archived)',
  description: 'Historical pre-migration scenario retained only as an archived reference for the removed dimensions contract.',
  tools: ['createDimension', 'updateDimension', 'lockDimension', 'unlockDimension'],
  input: {
    message: 'Historical reference only: create a dimension named "eval-dim" with description "temporary eval dimension", then update the description to "eval dimension updated", then lock it, then unlock it.',
  },
  expect: {
    toolsCalledSoft: ['createDimension', 'updateDimension', 'lockDimension', 'unlockDimension'],
    responseContainsSoft: ['eval-dim'],
  },
};
