/**
 * Memory Extraction — LLM-based auto-extraction of memorable information.
 *
 * After each conversation turn, optionally asks the LLM to analyze the exchange
 * and extract information worth remembering across conversations.
 *
 * Categories (Claude Code-inspired):
 * - user:      User preferences, role, knowledge level
 * - feedback:  Corrections and confirmations ("don't do X", "yes, keep doing Y")
 * - project:   Ongoing work context, goals, decisions
 * - reference: Pointers to external resources, tools, URLs
 */

import type { MemoryType } from '../types/agent-mode'

export interface ExtractedMemory {
  type: MemoryType
  title: string
  description: string
  content: string
  tags: string[]
}

export interface ExtractionResult {
  shouldSave: boolean
  memories: ExtractedMemory[]
}

/**
 * Build the prompt that instructs the LLM to analyze a conversation exchange
 * and decide what (if anything) should be remembered.
 */
export function buildExtractionPrompt(
  userMessage: string,
  assistantResponse: string,
  existingMemoriesSummary: string
): Array<{ role: 'system' | 'user'; content: string }> {
  const systemPrompt = `You are a memory extraction system. Analyze the conversation exchange below and decide if anything should be remembered for future conversations.

## Memory Types
- **user**: User preferences, role, expertise, knowledge level, how they like to work
- **feedback**: Corrections ("don't do X") or confirmations ("yes, keep doing Y")
- **project**: Ongoing work context, goals, decisions, deadlines
- **reference**: External resources, tools, URLs, documentation pointers

## Rules
- Only extract genuinely useful cross-conversation information
- Do NOT save: trivial greetings, one-off questions, code snippets, debugging sessions
- Do NOT duplicate existing memories (listed below)
- Keep titles under 60 characters, descriptions under 120 characters
- Content should be concise but complete (1-3 sentences)

## Existing Memories
${existingMemoriesSummary || 'None yet.'}

## Response Format
Respond with ONLY valid JSON (no markdown, no explanation):
{"shouldSave": true/false, "memories": [{"type": "user|feedback|project|reference", "title": "...", "description": "...", "content": "...", "tags": ["..."]}]}`

  const userPrompt = `## User said:
${userMessage.substring(0, 500)}

## Assistant replied:
${assistantResponse.substring(0, 500)}

Analyze this exchange. What (if anything) should be remembered?`

  return [
    { role: 'system', content: systemPrompt },
    { role: 'user', content: userPrompt },
  ]
}

/**
 * Parse the LLM's extraction response. Handles models that wrap JSON in
 * markdown code blocks or add preamble text.
 */
export function parseExtractionResponse(response: string): ExtractionResult {
  const fallback: ExtractionResult = { shouldSave: false, memories: [] }

  try {
    // Try to extract JSON from the response
    let jsonStr = response.trim()

    // Strip markdown code blocks
    const codeBlockMatch = jsonStr.match(/```(?:json)?\s*([\s\S]*?)```/)
    if (codeBlockMatch) {
      jsonStr = codeBlockMatch[1].trim()
    }

    // Try to find JSON object in the response
    const jsonMatch = jsonStr.match(/\{[\s\S]*\}/)
    if (!jsonMatch) return fallback

    const data = JSON.parse(jsonMatch[0])

    if (typeof data.shouldSave !== 'boolean') return fallback
    if (!data.shouldSave) return { shouldSave: false, memories: [] }
    if (!Array.isArray(data.memories)) return fallback

    // Validate each memory
    const validTypes: MemoryType[] = ['user', 'feedback', 'project', 'reference']
    const memories: ExtractedMemory[] = data.memories
      .filter((m: any) =>
        m &&
        validTypes.includes(m.type) &&
        typeof m.title === 'string' && m.title.length > 0 &&
        typeof m.content === 'string' && m.content.length > 0
      )
      .map((m: any) => ({
        type: m.type as MemoryType,
        title: m.title.substring(0, 60),
        description: (m.description || m.content.substring(0, 120)).substring(0, 120),
        content: m.content,
        tags: Array.isArray(m.tags) ? m.tags.filter((t: any) => typeof t === 'string') : [],
      }))

    return { shouldSave: memories.length > 0, memories }
  } catch {
    return fallback
  }
}
