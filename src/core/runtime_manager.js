/**
 * KALI Runtime Manager — v2.0
 *
 * Manages process lifecycle for all swarm capabilities.
 * Spawns, tracks, and terminates tool subprocesses.
 * Pipes stdout/stderr through TerminalBridge → SocketIO → browser.
 */

const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

const EventBus = require('./shared/event_bus');
const { scanCapabilities } = require('./capability_scanner');
const Optimizer = require('./optimizer');

let internalIp;
try {
    const config = JSON.parse(fs.readFileSync(path.join(__dirname, '../../config/config.json'), 'utf8'));
    internalIp = config.sovereign?.internal?.ip;
} catch (e) {
    // Fallback silent
}

class RuntimeManager {
    constructor() {
        this.runningProcesses = new Map();
    }

    getRegistry() {
        return scanCapabilities();
    }

    async startTool(toolId, args = {}) {
        if (this.runningProcesses.has(toolId)) {
            return { status: 'error', data: `Tool ${toolId} is already running.` };
        }

        const registry = this.getRegistry();
        const tool = registry.find(t => t.id === toolId);

        if (!tool) {
            return { status: 'error', data: `Tool ${toolId} not found in registry.` };
        }

        console.log(`[RuntimeManager] Starting: ${tool.name}`);

        const cmdParts = tool.start_command.split(' ');
        const mainCmd = cmdParts[0];
        const initialArgs = cmdParts.slice(1);

        // Merge registry args with runtime args
        const finalArgs = [...initialArgs];
        for (const [key, value] of Object.entries(args)) {
            if (value !== undefined && value !== '') {
                finalArgs.push(`--${key}`, String(value));
            }
        }

        // Safe Execution Wrapper: Validate command
        if (!mainCmd || typeof mainCmd !== 'string') {
            const errorMsg = `Malformed command for ${toolId}`;
            EventBus.emit('tool:failed', { tool_id: toolId, reason: errorMsg });
            return { status: 'error', data: errorMsg };
        }

        const cwd = path.resolve(__dirname, '../../', tool.working_directory);
        
        // Notify Governor that we are about to start
        EventBus.emit('tool:starting', { tool_id: toolId, args: finalArgs });

        let proc;
        try {
            proc = spawn(mainCmd, finalArgs, {
                cwd,
                shell: true,
                // Ensure subprocess doesn't inherit a TTY — capture clean output
                windowsHide: true
            });
        } catch (spawnErr) {
            EventBus.emit('tool:failed', { tool_id: toolId, reason: spawnErr.message });
            return { status: 'error', data: `Spawn crashed: ${spawnErr.message}` };
        }

        this.runningProcesses.set(toolId, {
            process: proc,
            tool,
            state: 'running',
            startTime: new Date()
        });

        // ── Stream stdout → EventBus ────────────────────────────────────────
        proc.stdout.on('data', (chunk) => {
            this.emitOutput(toolId, 'stream', chunk.toString(), 'success');
        });

        proc.stderr.on('data', (chunk) => {
            this.emitOutput(toolId, 'log', chunk.toString(), 'error');
        });

        proc.on('close', (code) => {
            console.log(`[RuntimeManager] ${tool.name} exited (code ${code})`);
            const procData = this.runningProcesses.get(toolId);
            const durationMs = procData ? (new Date() - procData.startTime) : 0;
            this.runningProcesses.delete(toolId);
            
            // Phase 10: Optimizer tracking
            Optimizer.logExecution(toolId, durationMs, code === 0, `Exit code ${code}`);
            
            EventBus.emit('tool:done', { tool_id: toolId, exit_code: code, duration_ms: durationMs });
        });

        proc.on('error', (err) => {
            console.error(`[RuntimeManager] Spawn error for ${toolId}: ${err.message}`);
            const procData = this.runningProcesses.get(toolId);
            const durationMs = procData ? (new Date() - procData.startTime) : 0;
            this.runningProcesses.delete(toolId);
            
            // Phase 10: Optimizer tracking
            Optimizer.logExecution(toolId, durationMs, false, err.message);
            
            EventBus.emit('tool:failed', { tool_id: toolId, reason: err.message });
        });

        return {
            status: 'success',
            data: `${tool.name} started.`,
            pid: proc.pid
        };
    }

    stopTool(toolId) {
        const procInfo = this.runningProcesses.get(toolId);
        if (procInfo) {
            try { procInfo.process.kill('SIGTERM'); } catch (_) {}
            this.runningProcesses.delete(toolId);
            return { status: 'success', data: `Tool ${toolId} stopped.` };
        }
        return { status: 'error', data: `Tool ${toolId} is not running.` };
    }

    /**
     * Emit output to EventBus
     */
    emitOutput(source, type, data, status) {
        const payload = {
            source,
            type,
            data,
            status,
            timestamp: new Date().toISOString()
        };

        EventBus.emit('tool:output', payload);
    }

    getStatus() {
        const status = {};
        this.runningProcesses.forEach((val, key) => {
            status[key] = {
                state: val.state,
                startTime: val.startTime,
                name: val.tool?.name
            };
        });
        return status;
    }
}

module.exports = new RuntimeManager();

// CLI test
if (require.main === module) {
    const manager = module.exports;
    if (process.argv.includes('--test')) {
        console.log('RuntimeManager self-test — starting sovereign_recon...');
        manager.startTool('sovereign_recon', { target: internalIp })
            .then(r => console.log(r));
    }
}
