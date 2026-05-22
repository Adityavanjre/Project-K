import { nodeService } from '@/services/database';
import { getSQLiteClient } from '@/services/database/sqlite-client';
import { NodeEmbedder } from '@/services/typescript/embed-nodes';
import { UniversalEmbedder } from '@/services/typescript/embed-universal';
import type { Node } from '@/types/database';

export interface EmbeddingStageStatus {
  status: 'pending' | 'completed' | 'failed' | 'skipped';
  message: string;
  chunks_created?: number;
}

export interface EmbeddingPipelineResult {
  success: boolean;
  error?: string;
  node_embedding: EmbeddingStageStatus;
  chunk_embeddings: EmbeddingStageStatus;
  overall_status: 'pending' | 'fully_embedded' | 'partially_embedded' | 'no_content' | 'failed';
}

interface EmbeddingResult {
  success: boolean;
  error?: string;
  output?: string;
}

async function runNodeEmbedding(nodeId: number): Promise<EmbeddingResult> {
  const embedder = new NodeEmbedder();
  try {
    const result = await embedder.embedNodes({ nodeId });
    if (result.processed > 0) {
      return { success: true, output: `Embedded ${result.processed} nodes` };
    }
    if (result.failed > 0) {
      return { success: false, error: 'Failed to embed node' };
    }
    return { success: true, output: 'Node already has embedding' };
  } catch (error) {
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Embedding failed'
    };
  } finally {
    embedder.close();
  }
}

async function updateChunkStatus(nodeId: number, status: Node['chunk_status']) {
  try {
    await nodeService.updateNode(nodeId, { chunk_status: status });
  } catch (error) {
    console.warn('Failed to update chunk_status for node', nodeId, status, error);
  }
}

async function runChunkEmbedding(nodeId: number): Promise<EmbeddingResult> {
  const sqlite = getSQLiteClient();
  const integrity = sqlite.getIntegrityReport();
  if (!sqlite.canUseFtsTable('chunks')) {
    await updateChunkStatus(nodeId, 'error');
    return {
      success: false,
      error: `Chunk indexing is disabled while the chunks FTS surface is degraded. ${integrity.summary}`
    };
  }

  const embedder = new UniversalEmbedder();
  try {
    await updateChunkStatus(nodeId, 'chunking');
    const result = await embedder.processNode({ nodeId });
    return {
      success: true,
      output: `Stored ${result.chunks} chunks`
    };
  } catch (error) {
    await updateChunkStatus(nodeId, 'error');
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Chunking failed'
    };
  } finally {
    embedder.close();
  }
}

export async function embedNodeContent(nodeId: number): Promise<EmbeddingPipelineResult> {
  const node = await nodeService.getNodeById(nodeId);
  if (!node) {
    return {
      success: false,
      error: 'Node not found',
      node_embedding: { status: 'failed', message: 'Node not found' },
      chunk_embeddings: { status: 'failed', message: 'Node not found' },
      overall_status: 'failed'
    };
  }

  const results = {
    node_embedding: { status: 'pending', message: '' } as EmbeddingStageStatus,
    chunk_embeddings: { status: 'pending', message: '', chunks_created: 0 } as EmbeddingStageStatus,
    overall_status: 'pending' as EmbeddingPipelineResult['overall_status']
  };

  const nodeResult = await runNodeEmbedding(nodeId);
  if (nodeResult.success) {
    results.node_embedding = {
      status: 'completed',
      message: nodeResult.output || 'Node metadata embedded successfully'
    };
  } else {
    results.node_embedding = {
      status: 'failed',
      message: nodeResult.error || 'Failed to embed node metadata'
    };
  }

  if (!node.source || !node.source.trim()) {
    results.chunk_embeddings = {
      status: 'skipped',
      message: 'No source content to embed',
      chunks_created: 0
    };
  } else {
    const chunkResult = await runChunkEmbedding(nodeId);
    if (chunkResult.success) {
      const chunkMatch = chunkResult.output?.match(/Stored (\d+) chunks/);
      const chunksCreated = chunkMatch ? parseInt(chunkMatch[1], 10) : 0;
      results.chunk_embeddings = {
        status: 'completed',
        message: chunkResult.output || 'Chunk content embedded successfully',
        chunks_created: chunksCreated
      };
    } else {
      results.chunk_embeddings = {
        status: 'failed',
        message: chunkResult.error || 'Failed to embed chunk content'
      };
    }
  }

  const nodeSuccess = results.node_embedding.status === 'completed';
  const chunkSuccess = results.chunk_embeddings.status === 'completed';
  const chunkSkipped = results.chunk_embeddings.status === 'skipped';

  if (nodeSuccess && (chunkSuccess || chunkSkipped)) {
    results.overall_status = chunkSkipped ? 'no_content' : 'fully_embedded';
    if (chunkSuccess) {
      await updateChunkStatus(nodeId, 'chunked');
    }
  } else if (nodeSuccess || chunkSuccess) {
    results.overall_status = 'partially_embedded';
  } else {
    results.overall_status = 'failed';
  }

  const errorParts: string[] = [];
  if (results.node_embedding.status === 'failed') {
    errorParts.push(`node: ${results.node_embedding.message}`);
  }
  if (results.chunk_embeddings.status === 'failed') {
    errorParts.push(`chunks: ${results.chunk_embeddings.message}`);
  }

  return {
    success: results.overall_status !== 'failed',
    error: errorParts.length ? errorParts.join('; ') : undefined,
    ...results
  };
}
