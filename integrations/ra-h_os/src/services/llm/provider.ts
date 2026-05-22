import { generateText } from 'ai';
import { createOpenAI } from '@ai-sdk/openai';
import { getPreferredOpenAiKey } from '@/services/storage/openaiKeyServer';

export type UtilityLlmProfile = 'openai' | 'openai-compatible' | 'custom';

export interface UtilityLlmRequest {
  prompt: string;
  maxOutputTokens?: number;
  temperature?: number;
  responseFormat?: 'text' | 'json';
  task:
    | 'description'
    | 'edge_inference'
    | 'extraction_analysis'
    | 'transcript_summary'
    | 'embedding_prep_analysis';
}

export interface UtilityLlmProviderInfo {
  profile: UtilityLlmProfile;
  model: string;
  baseUrl?: string;
}

export interface UtilityLlmHealth {
  ok: boolean;
  profile: UtilityLlmProfile;
  model: string;
  detail?: string;
}

export interface UtilityLlmProvider {
  info(): UtilityLlmProviderInfo;
  generateText(input: UtilityLlmRequest): Promise<string>;
  healthCheck(): Promise<UtilityLlmHealth>;
}

const DEFAULT_OPENAI_LLM_MODEL = 'gpt-4o-mini';

function normalizeProfile(raw: string | undefined): UtilityLlmProfile {
  if (raw === 'openai-compatible' || raw === 'custom') return raw;
  return 'openai';
}

export function getUtilityLlmProviderInfo(): UtilityLlmProviderInfo {
  const profile = normalizeProfile(process.env.LLM_PROFILE);
  if (profile === 'openai') {
    return {
      profile,
      model: process.env.LLM_MODEL || DEFAULT_OPENAI_LLM_MODEL,
    };
  }

  if (!process.env.LLM_MODEL) {
    throw new Error('LLM_MODEL is required when LLM_PROFILE=openai-compatible.');
  }
  if (!process.env.LLM_BASE_URL) {
    throw new Error('LLM_BASE_URL is required when LLM_PROFILE=openai-compatible.');
  }

  return {
    profile,
    model: process.env.LLM_MODEL,
    baseUrl: process.env.LLM_BASE_URL,
  };
}

function createProvider(info: UtilityLlmProviderInfo): ReturnType<typeof createOpenAI> {
  if (info.profile === 'openai') {
    const apiKey = getPreferredOpenAiKey();
    if (!apiKey) {
      throw new Error('OpenAI API key not configured. Add your key in Settings or .env.local.');
    }
    return createOpenAI({ apiKey });
  }

  return createOpenAI({
    apiKey: process.env.LLM_API_KEY || process.env.OPENAI_COMPATIBLE_API_KEY || 'local',
    baseURL: info.baseUrl,
  });
}

export function createUtilityLlmProvider(): UtilityLlmProvider {
  const info = getUtilityLlmProviderInfo();

  return {
    info: () => info,
    async generateText(input: UtilityLlmRequest): Promise<string> {
      const provider = createProvider(info);
      const response = await generateText({
        model: provider(info.model),
        prompt: input.prompt,
        maxOutputTokens: input.maxOutputTokens,
        temperature: input.temperature,
      });
      return response.text;
    },
    async healthCheck(): Promise<UtilityLlmHealth> {
      try {
        await this.generateText({
          prompt: 'Reply with exactly: ok',
          maxOutputTokens: 8,
          temperature: 0,
          task: 'description',
        });
        return {
          ok: true,
          profile: info.profile,
          model: info.model,
          detail: info.baseUrl ? `Connected to ${info.baseUrl}` : 'OpenAI utility LLM ready',
        };
      } catch (error) {
        return {
          ok: false,
          profile: info.profile,
          model: info.model,
          detail: error instanceof Error ? error.message : String(error),
        };
      }
    },
  };
}

export async function generateUtilityText(input: UtilityLlmRequest): Promise<string> {
  return createUtilityLlmProvider().generateText(input);
}
