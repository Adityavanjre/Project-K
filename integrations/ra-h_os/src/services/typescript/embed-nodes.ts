/**
 * Node metadata embedding service for RA-H knowledge management system
 * Embeds node metadata (title, source, context, AI analysis) into nodes.embedding field
 */

import {
  createDatabaseConnection,
  serializeFloat32Vector,
  formatEmbeddingText,
  batchProcess
} from './sqlite-vec';
import { createEmbeddingProvider } from '@/services/embedding/provider';
import { generateUtilityText } from '@/services/llm/provider';
import { getVectorBackend } from '@/services/vectorBackend/factory';

interface NodeRecord {
  id: number;
  title: string;
  source: string | null;
  description: string | null;
  embedding?: Buffer | null;
  embedding_updated_at?: string | null;
  embedding_text?: string | null;
}

interface EmbedNodeOptions {
  nodeId?: number;
  forceReEmbed?: boolean;
  verbose?: boolean;
}

export class NodeEmbedder {
  private db: ReturnType<typeof createDatabaseConnection>;
  private processedCount: number = 0;
  private failedCount: number = 0;

  constructor() {
    this.db = createDatabaseConnection();
  }

  /**
   * Analyze node content with AI to extract insights
   */
  private async analyzeNodeWithAI(node: NodeRecord): Promise<string> {
    const prompt = `Analyze this content and provide 2-3 key insights or themes in a concise paragraph (max 100 words):

Title: ${node.title}
Source: ${node.source || 'No source'}

    Focus on the main concepts, key relationships, and practical implications.`;

    try {
      const text = await generateUtilityText({
        prompt,
        maxOutputTokens: 150,
        temperature: 0.3,
        task: 'embedding_prep_analysis',
      });

      return text;
    } catch (error) {
      console.error(`AI analysis failed for node ${node.id}:`, error);
      return '';
    }
  }

  /**
   * Generate embedding for text using the active embedding profile.
   */
  private async generateEmbedding(text: string): Promise<number[]> {
    return createEmbeddingProvider().generateEmbedding(text);
  }

  /**
   * Embed a single node
   */
  private async embedNode(node: NodeRecord, forceReEmbed: boolean = false): Promise<void> {
    // Skip if already embedded and not forcing
    if (node.embedding && !forceReEmbed) {
      console.log(`Skipping node ${node.id} - already has embedding`);
      return;
    }

    // Create base embedding text
    let embeddingText = formatEmbeddingText(
      node.title,
      node.source || '',
      node.description,
      null
    );

    // Add AI analysis if source exists
    const sourceText = node.source || '';
    if (sourceText.trim().length > 0) {
      const analysis = await this.analyzeNodeWithAI(node);
      if (analysis) {
        embeddingText += `\n\nAI Analysis: ${analysis}`;
      }
    }

    try {
      // Generate embedding
      const embedding = await this.generateEmbedding(embeddingText);
      const embeddingBlob = serializeFloat32Vector(embedding);

      // Update database
      const updateStmt = this.db.prepare(`
        UPDATE nodes
        SET embedding = ?,
            embedding_updated_at = ?,
            embedding_text = ?
        WHERE id = ?
      `);

      const now = new Date().toISOString();
      updateStmt.run(embeddingBlob, now, embeddingText, node.id);

      // Update vec_nodes virtual table
      try {
        const vectorBackend = await getVectorBackend();
        await vectorBackend.upsertNode(node.id, embeddingText, embedding);
      } catch (vecError) {
        console.warn(`Could not update node vector backend for node ${node.id}:`, vecError);
        // Continue - main embedding is still saved
      }

      this.processedCount++;
      console.log(`✓ Embedded node ${node.id}: "${node.title}"`);

    } catch (error) {
      this.failedCount++;
      console.error(`✗ Failed to embed node ${node.id}:`, error);
      throw error;
    }
  }

  /**
   * Embed nodes based on options
   */
  async embedNodes(options: EmbedNodeOptions = {}): Promise<{ processed: number; failed: number }> {
    const { nodeId, forceReEmbed = false, verbose = false } = options;

    let query: string;
    let params: any[] = [];

    if (nodeId) {
      // Single node
        query = `
        SELECT n.id, n.title, n.source, n.description,
               n.embedding, n.embedding_updated_at
        FROM nodes n
        WHERE n.id = ?
      `;
      params = [nodeId];
    } else if (forceReEmbed) {
      // All nodes
      query = `
        SELECT n.id, n.title, n.source, n.description,
               n.embedding, n.embedding_updated_at
        FROM nodes n
        ORDER BY n.id
      `;
    } else {
      // Only nodes without embeddings
      query = `
        SELECT n.id, n.title, n.source, n.description,
               n.embedding, n.embedding_updated_at
        FROM nodes n
        WHERE n.embedding IS NULL OR n.embedding_updated_at IS NULL
        ORDER BY n.id
      `;
    }

    const stmt = this.db.prepare(query);
    const nodes = stmt.all(...params) as NodeRecord[];

    if (nodes.length === 0) {
      console.log('No nodes to process');
      return { processed: 0, failed: 0 };
    }

    console.log(`Processing ${nodes.length} nodes...`);

    // Process in batches
    await batchProcess(
      nodes,
      async (node) => {
        try {
          await this.embedNode(node, forceReEmbed);
        } catch {
          // Error already logged in embedNode
        }
      },
      5, // Batch size
      verbose ? (processed, total) => {
        console.log(`Progress: ${processed}/${total} nodes`);
      } : undefined
    );

    console.log(`\nComplete! Processed: ${this.processedCount}, Failed: ${this.failedCount}`);

    return {
      processed: this.processedCount,
      failed: this.failedCount
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
  const nodeId = args.includes('--node-id')
    ? parseInt(args[args.indexOf('--node-id') + 1])
    : undefined;

  const forceReEmbed = args.includes('--force');
  const verbose = args.includes('--verbose');

  const embedder = new NodeEmbedder();

  try {
    await embedder.embedNodes({ nodeId, forceReEmbed, verbose });
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
