export type AgentRole = 'orchestrator' | 'executor' | 'planner';

export interface AgentDefinition {
  id: number;
  key: string;
  displayName: string;
  description: string | null;
  model: string;
  role: AgentRole;
  systemPrompt: string;
  availableTools: string[];
  enabled: boolean;
  createdAt: string;
  updatedAt: string;
  memory?: Record<string, unknown> | null;
  prompts?: Array<{ id: string; name: string; content: string }>;
}

export interface AgentSummary {
  key: string;
  displayName: string;
  role: AgentRole;
  model: string;
  enabled: boolean;
}
