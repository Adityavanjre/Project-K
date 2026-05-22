import { embedNodeContent } from '@/services/embedding/ingestion';
import { nodeService } from '@/services/database';
import { getSQLiteClient } from '@/services/database/sqlite-client';

interface AutoEmbedTask {
  nodeId: number;
  force?: boolean;
  reason?: string;
}

const DEFAULT_COOLDOWN_MS = 2 * 60 * 1000; // 2 minutes between automatic runs per node
const RECOVERY_INTERVAL_MS = 60 * 1000;

export class AutoEmbedQueue {
  private readonly queue: number[] = [];
  private readonly pendingTasks = new Map<number, AutoEmbedTask>();
  private readonly running = new Set<number>();
  private readonly lastRunAt = new Map<number, number>();
  private readonly maxConcurrent = 1;
  private readonly cooldownMs = DEFAULT_COOLDOWN_MS;

  async recoverStuckNodes(): Promise<void> {
    const notChunked = await nodeService.getNodes({ chunkStatus: 'not_chunked', limit: 1000 });
    for (const node of notChunked) {
      this.enqueue(node.id, { reason: 'startup_recovery' });
    }

    // Recover nodes stuck in 'chunking' state — these were interrupted mid-process
    // and will never complete without intervention since executeTask skips them otherwise
    const stuckChunking = await nodeService.getNodes({ chunkStatus: 'chunking', limit: 1000 });
    for (const node of stuckChunking) {
      this.enqueue(node.id, { force: true, reason: 'stuck_chunking_recovery' });
    }
  }

  enqueue(nodeId: number, task: Omit<AutoEmbedTask, 'nodeId'> = {}): boolean {
    const existing = this.pendingTasks.get(nodeId);
    if (!existing) {
      this.pendingTasks.set(nodeId, { nodeId, ...task });
      this.queue.push(nodeId);
    } else {
      existing.force = existing.force || task.force;
      existing.reason = existing.reason || task.reason;
    }

    this.processQueue();
    return true;
  }

  private processQueue() {
    if (this.running.size >= this.maxConcurrent) {
      return;
    }

    const nextId = this.queue.shift();
    if (typeof nextId !== 'number') {
      return;
    }

    const task = this.pendingTasks.get(nextId);
    if (!task) {
      // Task was removed; try next
      this.processQueue();
      return;
    }
    this.pendingTasks.delete(nextId);

    const now = Date.now();
    const lastRun = this.lastRunAt.get(task.nodeId);
    if (!task.force && lastRun && now - lastRun < this.cooldownMs) {
      const delay = this.cooldownMs - (now - lastRun);
      setTimeout(() => this.enqueue(task.nodeId, task), delay);
      this.processQueue();
      return;
    }

    this.running.add(task.nodeId);
    this.executeTask(task)
      .catch(error => {
        console.error('[AutoEmbedQueue] Task failed', task.nodeId, error);
      })
      .finally(() => {
        this.running.delete(task.nodeId);
        this.lastRunAt.set(task.nodeId, Date.now());
        if (this.queue.length > 0) {
          setTimeout(() => this.processQueue(), 10);
        }
      });
  }

  private async executeTask(task: AutoEmbedTask) {
    const integrity = getSQLiteClient().getIntegrityReport();
    if (!integrity.ftsTables.chunks) {
      console.warn('[AutoEmbedQueue] Skipping chunk write because chunks FTS is degraded:', integrity.summary);
      try {
        const node = await nodeService.getNodeById(task.nodeId);
        if (node && node.chunk_status !== 'chunked' && node.chunk_status !== 'error') {
          await nodeService.updateNode(task.nodeId, { chunk_status: 'error' });
        }
      } catch (error) {
        console.warn('[AutoEmbedQueue] Failed to mark node as error while chunks FTS is degraded', task.nodeId, error);
      }
      return;
    }

    const node = await nodeService.getNodeById(task.nodeId);
    if (!node) {
      console.warn('[AutoEmbedQueue] Node missing, skipping', task.nodeId);
      return;
    }

    if (!task.force && node.chunk_status === 'chunked') {
      return;
    }

    if (node.chunk_status === 'chunking' && !task.force) {
      console.log('[AutoEmbedQueue] Node already chunking, skipping duplicate run', task.nodeId);
      return;
    }

    console.log(`🔄 [AutoEmbedQueue] Embedding node ${task.nodeId}${task.reason ? ` (${task.reason})` : ''}`);
    const result = await embedNodeContent(task.nodeId);
    if (!result.success) {
      console.error('[AutoEmbedQueue] Embedding failed', task.nodeId, result.error);
    }
  }
}

declare global {
  // eslint-disable-next-line no-var
  var autoEmbedQueue: AutoEmbedQueue | undefined;
  // eslint-disable-next-line no-var
  var autoEmbedRecoveryStarted: boolean | undefined;
  // eslint-disable-next-line no-var
  var autoEmbedRecoveryTimer: ReturnType<typeof setInterval> | undefined;
}

export const autoEmbedQueue = globalThis.autoEmbedQueue ?? new AutoEmbedQueue();
if (!globalThis.autoEmbedQueue) {
  globalThis.autoEmbedQueue = autoEmbedQueue;
}

export function startAutoEmbedRecovery(): void {
  if (globalThis.autoEmbedRecoveryStarted) {
    return;
  }
  globalThis.autoEmbedRecoveryStarted = true;

  const runRecovery = () => {
    autoEmbedQueue.recoverStuckNodes().catch(error => {
      console.error('[AutoEmbedQueue] Startup recovery failed', error);
    });
  };

  runRecovery();
  globalThis.autoEmbedRecoveryTimer = setInterval(runRecovery, RECOVERY_INTERVAL_MS);
  globalThis.autoEmbedRecoveryTimer.unref?.();
}
