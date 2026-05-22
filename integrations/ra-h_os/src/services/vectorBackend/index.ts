import type { Chunk } from '@/types/database';

export type VectorBackendType = 'sqlite-vec' | 'qdrant';

export interface RankedChunk extends Chunk {
  similarity: number;
}

export interface RankedNode {
  nodeId: number;
  score: number;
}

export interface VectorBackendHealth {
  ok: boolean;
  backend: VectorBackendType;
  detail?: string;
  dimensions?: number;
}

export interface VectorBackend {
  upsertChunk(chunkId: number, nodeId: number, chunkIndex: number, text: string, embedding: number[]): Promise<void>;
  upsertNode(nodeId: number, text: string, embedding: number[]): Promise<void>;
  searchChunks(
    queryEmbedding: number[],
    similarityThreshold: number,
    limit: number,
    nodeIds?: number[]
  ): Promise<RankedChunk[]>;
  searchNodes(queryEmbedding: number[], limit: number): Promise<RankedNode[]>;
  deleteChunksByNode(nodeId: number): Promise<void>;
  deleteNode(nodeId: number): Promise<void>;
  healthCheck(): Promise<VectorBackendHealth>;
}

export function getVectorBackendType(): VectorBackendType {
  return process.env.VECTOR_BACKEND === 'qdrant' ? 'qdrant' : 'sqlite-vec';
}
