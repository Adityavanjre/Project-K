import { getEmbeddingProviderInfo } from '@/services/embedding/provider';
import type { RankedChunk, RankedNode, VectorBackend, VectorBackendHealth } from './index';

interface QdrantPoint {
  id: number;
  score?: number;
  payload?: Record<string, unknown>;
}

function qdrantUrl(path: string): string {
  const base = (process.env.QDRANT_URL || 'http://localhost:6333').replace(/\/+$/, '');
  return `${base}${path}`;
}

function getApiKeyHeader(): Record<string, string> {
  return process.env.QDRANT_API_KEY ? { 'api-key': process.env.QDRANT_API_KEY } : {};
}

async function qdrantFetch<T>(path: string, init?: RequestInit): Promise<T> {
  const response = await fetch(qdrantUrl(path), {
    ...init,
    headers: {
      'Content-Type': 'application/json',
      ...getApiKeyHeader(),
      ...(init?.headers || {}),
    },
  });

  if (!response.ok) {
    const detail = await response.text().catch(() => response.statusText);
    throw new Error(`Qdrant ${response.status} ${response.statusText}: ${detail}`);
  }

  return response.json() as Promise<T>;
}

function payloadNumber(payload: Record<string, unknown> | undefined, key: string, fallback: number): number {
  const value = payload?.[key];
  return typeof value === 'number' ? value : fallback;
}

function payloadString(payload: Record<string, unknown> | undefined, key: string): string {
  const value = payload?.[key];
  return typeof value === 'string' ? value : '';
}

export class QdrantBackend implements VectorBackend {
  private readonly chunksCollection = process.env.QDRANT_CHUNKS_COLLECTION || 'rah_chunks';
  private readonly nodesCollection = process.env.QDRANT_NODES_COLLECTION || 'rah_nodes';
  private readonly dimensions = getEmbeddingProviderInfo().dimensions;
  private ensured = new Set<string>();

  private async ensureCollection(name: string): Promise<void> {
    if (this.ensured.has(name)) return;

    const existing = await fetch(qdrantUrl(`/collections/${encodeURIComponent(name)}`), {
      headers: getApiKeyHeader(),
    });

    if (existing.status === 404) {
      await qdrantFetch(`/collections/${encodeURIComponent(name)}`, {
        method: 'PUT',
        body: JSON.stringify({
          vectors: {
            size: this.dimensions,
            distance: 'Cosine',
          },
        }),
      });
      this.ensured.add(name);
      return;
    }

    if (!existing.ok) {
      const detail = await existing.text().catch(() => existing.statusText);
      throw new Error(`Qdrant ${existing.status} ${existing.statusText}: ${detail}`);
    }

    const data = await existing.json() as {
      result?: { config?: { params?: { vectors?: { size?: number } | Record<string, { size?: number }> } } };
    };
    const vectors = data.result?.config?.params?.vectors;
    const size = typeof vectors?.size === 'number'
      ? vectors.size
      : vectors && typeof vectors === 'object'
        ? Object.values(vectors).find((value) => typeof value?.size === 'number')?.size
        : undefined;

    if (typeof size === 'number' && size !== this.dimensions) {
      throw new Error(
        `Qdrant collection ${name} has ${size} dimensions, but active embedding profile requires ${this.dimensions}. ` +
        'Run the embedding rebuild script after changing embedding providers.'
      );
    }

    this.ensured.add(name);
  }

  async upsertChunk(chunkId: number, nodeId: number, chunkIndex: number, text: string, embedding: number[]): Promise<void> {
    await this.ensureCollection(this.chunksCollection);
    await qdrantFetch(`/collections/${encodeURIComponent(this.chunksCollection)}/points?wait=true`, {
      method: 'PUT',
      body: JSON.stringify({
        points: [{
          id: chunkId,
          vector: embedding,
          payload: { chunkId, nodeId, chunkIndex, text },
        }],
      }),
    });
  }

  async upsertNode(nodeId: number, text: string, embedding: number[]): Promise<void> {
    await this.ensureCollection(this.nodesCollection);
    await qdrantFetch(`/collections/${encodeURIComponent(this.nodesCollection)}/points?wait=true`, {
      method: 'PUT',
      body: JSON.stringify({
        points: [{
          id: nodeId,
          vector: embedding,
          payload: { nodeId, text },
        }],
      }),
    });
  }

  async searchChunks(
    queryEmbedding: number[],
    similarityThreshold: number,
    limit: number,
    nodeIds?: number[]
  ): Promise<RankedChunk[]> {
    await this.ensureCollection(this.chunksCollection);
    const filter = nodeIds && nodeIds.length > 0
      ? {
          must: [{
            key: 'nodeId',
            match: { any: nodeIds },
          }],
        }
      : undefined;

    const response = await qdrantFetch<{ result: QdrantPoint[] }>(
      `/collections/${encodeURIComponent(this.chunksCollection)}/points/search`,
      {
        method: 'POST',
        body: JSON.stringify({
          vector: queryEmbedding,
          limit,
          score_threshold: similarityThreshold,
          with_payload: true,
          filter,
        }),
      }
    );

    return response.result.map((point) => {
      const payload = point.payload;
      return {
        id: payloadNumber(payload, 'chunkId', Number(point.id)),
        node_id: payloadNumber(payload, 'nodeId', 0),
        chunk_idx: payloadNumber(payload, 'chunkIndex', 0),
        text: payloadString(payload, 'text'),
        embedding_type: getEmbeddingProviderInfo().model,
        created_at: '',
        similarity: Number(point.score ?? 0),
      };
    });
  }

  async searchNodes(queryEmbedding: number[], limit: number): Promise<RankedNode[]> {
    await this.ensureCollection(this.nodesCollection);
    const response = await qdrantFetch<{ result: QdrantPoint[] }>(
      `/collections/${encodeURIComponent(this.nodesCollection)}/points/search`,
      {
        method: 'POST',
        body: JSON.stringify({
          vector: queryEmbedding,
          limit,
          with_payload: true,
        }),
      }
    );

    return response.result.map((point) => ({
      nodeId: payloadNumber(point.payload, 'nodeId', Number(point.id)),
      score: Number(point.score ?? 0),
    }));
  }

  async deleteChunksByNode(nodeId: number): Promise<void> {
    await this.ensureCollection(this.chunksCollection);
    await qdrantFetch(`/collections/${encodeURIComponent(this.chunksCollection)}/points/delete?wait=true`, {
      method: 'POST',
      body: JSON.stringify({
        filter: {
          must: [{ key: 'nodeId', match: { value: nodeId } }],
        },
      }),
    });
  }

  async deleteNode(nodeId: number): Promise<void> {
    await this.deleteChunksByNode(nodeId);
    await this.ensureCollection(this.nodesCollection);
    await qdrantFetch(`/collections/${encodeURIComponent(this.nodesCollection)}/points/delete?wait=true`, {
      method: 'POST',
      body: JSON.stringify({
        points: [nodeId],
      }),
    });
  }

  async healthCheck(): Promise<VectorBackendHealth> {
    try {
      await qdrantFetch('/collections', { method: 'GET' });
      await this.ensureCollection(this.chunksCollection);
      await this.ensureCollection(this.nodesCollection);
      return {
        ok: true,
        backend: 'qdrant',
        dimensions: this.dimensions,
        detail: `Qdrant reachable at ${process.env.QDRANT_URL || 'http://localhost:6333'}`,
      };
    } catch (error) {
      return {
        ok: false,
        backend: 'qdrant',
        dimensions: this.dimensions,
        detail: error instanceof Error ? error.message : String(error),
      };
    }
  }
}
