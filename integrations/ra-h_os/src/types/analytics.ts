export interface UsageData {
  inputTokens: number;
  outputTokens: number;
  totalTokens: number;
  cacheWriteTokens?: number;
  cacheReadTokens?: number;
  cacheHit?: boolean;
  cacheSavingsPct?: number;
  estimatedCostUsd: number;
  modelUsed: string;
  provider: 'anthropic' | 'openai';
  toolsUsed?: string[];
  toolCallsCount?: number;
  traceId?: string;
  parentChatId?: number;
  workflowKey?: string;
  workflowNodeId?: number;
  capsuleVersion?: number;
  contextSourcesUsed?: number[];
  validationStatus?: 'ok' | 'failed';
  validationMessage?: string;
  fallbackAction?: string;
  mode?: 'easy' | 'hard';
}

export interface ModelPricing {
  provider: 'anthropic' | 'openai';
  inputPer1M: number;
  outputPer1M: number;
  cacheWritePer1M?: number;
  cacheReadPer1M?: number;
}

