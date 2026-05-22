/**
 * KALI System Monitor — v1.0 SOVEREIGN
 * Continuously polls CPU, memory, and model load.
 * Emits 'system:overload' or 'system:normal' via EventBus.
 */

const os = require('os');
const EventBus = require('./shared/event_bus');
const ModelManager = require('./model_manager');

// Thresholds
const OVERLOAD_CPU_PERCENT = 85;
const OVERLOAD_MEM_PERCENT = 85;

function init() {
    console.log("[SystemMonitor] Initialized.");
    setInterval(checkHealth, 5000);
}

async function checkHealth() {
    const totalMem = os.totalmem();
    const freeMem = os.freemem();
    const usedMemRatio = (totalMem - freeMem) / totalMem;
    const cpus = os.cpus();
    const loadAvg = os.loadavg ? os.loadavg()[0] / cpus.length : 0; // 1m load relative to cores

    const cpuPercent = Math.round(loadAvg * 100);
    const memPercent = Math.round(usedMemRatio * 100);

    const isOverloaded = (cpuPercent >= OVERLOAD_CPU_PERCENT) || (memPercent >= OVERLOAD_MEM_PERCENT);

    const payload = {
        cpu_percent: cpuPercent,
        mem_percent: memPercent,
        is_overloaded: isOverloaded
    };

    if (isOverloaded) {
        EventBus.emit('system:overload', payload);
    } else {
        EventBus.emit('system:normal', payload);
    }

    // Also emit a general health tick for the UI
    EventBus.emit('system:health', payload);
}

module.exports = { init, checkHealth };
