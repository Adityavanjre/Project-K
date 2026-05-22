/**
 * Universal chunking and embedding service for RA-H knowledge management system
 * Takes a node_id, reads source content from nodes table, chunks it, and stores in chunks table
 */

import { RecursiveCharacterTextSplitter } from '@langchain/textsplitters';
import { 
  createDatabaseConnection, 
  batchProcess 
} from './sqlite-vec';
import { createEmbeddingProvider, getEmbeddingProviderInfo } from '@/services/embedding/provider';
import { getVectorBackend } from '@/services/vectorBackend/factory';

interface Node {
  id: number;
  title: string;
  source: string | null;
  chunk_status?: string | null;
}

interface EmbedUniversalOptions {
  nodeId: number;
  verbose?: boolean;
}

export class UniversalEmbedder {
  private db: ReturnType<typeof createDatabaseConnection>;
  private textSplitter: RecursiveCharacterTextSplitter;
  
  constructor() {
    this.db = createDatabaseConnection();
    
    // Configure text splitter (same as old KMS system)
    this.textSplitter = new RecursiveCharacterTextSplitter({
      chunkSize: 1000,
      chunkOverlap: 200,
      separators: ["\n\n", "\n", ". ", " ", ""],
    });
  }

  /**
   * Generate embedding for text using the active embedding profile.
   */
  private async generateEmbedding(text: string): Promise<number[]> {
    return createEmbeddingProvider().generateEmbedding(text);
  }

  /**
   * Delete existing chunks for a node
   */
  private async deleteExistingChunks(nodeId: number): Promise<void> {
    try {
      const vectorBackend = await getVectorBackend();
      await vectorBackend.deleteChunksByNode(nodeId);
    } catch (error) {
      console.warn(`Could not delete existing chunk vectors for node ${nodeId}:`, error);
    }
    
    const deleteChunksStmt = this.db.prepare('DELETE FROM chunks WHERE node_id = ?');
    deleteChunksStmt.run(nodeId);
  }

  /**
   * Store a chunk with its embedding
   */
  private async storeChunk(
    nodeId: number,
    chunkContent: string,
    chunkIndex: number,
    metadata: Record<string, unknown>
  ): Promise<void> {
    // Generate embedding
    const embedding = await this.generateEmbedding(chunkContent);
    
    // Insert into chunks table (align with existing schema)
    const insertStmt = this.db.prepare(`
      INSERT INTO chunks (node_id, chunk_idx, text, embedding_type, metadata, created_at)
      VALUES (?, ?, ?, ?, ?, ?)
    `);
    
    const now = new Date().toISOString();
    const result = insertStmt.run(
      nodeId,
      chunkIndex,
      chunkContent,
      getEmbeddingProviderInfo().model,
      JSON.stringify(metadata),
      now
    );
    
    const chunkId = Number(result.lastInsertRowid);
    
    try {
      const vectorBackend = await getVectorBackend();
      await vectorBackend.upsertChunk(chunkId, nodeId, chunkIndex, chunkContent, embedding);
    } catch (error) {
      console.warn(`Could not upsert vector for chunk ${chunkId}:`, error);
    }
  }

  /**
   * Process a single node for chunking and embedding
   */
  async processNode(options: EmbedUniversalOptions): Promise<{ chunks: number }> {
    const { nodeId, verbose = false } = options;
    
    // Get node data
    const stmt = this.db.prepare(`
      SELECT id, title, source, chunk_status
      FROM nodes
      WHERE id = ?
    `);
    
    const node = stmt.get(nodeId) as Node | undefined;
    
    if (!node) {
      throw new Error(`Node ${nodeId} not found`);
    }
    
    if (!node.source || node.source.trim().length === 0) {
      console.log(`Node ${nodeId} has no source content to process`);
      return { chunks: 0 };
    }
    
    console.log(`Processing node ${nodeId}: "${node.title}"`);
    
    // Delete existing chunks
    await this.deleteExistingChunks(nodeId);
    
    // Split text into chunks
    const chunks = await this.textSplitter.splitText(node.source);
    
    if (verbose) {
      console.log(`Split into ${chunks.length} chunks`);
    }
    
    // Process each chunk
    let startChar = 0;
    await batchProcess(
      chunks.map((chunkContent, index) => ({ chunkContent, index })),
      async ({ chunkContent, index }) => {
        const endChar = startChar + chunkContent.length;
        
        const metadata = {
          node_id: nodeId,
          chunk_index: index,
          start_char: startChar,
          end_char: endChar,
          title: node.title,
        };
        
        await this.storeChunk(nodeId, chunkContent, index, metadata);
        
        if (verbose) {
          console.log(`  Chunk ${index + 1}/${chunks.length}: ${chunkContent.substring(0, 50)}...`);
        }
        
        startChar = endChar;
      },
      5, // Batch size
      verbose ? (processed, total) => {
        console.log(`Embedding progress: ${processed}/${total} chunks`);
      } : undefined
    );
    
    // Update node chunk_status
    const updateStmt = this.db.prepare(`
      UPDATE nodes 
      SET chunk_status = 'chunked'
      WHERE id = ?
    `);
    updateStmt.run(nodeId);
    
    console.log(`✓ Created ${chunks.length} chunks for node ${nodeId}`);
    
    return { chunks: chunks.length };
  }

  /**
   * Get statistics about chunks in the database
   */
  getStats(): { totalChunks: number; totalNodes: number; avgChunksPerNode: number } {
    const statsStmt = this.db.prepare(`
      SELECT 
        COUNT(DISTINCT node_id) as total_nodes,
        COUNT(*) as total_chunks
      FROM chunks
    `);
    
    const stats = statsStmt.get() as any;
    
    return {
      totalChunks: stats.total_chunks || 0,
      totalNodes: stats.total_nodes || 0,
      avgChunksPerNode: stats.total_nodes > 0 
        ? Math.round(stats.total_chunks / stats.total_nodes * 10) / 10 
        : 0
    };
  }

  /**
   * Close database connection
   */
  close(): void {
    this.db.close();
  }
}

/**
 * CLI interface for direct execution
 */
export async function runCLI(args: string[]): Promise<void> {
  if (!args.includes('--node-id')) {
    console.error('Error: --node-id is required');
    process.exit(1);
  }
  
  const nodeId = parseInt(args[args.indexOf('--node-id') + 1]);
  const verbose = args.includes('--verbose');
  
  if (isNaN(nodeId)) {
    console.error('Error: Invalid node ID');
    process.exit(1);
  }
  
  const embedder = new UniversalEmbedder();
  
  try {
    await embedder.processNode({ nodeId, verbose });
    
    if (verbose) {
      const stats = embedder.getStats();
      console.log('\nDatabase statistics:');
      console.log(`  Total chunks: ${stats.totalChunks}`);
      console.log(`  Total nodes with chunks: ${stats.totalNodes}`);
      console.log(`  Average chunks per node: ${stats.avgChunksPerNode}`);
    }
  } finally {
    embedder.close();
  }
}

// Run if called directly (for testing)
if (require.main === module) {
  runCLI(process.argv.slice(2)).catch(error => {
    console.error('Error:', error);
    process.exit(1);
  });
}
