// Tool group definitions and utilities
export interface ToolGroup {
  id: string;
  name: string;
  description: string;
  icon: string;
  color: string;
}

export const TOOL_GROUPS: Record<string, ToolGroup> = {
  core: {
    id: 'core',
    name: 'Core Graph',
    description: 'Read-only knowledge graph queries and search (all agents)',
    icon: '●',
    color: '#3b82f6'
  },
  orchestration: {
    id: 'orchestration',
    name: 'Orchestration',
    description: 'Workflows, web search, and reasoning (orchestrator only)',
    icon: '●',
    color: '#8b5cf6'
  },
  execution: {
    id: 'execution',
    name: 'Execution',
    description: 'Write operations, extraction, and embeddings (workers only)',
    icon: '●',
    color: '#10b981'
  }
};

// Tool group assignments
export const TOOL_GROUP_ASSIGNMENTS: Record<string, string> = {
  // Core: Read-only graph operations (all agents)
  queryNodes: 'core',
  retrieveQueryContext: 'core',
  getNodesById: 'core',
  queryEdge: 'core',
  searchContentEmbeddings: 'core',
  listSkills: 'core',
  readSkill: 'core',

  // Orchestration: Web search and reasoning (orchestrator only)
  webSearch: 'orchestration',
  think: 'orchestration',

  // Execution: Write operations and extraction (workers only)
  createNode: 'execution',
  updateNode: 'execution',
  deleteNode: 'execution',
  createEdge: 'execution',
  updateEdge: 'execution',
  embedContent: 'execution',
  youtubeExtract: 'execution',
  websiteExtract: 'execution',
  paperExtract: 'execution',
  writeSkill: 'execution',
  deleteSkill: 'execution'
};

/**
 * Get tool group by tool ID
 */
export function getToolGroup(toolId: string): ToolGroup | null {
  const groupId = TOOL_GROUP_ASSIGNMENTS[toolId];
  return groupId ? TOOL_GROUPS[groupId] : null;
}

/**
 * Group tools by their assigned groups
 */
export function groupTools(toolIds: string[]): Record<string, string[]> {
  const grouped: Record<string, string[]> = {};
  
  toolIds.forEach(toolId => {
    const groupId = TOOL_GROUP_ASSIGNMENTS[toolId] || 'other';
    if (!grouped[groupId]) {
      grouped[groupId] = [];
    }
    grouped[groupId].push(toolId);
  });
  
  return grouped;
}

/**
 * Get all available tools organized by groups
 */
export function getAllToolsByGroup(): Record<string, string[]> {
  return groupTools(Object.keys(TOOL_GROUP_ASSIGNMENTS));
}
