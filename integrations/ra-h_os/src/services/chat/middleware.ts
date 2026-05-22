import { getSQLiteClient } from '@/services/database/sqlite-client';
import { UsageData } from '@/types/analytics';
import { RequestContext } from '@/services/context/requestContext';
import { logEvalChat } from '@/services/evals/evalsLogger';

interface ChatLogEntry {
  chat_type: string;
  user_message: string;
  assistant_message: string;
  thread_id: string;
  focused_node_id: number | null;
  helper_name: string;
  agent_type: 'orchestrator' | 'executor' | 'planner';
  delegation_id: number | null;
  metadata: any;
}

interface StreamMetadata {
  helperName: string;
  openTabs?: any[];
  activeTabId?: number | null;
  currentView?: 'nodes' | 'memory';
  sessionId?: string;
  agentType?: 'orchestrator' | 'executor' | 'planner';
  delegationId?: number | null;
  usageData?: UsageData;
  traceId?: string;
  parentChatId?: number;
  systemMessage?: string;
  promptVersion?: string;
  modelUsed?: string;
  workflowKey?: string;
  workflowNodeId?: number;
  toolCallsData?: any[];
  backendUsage?: Array<{
    provider: string;
    headers: Record<string, string>;
  }>;
  requestStartedAt?: number;
  timingBreakdown?: {
    promptBuildMs?: number;
    toolsBuildMs?: number;
    modelResolveMs?: number;
    messageAssemblyMs?: number;
    streamSetupMs?: number;
    toolLoopMs?: number;
  };
  toolTimingData?: Array<{
    toolName: string;
    durationMs: number;
  }>;
  latencyMs?: number;
  firstTokenLatencyMs?: number | null;
  firstChunkLatencyMs?: number | null;
}

function normalizeToolResult(result: unknown): unknown {
  if (result == null) return null;
  if (typeof result === 'object') return result;
  return { value: result };
}

function collectToolCalls(result: any): any[] | undefined {
  const collected: any[] = [];

  const pushCall = (call: any) => {
    if (!call?.toolName) return;
    collected.push({
      toolName: call.toolName,
      args: call.args ?? null,
      result: normalizeToolResult(call.result),
    });
  };

  if (Array.isArray(result?.toolCalls)) {
    result.toolCalls.forEach(pushCall);
  }

  if (Array.isArray(result?.steps)) {
    result.steps.forEach((step: any) => {
      if (Array.isArray(step?.toolCalls)) {
        step.toolCalls.forEach(pushCall);
      }
    });
  }

  return collected.length > 0 ? collected : undefined;
}

export class ChatLoggingMiddleware {
  private static generateThreadId(helperName: string, metadata: StreamMetadata): string {
    const { activeTabId = null, currentView, sessionId } = metadata;
    const timestamp = Date.now();
    const session = sessionId || `session_${timestamp}`;

    if (activeTabId) {
      return `${helperName}-node-${activeTabId}-${session}`;
    }
    return `${helperName}-general-${session}`;
  }

  private static extractUserMessage(messages: any[]): string | null {
    const userMessages = messages.filter(m => m.role === 'user');
    const lastUserMessage = userMessages[userMessages.length - 1];
    
    if (!lastUserMessage) return null;
    
    // Handle different message formats (AI SDK v5)
    if (typeof lastUserMessage.content === 'string') {
      return lastUserMessage.content;
    }
    
    // Handle parts-based messages (from frontend)
    if (Array.isArray(lastUserMessage.parts)) {
      const textParts = lastUserMessage.parts
        .filter((part: any) => part.type === 'text')
        .map((part: any) => part.text);
      return textParts.join(' ');
    }
    
    // Handle content as object or other formats
    if (lastUserMessage.content && typeof lastUserMessage.content === 'object') {
      return JSON.stringify(lastUserMessage.content);
    }
    
    return lastUserMessage.content || null;
  }

  static async logChatInteraction(
    userMessage: string,
    assistantMessage: string,
    metadata: StreamMetadata,
    messages: any[] = []
  ): Promise<void> {
    try {
      const threadId = this.generateThreadId(metadata.helperName, metadata);

      const createdAt = new Date().toISOString();

      const chatEntry: ChatLogEntry = {
        chat_type: 'helper',
        user_message: userMessage,
        assistant_message: assistantMessage,
        thread_id: threadId,
        focused_node_id: metadata.activeTabId ?? null,
        helper_name: metadata.helperName,
        agent_type: metadata.agentType || 'orchestrator',
        delegation_id: null,
        metadata: {
          timestamp: new Date().toISOString(),
          session_id: metadata.sessionId,
          current_view: metadata.currentView || 'nodes',
          open_tab_count: metadata.openTabs?.length || 0,
          has_focused_node: !!metadata.activeTabId,
          message_count: messages.length,
          // System message
          ...(metadata.systemMessage && { system_message: metadata.systemMessage }),
          // Enhanced usage data
          ...(metadata.usageData && {
            input_tokens: metadata.usageData.inputTokens,
            output_tokens: metadata.usageData.outputTokens,
            total_tokens: metadata.usageData.totalTokens,
            cache_write_tokens: metadata.usageData.cacheWriteTokens,
            cache_read_tokens: metadata.usageData.cacheReadTokens,
            cache_hit: metadata.usageData.cacheHit,
            cache_savings_pct: metadata.usageData.cacheSavingsPct,
            estimated_cost_usd: metadata.usageData.estimatedCostUsd,
            model_used: metadata.usageData.modelUsed,
            provider: metadata.usageData.provider,
            tools_used: metadata.usageData.toolsUsed,
            tool_calls_count: metadata.usageData.toolCallsCount,
            capsule_version: metadata.usageData.capsuleVersion,
            context_sources_used: metadata.usageData.contextSourcesUsed,
            validation_status: metadata.usageData.validationStatus,
            validation_message: metadata.usageData.validationMessage,
            fallback_action: metadata.usageData.fallbackAction,
          }),
          ...((metadata.toolCallsData && metadata.toolCallsData.length > 0) ? {
            tools_used: metadata.usageData?.toolsUsed ?? Array.from(new Set(
              metadata.toolCallsData
                .map((call: any) => call?.toolName)
                .filter((toolName: unknown): toolName is string => typeof toolName === 'string' && toolName.length > 0)
            )),
            tool_calls_count: metadata.usageData?.toolCallsCount ?? metadata.toolCallsData.length,
          } : {}),
          // Tool calls data
          ...(metadata.toolCallsData && metadata.toolCallsData.length > 0 && {
            tool_calls: metadata.toolCallsData
          }),
          // Trace grouping
          ...(metadata.traceId && { trace_id: metadata.traceId }),
          ...(metadata.parentChatId && { parent_chat_id: metadata.parentChatId }),
          // Backend usage (for Supabase sync correlation)
          ...(metadata.backendUsage && metadata.backendUsage.length > 0 && {
            backend_usage: metadata.backendUsage,
          }),
          ...(metadata.timingBreakdown && { timing_breakdown: metadata.timingBreakdown }),
          ...(metadata.toolTimingData && metadata.toolTimingData.length > 0 && {
            tool_timings: metadata.toolTimingData,
          }),
          ...(metadata.latencyMs !== undefined && { latency_ms: metadata.latencyMs }),
          ...(metadata.firstTokenLatencyMs !== undefined && { first_token_latency_ms: metadata.firstTokenLatencyMs }),
          ...(metadata.firstChunkLatencyMs !== undefined && { first_chunk_latency_ms: metadata.firstChunkLatencyMs }),
        }
      };

      const sqlite = getSQLiteClient();
      const result = sqlite.prepare(`
        INSERT INTO chats (chat_type, user_message, assistant_message, thread_id, focused_node_id, helper_name, agent_type, delegation_id, created_at, metadata) 
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `).run(
        chatEntry.chat_type,
        chatEntry.user_message,
        chatEntry.assistant_message,
        chatEntry.thread_id,
        chatEntry.focused_node_id,
        chatEntry.helper_name,
        chatEntry.agent_type,
        chatEntry.delegation_id,
        createdAt,
        JSON.stringify(chatEntry.metadata)
      );
      console.log(`✅ Chat logged for ${metadata.helperName}, ID: ${result.lastInsertRowid}`);

      const lastInsertedChatId = Number(result.lastInsertRowid);

      if (metadata.agentType === 'orchestrator' && metadata.helperName === 'ra-h') {
        RequestContext.set({ 
          traceId: metadata.traceId, 
          parentChatId: lastInsertedChatId 
        });
      }

    } catch (error) {
      console.error('❌ Chat logging error:', error);
    }
  }

  static createLoggingHandlers(metadata: StreamMetadata, messages: any[]) {
    let assistantResponse = '';
    const userMessage = this.extractUserMessage(messages);
    const startedAt = metadata.requestStartedAt ?? Date.now();
    const streamStartedAt = Date.now();
    const streamSetupMs = Math.max(0, streamStartedAt - startedAt);
    let firstTextDeltaAt: number | null = null;
    let firstChunkAt: number | null = null;

    return {
      onFinish: async (result: any) => {
        const { text, toolCalls, steps } = result;
        // Log if we have a user message and either text OR tool activity
        const hasActivity = Boolean(text || toolCalls?.length > 0 || steps?.length > 0);
        
        if (userMessage && hasActivity) {
          // Capture tool calls if present
          const toolCallsData = collectToolCalls(result);
          
          if (toolCallsData) {
            console.log(`🔧 Captured ${toolCallsData.length} tool calls for logging`);
          }
          
          const enhancedMetadata = { 
            ...metadata,
            toolCallsData,
            timingBreakdown: {
              ...metadata.timingBreakdown,
              streamSetupMs,
            },
            latencyMs: Date.now() - startedAt,
            firstChunkLatencyMs: firstChunkAt ? firstChunkAt - startedAt : null,
            firstTokenLatencyMs: firstTextDeltaAt
              ? firstTextDeltaAt - startedAt
              : (firstChunkAt ? firstChunkAt - startedAt : null),
          };
          
          await this.logChatInteraction(
            userMessage,
            text || '[Tool calls only - no text response]',
            enhancedMetadata,
            messages
          );
        } else if (userMessage && !hasActivity) {
          console.warn(`⚠️ Skipping chat log - no text or tool activity for user message: ${userMessage.substring(0, 50)}...`);
        }

        const evalContext = RequestContext.get();
        if (userMessage) {
          const toolCallsData = collectToolCalls(result);
          const timingBreakdown = {
            ...metadata.timingBreakdown,
            streamSetupMs,
          };
          const evalMetadata = {
            ...metadata,
            toolCallsData,
            timingBreakdown,
          };
          logEvalChat({
            traceId: evalMetadata.traceId,
            spanId: evalContext.evalChatSpanId,
            helperName: evalMetadata.helperName,
            model: evalMetadata.modelUsed || evalMetadata.usageData?.modelUsed,
            promptVersion: evalMetadata.promptVersion,
            systemMessage: evalMetadata.systemMessage || null,
            userMessage,
            assistantMessage: text || assistantResponse || null,
            inputTokens: evalMetadata.usageData?.inputTokens,
            outputTokens: evalMetadata.usageData?.outputTokens,
            totalTokens: evalMetadata.usageData?.totalTokens,
            cacheWriteTokens: evalMetadata.usageData?.cacheWriteTokens,
            cacheReadTokens: evalMetadata.usageData?.cacheReadTokens,
            cacheHit: evalMetadata.usageData?.cacheHit,
            cacheSavingsPct: evalMetadata.usageData?.cacheSavingsPct,
            estimatedCostUsd: evalMetadata.usageData?.estimatedCostUsd,
            provider: evalMetadata.usageData?.provider ?? null,
            workflowKey: evalMetadata.workflowKey ?? null,
            workflowNodeId: evalMetadata.workflowNodeId ?? null,
            latencyMs: Date.now() - startedAt,
            firstChunkLatencyMs: firstChunkAt ? firstChunkAt - startedAt : null,
            firstTokenLatencyMs: firstTextDeltaAt
              ? firstTextDeltaAt - startedAt
              : (firstChunkAt ? firstChunkAt - startedAt : null),
            promptBuildMs: timingBreakdown?.promptBuildMs ?? null,
            toolsBuildMs: timingBreakdown?.toolsBuildMs ?? null,
            modelResolveMs: timingBreakdown?.modelResolveMs ?? null,
            messageAssemblyMs: timingBreakdown?.messageAssemblyMs ?? null,
            streamSetupMs,
            toolLoopMs: timingBreakdown?.toolLoopMs ?? null,
            toolsUsed: evalMetadata.usageData?.toolsUsed ?? (
              evalMetadata.toolCallsData
                ? Array.from(new Set(
                    evalMetadata.toolCallsData
                      .map((call: any) => call?.toolName)
                      .filter((toolName: unknown): toolName is string => typeof toolName === 'string' && toolName.length > 0)
                  ))
                : null
            ),
            toolCallsCount: evalMetadata.usageData?.toolCallsCount ?? evalMetadata.toolCallsData?.length ?? null,
            success: hasActivity,
            error: null,
          });
        }
      },
      onChunk: ({ chunk }: { chunk: any }) => {
        if (firstChunkAt === null) {
          firstChunkAt = Date.now();
        }
        if (chunk.type === 'text-delta' && chunk.textDelta) {
          if (firstTextDeltaAt === null) {
            firstTextDeltaAt = Date.now();
          }
          assistantResponse += chunk.textDelta;
        }
      }
    };
  }
}

export function withChatLogging(
  streamConfig: any,
  metadata: StreamMetadata,
  messages: any[]
) {
  const handlers = ChatLoggingMiddleware.createLoggingHandlers(metadata, messages);
  const originalOnFinish = streamConfig.onFinish;
  
  return {
    ...streamConfig,
    onFinish: async (result: any) => {
      // Call original onFinish first (for cache stats)
      if (originalOnFinish) {
        await originalOnFinish(result);
      }
      // Then call logging handler
      await handlers.onFinish(result);
    },
    onChunk: handlers.onChunk
  };
}
