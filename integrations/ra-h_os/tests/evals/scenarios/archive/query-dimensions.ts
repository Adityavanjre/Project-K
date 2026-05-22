import { Scenario } from '../types';

export const scenario: Scenario = {
  id: 'query-dimensions',
  name: 'Legacy dimensions query (archived)',
  description: 'Historical pre-migration scenario retained only as an archived reference for the removed dimensions contract.',
  tools: ['queryDimensions'],
  input: {
    message: 'Historical reference only: list my top dimensions and briefly describe what they represent.',
  },
  expect: {
    toolsCalledSoft: ['queryDimensions'],
    responseContainsSoft: ['dimension'],
  },
};
