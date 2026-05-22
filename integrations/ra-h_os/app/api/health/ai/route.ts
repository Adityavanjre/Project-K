import { NextResponse } from 'next/server';
import { getSQLiteClient } from '@/services/database/sqlite-client';
import { createEmbeddingProvider } from '@/services/embedding/provider';
import { createUtilityLlmProvider } from '@/services/llm/provider';
import { getVectorBackend } from '@/services/vectorBackend/factory';

export async function GET() {
  try {
    const sqlite = getSQLiteClient();
    const utility = createUtilityLlmProvider();
    const embedding = createEmbeddingProvider();
    const vectorBackend = await getVectorBackend();

    const [utilityHealth, embeddingHealth, vectorHealth] = await Promise.all([
      utility.healthCheck(),
      embedding.healthCheck(),
      vectorBackend.healthCheck(),
    ]);

    return NextResponse.json({
      status: utilityHealth.ok && embeddingHealth.ok && vectorHealth.ok ? 'success' : 'degraded',
      data: {
        utility_llm: utilityHealth,
        embedding_provider: embeddingHealth,
        vector_backend: vectorHealth,
        embedding_profile: sqlite.getEmbeddingProfileStatus(),
      },
    });
  } catch (error) {
    return NextResponse.json({
      status: 'error',
      message: 'AI health check failed',
      details: error instanceof Error ? error.message : String(error),
    }, { status: 500 });
  }
}
