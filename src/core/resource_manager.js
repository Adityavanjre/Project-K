/**
 * KALI Resource Manager — v1.0 SOVEREIGN
 * Limits concurrent tools, prioritizes tasks, and tracks basic CPU/Memory.
 * Acts as a queueing layer on top of RuntimeManager.
 */

const os = require('os');
const RuntimeManager = require('./runtime_manager');
const EventBus = require('./shared/event_bus');

const BASE_MAX_CONCURRENT = parseInt(process.env.KALI_MAX_CONCURRENT || '3', 10);
let currentMaxConcurrent = BASE_MAX_CONCURRENT;

const executionQueue = []; // { toolId, args, priority, resolve, reject, timestamp }

// Initialize listeners for System Monitor dynamic scaling
EventBus.on('system:overload', () => {
    if (currentMaxConcurrent > 1) {
        currentMaxConcurrent = Math.max(1, currentMaxConcurrent - 1);
        console.warn(`[ResourceManager] System overloaded. Scaling DOWN concurrency to ${currentMaxConcurrent}`);
    }
});

EventBus.on('system:normal', () => {
    if (currentMaxConcurrent < BASE_MAX_CONCURRENT) {
        currentMaxConcurrent = Math.min(BASE_MAX_CONCURRENT, currentMaxConcurrent + 1);
        console.log(`[ResourceManager] System normal. Scaling UP concurrency to ${currentMaxConcurrent}`);
        _processQueue(); // Re-trigger queue processing with new capacity
    }
});

// Track running processes managed by ResourceManager
const activeTasks = new Map(); // toolId -> { processData, priority, startTime }

/**
 * Get current system resource usage.
 */
function getSystemLoad() {
    const totalMem = os.totalmem();
    const freeMem = os.freemem();
    const usedMemRatio = (totalMem - freeMem) / totalMem;
    const cpus = os.cpus();
    // Rough estimate of CPU load using the 1m load average (if available, else mock)
    const loadAvg = os.loadavg ? os.loadavg()[0] / cpus.length : 0.5;

    return {
        cpu_load_percent: Math.round(loadAvg * 100),
        mem_used_percent: Math.round(usedMemRatio * 100),
        active_tools: activeTasks.size,
        queued_tasks: executionQueue.length
    };
}

/**
 * Queue a tool for execution. Returns a promise that resolves when the tool starts.
 * @param {string} toolId 
 * @param {Object} args 
 * @param {string} priority 'high', 'medium', 'low'
 */
function requestExecution(toolId, args = {}, priority = 'medium') {
    return new Promise((resolve, reject) => {
        executionQueue.push({
            toolId,
            args,
            priority,
            resolve,
            reject,
            timestamp: Date.now()
        });
        
        console.log(`[ResourceManager] Queued ${toolId} (Priority: ${priority})`);
        _processQueue();
    });
}

/**
 * Stop a task and remove from tracking.
 */
function stopTask(toolId) {
    if (activeTasks.has(toolId)) {
        RuntimeManager.stopTool(toolId);
        activeTasks.delete(toolId);
        console.log(`[ResourceManager] Stopped task ${toolId}`);
        _processQueue();
        return true;
    }
    return false;
}

/**
 * Internal: Process the queue.
 */
async function _processQueue() {
    // Clean up finished tasks from activeTasks map
    const running = RuntimeManager.getStatus();
    for (const [toolId] of activeTasks.entries()) {
        if (!running[toolId]) {
            activeTasks.delete(toolId);
        }
    }

    if (activeTasks.size >= currentMaxConcurrent) {
        // We are at capacity. Should we preempt a low priority task?
        const highPriorityWaiting = executionQueue.some(q => q.priority === 'high');
        if (highPriorityWaiting) {
            // Find a low priority task to kill
            for (const [id, task] of activeTasks.entries()) {
                if (task.priority === 'low') {
                    console.log(`[ResourceManager] Preempting low priority task ${id} for high priority task`);
                    stopTask(id);
                    break; // Just free one slot for now
                }
            }
        }
        
        // Check capacity again after potential preemption
        if (activeTasks.size >= currentMaxConcurrent) {
            return; // Still at capacity
        }
    }

    if (executionQueue.length === 0) return;

    // Sort queue: high -> medium -> low, then by oldest first
    executionQueue.sort((a, b) => {
        const pMap = { 'high': 3, 'medium': 2, 'low': 1 };
        if (pMap[a.priority] !== pMap[b.priority]) {
            return pMap[b.priority] - pMap[a.priority];
        }
        return a.timestamp - b.timestamp;
    });

    const nextTask = executionQueue.shift();

    try {
        console.log(`[ResourceManager] Starting ${nextTask.toolId} from queue`);
        const result = await RuntimeManager.startTool(nextTask.toolId, nextTask.args);
        
        if (result.status === 'success') {
            activeTasks.set(nextTask.toolId, {
                priority: nextTask.priority,
                startTime: Date.now()
            });
        }
        
        nextTask.resolve(result);
    } catch (err) {
        nextTask.reject(err);
    }
}

module.exports = {
    getSystemLoad,
    requestExecution,
    stopTask
};
