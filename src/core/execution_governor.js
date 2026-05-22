/**
 * KALI Execution Governor — v1.0 SOVEREIGN
 * Observes all executions, classifies them by intensity/risk, and tags them.
 * NEVER BLOCKS executions. Only acts as an observation and tagging layer.
 */

const EventBus = require('./shared/event_bus');

// Define classification rules
const INTENSIVE_TOOLS = ['nmap', 'ffuf', 'gobuster', 'masscan', 'nuclei'];
const CRITICAL_TOOLS = ['sqlmap', 'metasploit', 'exploit_runner'];

function init() {
    console.log("[ExecutionGovernor] Initialized.");

    // Intercept tool starts
    EventBus.on('tool:starting', (payload) => {
        const { tool_id, args } = payload;
        
        let classification = 'normal';
        if (INTENSIVE_TOOLS.some(t => tool_id.includes(t))) {
            classification = 'intensive';
        } else if (CRITICAL_TOOLS.some(t => tool_id.includes(t))) {
            classification = 'critical';
        }

        console.log(`[Governor] Observing ${tool_id} execution. Class: [${classification.toUpperCase()}]`);

        // Emit governed start event
        EventBus.emit('tool:started', {
            ...payload,
            classification,
            governor_approved: true // Always true in Phase 7
        });
    });
}

module.exports = { init };
