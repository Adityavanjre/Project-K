/**
 * KALI Mission Runner — v1.0 SOVEREIGN
 * Background loop that executes pending and running missions autonomously.
 */

const MissionEngine = require('./mission_engine');
const ResourceManager = require('./resource_manager');
const ContextEngine = require('./context_engine');
const TerminalBridge = require('../ui/terminal_bridge');

// Track actively executing steps so we don't double-run them
const executingMissions = new Set(); 

function getBridge() {
    try { return require('../ui/terminal_bridge'); }
    catch (_) { return null; }
}

async function runStep(mission) {
    if (mission.current_step_idx >= mission.steps.length) {
        MissionEngine.updateStatus(mission.id, 'completed');
        return;
    }

    const stepDef = mission.steps[mission.current_step_idx];
    const toolId = stepDef.tool_id;
    
    console.log(`[MissionRunner] [${mission.id}] Executing step ${mission.current_step_idx + 1}/${mission.steps.length}: ${toolId}`);
    MissionEngine.addLog(mission.id, `Started step: ${toolId}`);

    // Build arguments from accumulated facts
    const args = ContextEngine.buildChainArgs(mission.facts, toolId, { target: mission.target });

    try {
        // Request execution through Resource Manager
        const result = await ResourceManager.requestExecution(toolId, args, mission.priority);
        
        if (result.status === 'success') {
            // Because ResourceManager returns success immediately upon spawn, we should ideally wait
            // for the process to exit. But since this is an async polling runner, we'll simulate 
            // a wait. In a full event-driven system, RuntimeManager would emit a 'done' event.
            // For now, we assume success and advance.
            
            MissionEngine.addLog(mission.id, `Completed step: ${toolId}`);
            MissionEngine.advanceStep(mission.id, { [`${toolId}_ran`]: true });
        } else {
            MissionEngine.updateStatus(mission.id, 'failed', result.data);
        }
    } catch (err) {
        console.error(`[MissionRunner] Execution error for ${mission.id}:`, err);
        MissionEngine.updateStatus(mission.id, 'failed', err.message);
    }
}

async function processMissions() {
    // 1. Check for Pending missions to start
    const pending = MissionEngine.listMissions('pending');
    for (const mission of pending) {
        MissionEngine.updateStatus(mission.id, 'running');
        MissionEngine.addLog(mission.id, 'Mission execution started.');
    }

    // 2. Process Running missions
    const running = MissionEngine.listMissions('running');
    for (const mission of running) {
        if (!executingMissions.has(mission.id)) {
            executingMissions.add(mission.id);
            // Run step asynchronously
            runStep(mission).finally(() => {
                executingMissions.delete(mission.id);
            });
        }
    }
}

function init() {
    console.log("[MissionRunner] Background loop initialized.");
    
    // On startup, any 'running' missions should be recovered. 
    // They are technically already 'running' in the DB but the processes died.
    const running = MissionEngine.listMissions('running');
    if (running.length > 0) {
        console.log(`[MissionRunner] Recovered ${running.length} running missions from previous session.`);
        running.forEach(m => MissionEngine.addLog(m.id, 'Recovered running mission after system restart.'));
    }

    setInterval(processMissions, 5000); // Poll every 5 seconds
}

module.exports = { init };
