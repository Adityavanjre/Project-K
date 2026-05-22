import {
  createEmbeddingProvider,
  getEmbeddingProviderInfo,
  validateEmbeddingDimensions
} from '@/services/embedding/provider';

export class EmbeddingService {
  /**
   * Generate embedding for a search query using the active embedding profile.
   */
  static async generateQueryEmbedding(query: string): Promise<number[]> {
    try {
      return await createEmbeddingProvider().generateEmbedding(query);
    } catch (error) {
      console.error('Failed to generate query embedding:', error);
      throw new Error(`Embedding generation failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
    }
  }

  /**
   * Validate embedding dimensions match the active profile.
   */
  static validateEmbedding(embedding: number[]): boolean {
    return validateEmbeddingDimensions(embedding);
  }

  static getActiveEmbeddingInfo() {
    return getEmbeddingProviderInfo();
  }
}
