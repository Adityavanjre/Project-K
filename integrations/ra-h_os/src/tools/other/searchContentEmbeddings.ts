import { tool } from 'ai';
import { z } from 'zod';
import { chunkService } from '@/services/database/chunks';
import { EmbeddingService } from '@/services/embeddings';

export const searchContentEmbeddingsTool = tool({
  description: 'Search source chunks with hybrid retrieval: vector similarity plus FTS/keyword fallback merged for reliability.',
  inputSchema: z.object({
    query: z.string().describe('The search query to find semantically similar content'),
    limit: z.number().min(1).max(20).default(5).describe('Maximum number of results to return (default: 5)'),
    node_id: z.number().optional().describe('Optional: search within a specific node only'),
    similarity_threshold: z.number().min(0.1).max(1.0).default(0.5).describe('Minimum similarity score (0.1-1.0, default: 0.5)')
  }),
  execute: async ({ query, limit = 5, node_id, similarity_threshold = 0.5 }) => {
    const startTime = Date.now();
    
    try {
      console.log(`🔍 Searching embeddings for: "${query}"${node_id ? ` in node ${node_id}` : ' across all nodes'} (threshold: ${similarity_threshold})`);
      
      // Generate embedding for the search query
      let queryEmbedding: number[];
      try {
        queryEmbedding = await EmbeddingService.generateQueryEmbedding(query);
      } catch (embeddingError) {
        console.error('Failed to generate embedding, falling back to text search:', embeddingError);
        // Fallback to text search immediately if embedding fails
        const chunks = await chunkService.textSearchFallback(
          query,
          limit,
          node_id ? [node_id] : undefined
        );
        
        return {
          success: true,
          data: {
            chunks: chunks.map(chunk => ({
              id: chunk.id,
              node_id: chunk.node_id,
              chunk_idx: chunk.chunk_idx,
              preview: chunk.text?.length ? `${chunk.text.slice(0, 180)}${chunk.text.length > 180 ? '…' : ''}` : '',
              text: chunk.text ?? '',
              similarity: chunk.similarity,
            })),
            query: query,
            searched_nodes: node_id ? [node_id] : 'all',
            count: chunks.length,
            similarity_threshold,
            search_method: 'text_fallback',
            search_time_ms: Date.now() - startTime
          }
        };
      }
      
      if (!EmbeddingService.validateEmbedding(queryEmbedding)) {
        return {
          success: false,
          error: 'Invalid embedding generated for query',
          data: null
        };
      }

      // Determine search scope
      let searchNodeIds: number[] | undefined;
      if (node_id) {
        searchNodeIds = [node_id];
      }

      // Perform vector similarity search with improved parameters
      const chunks = await chunkService.searchChunks(
        queryEmbedding,
        similarity_threshold,
        limit,
        searchNodeIds,
        query // provide fallback query
      );

      const searchTime = Date.now() - startTime;
      const hasResults = chunks.length > 0;

      console.log(`📊 Found ${chunks.length} relevant chunks with similarity >= ${similarity_threshold} (${searchTime}ms)`);
      if (hasResults) {
        console.log(`🎯 Top result: chunk ${chunks[0].id} (similarity: ${chunks[0].similarity.toFixed(3)})`);
        console.log(`📝 Preview: ${chunks[0].text?.slice(0, 100)}...`);
      }

      // If no results and threshold is high, suggest retry with lower threshold
      let suggestions: string[] = [];
      if (!hasResults && similarity_threshold > 0.3) {
        suggestions.push(`No results found with similarity >= ${similarity_threshold}. Try lowering the threshold to 0.3 for broader results.`);
      }
      if (!hasResults && searchNodeIds) {
        suggestions.push('No results in specified node. Try searching across all nodes.');
      }

      return {
        success: true,
        data: {
          chunks: chunks.map(chunk => ({
            id: chunk.id,
            node_id: chunk.node_id,
            chunk_idx: chunk.chunk_idx,
            preview: chunk.text?.length ? `${chunk.text.slice(0, 180)}${chunk.text.length > 180 ? '…' : ''}` : '',
            text: chunk.text ?? '',
            similarity: chunk.similarity,
          })),
          query: query,
          searched_nodes: searchNodeIds || 'all',
          count: chunks.length,
          similarity_threshold,
          search_method: query ? 'hybrid_vector_fts' : 'vector_search',
          search_time_ms: searchTime,
          suggestions: suggestions.length > 0 ? suggestions : undefined
        }
      };
    } catch (error) {
      const searchTime = Date.now() - startTime;
      console.error('Embedding search failed completely:', error);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Failed to search content embeddings',
        data: null,
        search_time_ms: searchTime
      };
    }
  }
});
