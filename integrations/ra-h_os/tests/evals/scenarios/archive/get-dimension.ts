import { Scenario } from '../types';

export const scenario: Scenario = {
  id: 'get-dimension',
  name: 'Get single dimension (archived)',
  description: 'Historical pre-migration scenario retained only as an archived reference for the removed dimensions contract.',
  tools: ['getDimension'],
  input: {
    message: 'Historical reference only: get details for the dimension "ai".',
  },
  expect: {
    toolsCalledSoft: ['getDimension'],
    responseContainsSoft: ['ai'],
  },
};
