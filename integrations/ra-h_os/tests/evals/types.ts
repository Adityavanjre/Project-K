export type EvalCategory = 'database' | 'tools' | 'skills' | 'search' | 'ingestion';

export type ScenarioExpectations = {
  skillsRead?: string[];
  skillsReadSoft?: string[];
  skillsNotRead?: string[];
  skillsNotReadSoft?: string[];
  toolsCalled?: string[];
  toolsCalledSoft?: string[];
  toolsNotCalled?: string[];
  toolsNotCalledSoft?: string[];
  responseContains?: string[];
  responseContainsSoft?: string[];
  responseNotContains?: string[];
  maxLatencyMs?: number;
  maxTotalTokens?: number;
  maxEstimatedCostUsd?: number;
};

export type ScenarioInput = {
  message: string;
  focusedNodeId?: number;
  focusedNodeQuery?: {
    titleContains?: string;
    titleEquals?: string;
  };
  mode?: 'easy' | 'hard';
};

export type Scenario = {
  id: string;
  name: string;
  input: ScenarioInput;
  expect?: ScenarioExpectations;
  description?: string;
  tools?: string[];
  categories?: EvalCategory[];
  suites?: string[];
  enabled?: boolean;
  notes?: string;
};
