/**
 * SQLite vec0 utilities for TypeScript
 * Handles binary serialization for vec0 BLOB storage
 */

import Database from 'better-sqlite3';
import {
  getDatabasePath as getRuntimeDatabasePath,
  getDbVectorCapability as getVectorCapability,
  getVecExtensionPath as getRuntimeVecExtensionPath
} from '@/services/database/sqlite-runtime';

/**
 * Serialize a float array to binary format for vec0 storage
 * Equivalent to Python's struct.pack(f'{len(vector)}f', *vector)
 */
export function serializeFloat32Vector(vector: number[]): Buffer {
  const buffer = Buffer.allocUnsafe(vector.length * 4);
  for (let i = 0; i < vector.length; i++) {
    buffer.writeFloatLE(vector[i], i * 4);
  }
  return buffer;
}

/**
 * Deserialize a vec0 BLOB back to float array
 */
export function deserializeFloat32Vector(blob: Buffer): number[] {
  const vector: number[] = [];
  for (let i = 0; i < blob.length; i += 4) {
    vector.push(blob.readFloatLE(i));
  }
  return vector;
}

/**
 * Get SQLite database path from environment or default location
 */
export function getDatabasePath(): string {
  return getRuntimeDatabasePath();
}

/**
 * Get vec extension path from environment or default location
 */
export function getVecExtensionPath(): string {
  return getRuntimeVecExtensionPath();
}

/**
 * Create database connection with vec0 extension loaded
 */
export function createDatabaseConnection(): Database.Database {
  const dbPath = getDatabasePath();
  const vecPath = getVecExtensionPath();

  const db = new Database(dbPath);

  // Load vec0 extension
  try {
    db.loadExtension(vecPath);
  } catch (error) {
    console.error('Warning: Could not load vec0 extension:', error);
    // Continue without vector support for non-vector operations
  }

  return db;
}

export function getDbVectorCapability(db: Database.Database) {
  return getVectorCapability(db);
}

/**
 * Format embedding text for node metadata
 */
export function formatEmbeddingText(
  title: string,
  content: string,
  description?: string | null,
  contextName?: string | null
): string {
  const descriptionText = description && description.trim() ? description.trim() : 'none';
  const contextText = contextName && contextName.trim() ? contextName.trim() : 'none';
  return `Title: ${title}\n\nDescription: ${descriptionText}\n\nContent: ${content}\n\nContext: ${contextText}`;
}

/**
 * Batch process items with progress logging
 */
export async function batchProcess<T, R>(
  items: T[],
  processor: (item: T) => Promise<R>,
  batchSize: number = 10,
  onProgress?: (processed: number, total: number) => void
): Promise<R[]> {
  const results: R[] = [];

  for (let i = 0; i < items.length; i += batchSize) {
    const batch = items.slice(i, Math.min(i + batchSize, items.length));
    const batchResults = await Promise.all(batch.map(processor));
    results.push(...batchResults);

    if (onProgress) {
      onProgress(Math.min(i + batchSize, items.length), items.length);
    }
  }

  return results;
}
