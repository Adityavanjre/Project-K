import type { Node } from '@/types/database';

interface RequestContext {
  traceId?: string;
  parentChatId?: number;
  workflowKey?: string;
  workflowNodeId?: number;
  openTabs?: Node[];
  activeTabId?: number | null;
  mode?: 'easy' | 'hard';
  apiKeys?: {
    openai?: string;
    anthropic?: string;
  };
  helperName?: string;
  evalDatasetId?: string;
  evalScenarioId?: string;
  evalChatSpanId?: string;
}

let currentContext: RequestContext = {};

export const RequestContext = {
  set(context: Partial<RequestContext>) {
    Object.entries(context).forEach(([key, value]) => {
      if (value === undefined) {
        delete (currentContext as Record<string, unknown>)[key];
      } else {
        (currentContext as Record<string, unknown>)[key] = value;
      }
    });
  },

  get(): RequestContext {
    return currentContext;
  },

  clear() {
    currentContext = {};
  },
};
