import { NextResponse } from 'next/server';
import { getSQLiteClient } from '@/services/database/sqlite-client';
import { chunkService } from '@/services/database/chunks';
import { createEmbeddingProvider } from '@/services/embedding/provider';
import { createUtilityLlmProvider } from '@/services/llm/provider';
import { getVectorBackend } from '@/services/vectorBackend/factory';
import { getVectorBackendType } from '@/services/vectorBackend';

interface ChunkStats {
  total_chunks: number;
  vectorized_chunks: number | null;
  missing_embeddings: number | null;
  coverage_percentage: number | null;
}

interface VectorStats {
  vec_chunks_count?: number;
  matches_chunk_embeddings?: boolean;
  extension_loaded?: boolean;
  reason?: string;
  error?: string;
  suggestion?: string;
  backend?: string;
  status?: unknown;
}

function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}

export async function GET() {
  try {
    const sqlite = getSQLiteClient();
    // Test basic database connection
    const connectionTest = await sqlite.testConnection();
    if (!connectionTest) {
      return NextResponse.json({
        status: 'error',
        message: 'Database connection failed',
        details: null
      });
    }

    const vectorBackend = await getVectorBackend();
    const vectorBackendHealth = await vectorBackend.healthCheck();
    const embeddingInfo = createEmbeddingProvider().info();
    const utilityInfo = createUtilityLlmProvider().info();
    const profileStatus = sqlite.getEmbeddingProfileStatus();

    // Check if vector extension is loaded
    const vectorExtensionTest = await sqlite.checkVectorExtension();
    let vectorStats: VectorStats | null = null;
    let chunkStats: ChunkStats | null = null;
    let vectorHealth = vectorExtensionTest ? 'healthy' : 'unavailable';

    try {
      const totalChunks = await chunkService.getChunkCount();
      chunkStats = {
        total_chunks: totalChunks,
        vectorized_chunks: null,
        missing_embeddings: null,
        coverage_percentage: null,
      };

      if (getVectorBackendType() === 'qdrant') {
        vectorHealth = vectorBackendHealth.ok ? 'healthy' : 'unavailable';
        vectorStats = {
          backend: 'qdrant',
          status: vectorBackendHealth,
          matches_chunk_embeddings: !profileStatus.rebuild_required,
        };
      } else if (vectorExtensionTest) {
        try {
          const chunksWithoutEmbeddings = await chunkService.getChunksWithoutEmbeddings();
          const vectorizedCount = totalChunks - chunksWithoutEmbeddings.length;
          const result = sqlite.query('SELECT COUNT(*) as count FROM vec_chunks');
          const vecCount = Number(result.rows[0].count);

          chunkStats = {
            total_chunks: totalChunks,
            vectorized_chunks: vectorizedCount,
            missing_embeddings: chunksWithoutEmbeddings.length,
            coverage_percentage: totalChunks > 0 ? Math.round((vectorizedCount / totalChunks) * 100) : 0
          };

          vectorStats = {
            vec_chunks_count: vecCount,
            matches_chunk_embeddings: vecCount === vectorizedCount
          };
          
          vectorHealth = vecCount === vectorizedCount ? 'healthy' : 'inconsistent';
        } catch (vecError: unknown) {
          vectorHealth = 'corrupted';
          vectorStats = {
            error: errorMessage(vecError),
            suggestion: 'Vector table may be corrupted and need recreation'
          };
        }
      } else {
        vectorHealth = 'unavailable';
        vectorStats = {
          extension_loaded: false,
          reason: 'Vector extension unavailable in this environment.',
        };
      }

    } catch (error: unknown) {
      return NextResponse.json({
        status: 'error',
        message: 'Failed to collect vector statistics',
        details: errorMessage(error)
      });
    }

    return NextResponse.json({
      status: 'success',
      data: {
        database_connected: connectionTest,
        vector_extension_loaded: vectorExtensionTest,
        vector_capability: {
          available: vectorBackendHealth.ok,
          backend: getVectorBackendType(),
          detail: vectorBackendHealth.detail,
          dimensions: vectorBackendHealth.dimensions,
        },
        utility_llm: utilityInfo,
        embedding_provider: embeddingInfo,
        embedding_profile: profileStatus,
        vector_health: vectorHealth,
        chunk_stats: chunkStats,
        vector_stats: vectorStats,
        recommendations: generateRecommendations(vectorHealth, chunkStats, vectorStats, profileStatus)
      }
    });

  } catch (error: unknown) {
    console.error('Vector health check failed:', error);
    return NextResponse.json({
      status: 'error',
      message: 'Health check failed',
      details: errorMessage(error)
    });
  }
}

function generateRecommendations(
  vectorHealth: string, 
  chunkStats: ChunkStats | null,
  vectorStats: VectorStats | null,
  profileStatus?: { rebuild_required?: boolean; reason?: string }
): string[] {
  const recommendations: string[] = [];

  if (vectorHealth === 'corrupted') {
    recommendations.push('Vector tables are corrupted - restart the application to trigger automatic healing');
  }

  if (vectorHealth === 'unavailable') {
    recommendations.push('Semantic/vector search is unavailable. Install sqlite-vec for your platform or switch to Qdrant.');
  }

  if (chunkStats && typeof chunkStats.coverage_percentage === 'number' && chunkStats.coverage_percentage < 95) {
    recommendations.push(`${chunkStats.missing_embeddings} chunks missing embeddings - consider running embedding generation`);
  }

  if (vectorStats && !vectorStats.matches_chunk_embeddings) {
    recommendations.push('Vector count does not match chunk embeddings - database inconsistency detected');
  }

  if (profileStatus?.rebuild_required) {
    recommendations.push(profileStatus.reason || 'Embedding profile changed - rebuild embeddings before semantic search');
  }

  if (recommendations.length === 0) {
    recommendations.push('Vector search system is healthy');
  }

  return recommendations;
}
