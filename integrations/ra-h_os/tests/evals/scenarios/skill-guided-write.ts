import { Scenario } from '../types';

export const scenario: Scenario = {
  id: 'skill-guided-write',
  name: 'Skill-guided skill authoring',
  description: 'Explicit skill-authoring work should read the create-skill doctrine, then write the requested reusable skill cleanly.',
  categories: ['skills'],
  tools: ['readSkill', 'writeSkill'],
  input: {
    message: 'Using your create-skill guidance, create a new skill called "capture-source" for repeatable workflows where the user wants to preserve raw source text while adding a strong description.',
  },
  expect: {
    skillsReadSoft: ['create-skill'],
    toolsCalledSoft: ['readSkill', 'writeSkill'],
    responseContainsSoft: ['capture-source'],
    maxLatencyMs: 35000,
    maxTotalTokens: 12000,
    maxEstimatedCostUsd: 0.12,
  },
};
