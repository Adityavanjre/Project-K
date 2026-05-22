import { getToolGroup, groupTools, getAllToolsByGroup } from './groups';
import { queryNodesTool } from '../database/queryNodes';
import { retrieveQueryContextTool } from '../database/retrieveQueryContext';
import { getNodesByIdTool } from '../database/getNodesById';
import { queryEdgeTool } from '../database/queryEdge';
import { createNodeTool } from '../database/createNode';
import { updateNodeTool } from '../database/updateNode';
import { deleteNodeTool } from '../database/deleteNode';
import { createEdgeTool } from '../database/createEdge';
import { updateEdgeTool } from '../database/updateEdge';
import { searchContentEmbeddingsTool } from '../other/searchContentEmbeddings';
import { webSearchTool } from '../other/webSearch';
import { thinkTool } from '../other/think';
import { youtubeExtractTool } from '../other/youtubeExtract';
import { websiteExtractTool } from '../other/websiteExtract';
import { paperExtractTool } from '../other/paperExtract';
import { sqliteQueryTool } from '../other/sqliteQuery';
import { listSkillsTool } from '../skills/listSkills';
import { readSkillTool } from '../skills/readSkill';
import { writeSkillTool } from '../skills/writeSkill';
import { deleteSkillTool } from '../skills/deleteSkill';
import { logEvalToolCall } from '@/services/evals/evalsLogger';

// Read tools (graph queries + skills)
const CORE_TOOLS: Record<string, any> = {
  sqliteQuery: sqliteQueryTool,
  queryNodes: queryNodesTool,
  retrieveQueryContext: retrieveQueryContextTool,
  getNodesById: getNodesByIdTool,
  queryEdge: queryEdgeTool,
  searchContentEmbeddings: searchContentEmbeddingsTool,
  listSkills: listSkillsTool,
  readSkill: readSkillTool,
};

// Utility tools
const ORCHESTRATION_TOOLS: Record<string, any> = {
  webSearch: webSearchTool,
  think: thinkTool,
};

// Write tools (includes extraction)
const EXECUTION_TOOLS: Record<string, any> = {
  createNode: createNodeTool,
  updateNode: updateNodeTool,
  deleteNode: deleteNodeTool,
  createEdge: createEdgeTool,
  updateEdge: updateEdgeTool,
  youtubeExtract: youtubeExtractTool,
  websiteExtract: websiteExtractTool,
  paperExtract: paperExtractTool,
  writeSkill: writeSkillTool,
  deleteSkill: deleteSkillTool,
};

export const TOOL_SETS = {
  core: CORE_TOOLS,
  orchestration: ORCHESTRATION_TOOLS,
  execution: EXECUTION_TOOLS,
};

export const TOOLS: Record<string, any> = {
  ...CORE_TOOLS,
  ...ORCHESTRATION_TOOLS,
  ...EXECUTION_TOOLS,
};

const ORCHESTRATOR_TOOL_NAMES = Object.keys(TOOLS);

const EXECUTOR_TOOL_NAMES = Object.keys(TOOLS);

// Note: PLANNER_TOOL_NAMES kept for backwards compatibility but workflows now use specific tool sets
const PLANNER_TOOL_NAMES = [
  ...Object.keys(CORE_TOOLS),
  'webSearch',
  'think',
  'updateNode',
  'createEdge',
];

/**
 * Get tool by ID
 */
export function getTool(toolId: string): any | null {
  return TOOLS[toolId] || null;
}

/**
 * Get tools by IDs (for helper's available_tools)
 */
export function getTools(toolIds: string[]): any[] {
  if (!Array.isArray(toolIds)) {
    console.error('getTools received non-array:', toolIds);
    return [];
  }
  return toolIds.map(id => TOOLS[id]).filter(Boolean);
}

/**
 * Get all available tools
 */
export function getAllTools(): any[] {
  return Object.values(TOOLS);
}

/**
 * Get tool schemas for OpenAI function calling
 */
export function getToolSchemas(toolIds: string[]) {
  return getTools(toolIds).map(tool => tool.schema);
}

/**
 * Get tools for a specific helper by tool names
 * This is the main function used by helper APIs to get their assigned tools
 */
export function getHelperTools(availableToolNames: string[]): Record<string, any> {
  if (!Array.isArray(availableToolNames)) {
    console.error('getHelperTools received non-array:', availableToolNames);
    return {};
  }
  
  return availableToolNames.reduce((tools, name) => {
    if (TOOLS[name]) {
      tools[name] = wrapToolForEvalLogging(name, TOOLS[name]);
    } else {
      console.warn(`Tool '${name}' not found in registry`);
    }
    return tools;
  }, {} as Record<string, any>);
}

export function getDefaultToolNamesForRole(role: 'orchestrator' | 'executor' | 'planner'): string[] {
  if (role === 'orchestrator') {
    return [...ORCHESTRATOR_TOOL_NAMES];
  }
  if (role === 'planner') {
    return [...PLANNER_TOOL_NAMES];
  }
  return [...EXECUTOR_TOOL_NAMES];
}

export function getToolsForRole(role: 'orchestrator' | 'executor' | 'planner'): Record<string, any> {
  const names = getDefaultToolNamesForRole(role);
  return getHelperTools(names);
}

/**
 * Get tools by their names (for workflow execution with specific tool sets)
 */
export function getToolsByNames(toolNames: string[]): Record<string, any> {
  if (!Array.isArray(toolNames) || toolNames.length === 0) {
    console.warn('[getToolsByNames] No tool names provided');
    return {};
  }
  return getHelperTools(toolNames);
}

/**
 * Execute a tool with given parameters and context
 */
export async function executeTool(toolId: string, params: any, context: any) {
  const tool = getTool(toolId);
  
  if (!tool) {
    return {
      success: false,
      error: `Tool '${toolId}' not found`,
      data: null
    };
  }
  
  const startedAt = Date.now();
  try {
    const result = await tool.execute(params, context);
    logEvalToolCall({
      toolName: toolId,
      args: params,
      result,
      latencyMs: Date.now() - startedAt
    });
    return result;
  } catch (error) {
    logEvalToolCall({
      toolName: toolId,
      args: params,
      error,
      latencyMs: Date.now() - startedAt
    });
    return {
      success: false,
      error: error instanceof Error ? error.message : `Tool '${toolId}' execution failed`,
      data: null
    };
  }
}

function wrapToolForEvalLogging(toolName: string, tool: any) {
  if (!tool || typeof tool.execute !== 'function') {
    return tool;
  }

  return {
    ...tool,
    execute: async (params: any, context: any) => {
      const startedAt = Date.now();
      try {
        const result = await tool.execute(params, context);
        logEvalToolCall({
          toolName,
          args: params,
          result,
          latencyMs: Date.now() - startedAt
        });
        return result;
      } catch (error) {
        logEvalToolCall({
          toolName,
          args: params,
          error,
          latencyMs: Date.now() - startedAt
        });
        throw error;
      }
    }
  };
}

// Export group utilities
export { getToolGroup, groupTools, getAllToolsByGroup };
