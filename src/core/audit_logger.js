/**
 * KALI Global Audit Logger — v1.0 SOVEREIGN
 * Records an immutable, append-only JSONL log of every system action.
 */

const fs = require('fs');
const path = require('path');
const EventBus = require('./shared/event_bus');

const AUDIT_FILE = path.join(__dirname, '../../data/audit.log');

function init() {
    console.log("[AuditLogger] Initialized.");

    // Listen for tool executions
    EventBus.on('tool:started', (data) => logAction('TOOL_START', data));
    EventBus.on('tool:completed', (data) => logAction('TOOL_DONE', data));
    EventBus.on('tool:failed', (data) => logAction('TOOL_FAIL', data));
    
    // Listen for mission states
    EventBus.on('mission:updated', (data) => logAction('MISSION_STATE', data));
    
    // Listen for emergency controls
    EventBus.on('system:failsafe', (data) => logAction('EMERGENCY', data));
}

function logAction(actionType, payload) {
    const entry = {
        timestamp: new Date().toISOString(),
        action: actionType,
        ...payload
    };

    const line = JSON.stringify(entry) + '\n';
    
    // Append asynchronously to prevent blocking execution
    fs.appendFile(AUDIT_FILE, line, (err) => {
        if (err) console.error("[AuditLogger] Failed to write audit log:", err);
    });
}

/**
 * Retrieve recent logs for the UI
 */
function getRecentLogs(lines = 100) {
    if (!fs.existsSync(AUDIT_FILE)) return [];
    try {
        const data = fs.readFileSync(AUDIT_FILE, 'utf-8');
        const split = data.trim().split('\n');
        const slice = split.slice(-lines);
        return slice.map(l => JSON.parse(l));
    } catch (e) {
        return [];
    }
}

module.exports = { init, getRecentLogs };
