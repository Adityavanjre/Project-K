import type { DatabaseIntegrityReport } from './sqlite-client';

// Service instances
export { nodeService, NodeService } from './nodes';
export { chunkService, ChunkService } from './chunks';
export { edgeService, EdgeService } from './edges';
// export { HelperService } from './helpers'; // Removed - migrated to JSON-based service

// Types
export * from '@/types/database';

export interface DatabaseHealthStatus {
  connected: boolean;
  vectorExtension: boolean;
  tablesExist: boolean;
  quickCheckOk: boolean;
  integrityCheckOk: boolean;
  foreignKeyViolations: number;
  lostAndFoundExists: boolean;
  ftsTables: {
    nodes: boolean;
    chunks: boolean;
  };
  vecTables: {
    nodes: boolean;
    chunks: boolean;
  };
  integrityState: DatabaseIntegrityReport['state'];
  repairableFtsTables: DatabaseIntegrityReport['repairableFtsTables'];
  canRepairFts: boolean;
  summary: string;
  error?: string;
}

// Health check utility
export async function checkDatabaseHealth(): Promise<DatabaseHealthStatus> {
  try {
    return checkSQLiteDatabaseHealth();
  } catch (error) {
    return {
      connected: false,
      vectorExtension: false,
      tablesExist: false,
      quickCheckOk: false,
      integrityCheckOk: false,
      foreignKeyViolations: -1,
      lostAndFoundExists: false,
      ftsTables: { nodes: false, chunks: false },
      vecTables: { nodes: false, chunks: false },
      integrityState: 'corrupt',
      repairableFtsTables: [],
      canRepairFts: false,
      summary: 'Database health check failed before classification.',
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}

async function checkSQLiteDatabaseHealth(): Promise<DatabaseHealthStatus> {
  try {
    const { getSQLiteClient } = await import('./sqlite-client');
    const sqlite = getSQLiteClient();
    const integrity = sqlite.getIntegrityReport(true);
    
    const connected = await sqlite.testConnection();
    if (!connected) {
      return {
        connected: false,
        vectorExtension: false,
        tablesExist: false,
        quickCheckOk: false,
        integrityCheckOk: false,
        foreignKeyViolations: -1,
        lostAndFoundExists: false,
        ftsTables: { nodes: false, chunks: false },
        vecTables: { nodes: false, chunks: false },
        integrityState: integrity.state,
        repairableFtsTables: integrity.repairableFtsTables,
        canRepairFts: integrity.canRepairFts,
        summary: integrity.summary,
        error: 'SQLite connection failed'
      };
    }

    const vectorExtension = await sqlite.checkVectorExtension();
    
    // Check if main tables exist
    const tables = await sqlite.checkTables();
    const requiredTables = ['nodes', 'chunks', 'edges'];
    const tablesExist = requiredTables.every(table => tables.includes(table));

    return {
      connected,
      vectorExtension,
      tablesExist,
      quickCheckOk: integrity.quickCheck.ok,
      integrityCheckOk: integrity.integrityCheck.ok,
      foreignKeyViolations: integrity.foreignKeyViolations,
      lostAndFoundExists: integrity.lostAndFoundExists,
      ftsTables: integrity.ftsTables,
      vecTables: integrity.vecTables,
      integrityState: integrity.state,
      repairableFtsTables: integrity.repairableFtsTables,
      canRepairFts: integrity.canRepairFts,
      summary: integrity.summary,
      error: integrity.error,
    };
  } catch (error) {
    return {
      connected: false,
      vectorExtension: false,
      tablesExist: false,
      quickCheckOk: false,
      integrityCheckOk: false,
      foreignKeyViolations: -1,
      lostAndFoundExists: false,
      ftsTables: { nodes: false, chunks: false },
      vecTables: { nodes: false, chunks: false },
      integrityState: 'corrupt',
      repairableFtsTables: [],
      canRepairFts: false,
      summary: 'Database health check failed during execution.',
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
}
