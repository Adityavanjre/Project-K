import OpenAI from 'openai';
import { getPreferredOpenAiKey } from '@/services/storage/openaiKeyServer';

export type EmbeddingProfile = 'openai' | 'openai-compatible' | 'custom';

export interface EmbeddingProviderInfo {
  profile: EmbeddingProfile;
  model: string;
  dimensions: number;
  baseUrl?: string;
}

export interface EmbeddingHealth {
  ok: boolean;
  profile: EmbeddingProfile;
  model: string;
  dimensions: number;
  detail?: string;
}

export interface EmbeddingProvider {
  info(): EmbeddingProviderInfo;
  generateEmbedding(text: string): Promise<number[]>;
  healthCheck(): Promise<EmbeddingHealth>;
}

const DEFAULT_OPENAI_EMBEDDING_MODEL = 'text-embedding-3-small';
const DEFAULT_OPENAI_EMBEDDING_DIMENSIONS = 1536;
const DEFAULT_LOCAL_EMBEDDING_DIMENSIONS = 1024;

function normalizeProfile(raw: string | undefined): EmbeddingProfile {
  if (raw === 'openai-compatible' || raw === 'custom') return raw;
  return 'openai';
}

function parseDimensions(raw: string | undefined, fallback: number): number {
  if (!raw) return fallback;
  const parsed = Number(raw);
  if (!Number.isInteger(parsed) || parsed <= 0) {
    throw new Error(`Invalid EMBEDDING_DIMENSIONS="${raw}". Use a positive integer.`);
  }
  return parsed;
}

export function getEmbeddingProviderInfo(): EmbeddingProviderInfo {
  const profile = normalizeProfile(process.env.EMBEDDING_PROFILE);
  if (profile === 'openai') {
    return {
      profile,
      model: process.env.EMBEDDING_MODEL || DEFAULT_OPENAI_EMBEDDING_MODEL,
      dimensions: parseDimensions(process.env.EMBEDDING_DIMENSIONS, DEFAULT_OPENAI_EMBEDDING_DIMENSIONS),
    };
  }

  const model = process.env.EMBEDDING_MODEL;
  const baseUrl = process.env.EMBEDDING_BASE_URL || process.env.LLM_BASE_URL;

  if (!model) {
    throw new Error('EMBEDDING_MODEL is required when EMBEDDING_PROFILE=openai-compatible.');
  }
  if (!baseUrl) {
    throw new Error('EMBEDDING_BASE_URL is required when EMBEDDING_PROFILE=openai-compatible.');
  }

  return {
    profile,
    model,
    dimensions: parseDimensions(process.env.EMBEDDING_DIMENSIONS, DEFAULT_LOCAL_EMBEDDING_DIMENSIONS),
    baseUrl,
  };
}

function createOpenAiClient(info: EmbeddingProviderInfo): OpenAI {
  if (info.profile === 'openai') {
    const apiKey = getPreferredOpenAiKey();
    if (!apiKey) {
      throw new Error('OpenAI API key not configured. Add OPENAI_API_KEY to your .env.local file.');
    }
    return new OpenAI({ apiKey });
  }

  return new OpenAI({
    apiKey: process.env.EMBEDDING_API_KEY || process.env.OPENAI_COMPATIBLE_API_KEY || 'local',
    baseURL: info.baseUrl,
  });
}

export function validateEmbeddingDimensions(embedding: number[], expectedDimensions = getEmbeddingProviderInfo().dimensions): boolean {
  return Array.isArray(embedding) && embedding.length === expectedDimensions;
}

export function createEmbeddingProvider(): EmbeddingProvider {
  const info = getEmbeddingProviderInfo();

  return {
    info: () => info,
    async generateEmbedding(text: string): Promise<number[]> {
      const client = createOpenAiClient(info);
      const response = await client.embeddings.create({
        model: info.model,
        input: text.trim(),
        encoding_format: 'float',
        dimensions: info.dimensions,
      });

      const embedding = response.data?.[0]?.embedding;
      if (!embedding) {
        throw new Error(`No embedding returned from ${info.profile} provider.`);
      }
      if (!validateEmbeddingDimensions(embedding, info.dimensions)) {
        throw new Error(
          `Embedding dimension mismatch: expected ${info.dimensions}, got ${embedding.length}. ` +
          'Run the local AI doctor and rebuild embeddings after changing providers.'
        );
      }
      return embedding;
    },
    async healthCheck(): Promise<EmbeddingHealth> {
      try {
        const embedding = await this.generateEmbedding('RA-H embedding health check');
        return {
          ok: true,
          profile: info.profile,
          model: info.model,
          dimensions: embedding.length,
          detail: info.baseUrl ? `Connected to ${info.baseUrl}` : 'OpenAI embedding provider ready',
        };
      } catch (error) {
        return {
          ok: false,
          profile: info.profile,
          model: info.model,
          dimensions: info.dimensions,
          detail: error instanceof Error ? error.message : String(error),
        };
      }
    },
  };
}
