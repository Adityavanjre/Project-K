/**
 * Adapter Registry
 *
 * Maps tool_id → Adapter class.
 * Falls back to GenericAdapter for any unregistered tool.
 *
 * Adding a new adapter:
 *   1. Create src/ui/adapters/mytool_adapter.js
 *   2. Add entry to REGISTRY below
 */

const NmapAdapter    = require('./nmap_adapter');
const OsintAdapter   = require('./osint_adapter');
const GenericAdapter = require('./generic_adapter');

const REGISTRY = {
    sovereign_recon:  NmapAdapter,
    web_recon:        GenericAdapter,
    sql_injection:    GenericAdapter,
    xss_hunter:       GenericAdapter,
    osint_engine:     OsintAdapter,
    exploit_generator: GenericAdapter,
    auto_refactor:    GenericAdapter,
    code_auditor:     GenericAdapter,
    git_nexus:        GenericAdapter,
    report_generator: GenericAdapter,
    identity_sync:    GenericAdapter,
    bounty_hunter:    GenericAdapter,
    wealth_tracker:   GenericAdapter,
    neocortex_vision: GenericAdapter,
    local_ai_inference: GenericAdapter,
    swarm_orchestrator: GenericAdapter,
    memory_service:   GenericAdapter,
    crypto_miner:     GenericAdapter,
    browser_cua:      GenericAdapter,
    voice_interface:  GenericAdapter,
};

// Cache instances per tool_id
const _instances = new Map();

/**
 * Get an adapter instance for a given tool_id.
 * @param {string} toolId
 * @returns {BaseAdapter}
 */
function getAdapter(toolId) {
    if (_instances.has(toolId)) return _instances.get(toolId);
    const AdapterClass = REGISTRY[toolId] || GenericAdapter;
    const instance = new AdapterClass(toolId);
    _instances.set(toolId, instance);
    return instance;
}

/**
 * Parse a line using the appropriate adapter.
 * @param {string} toolId
 * @param {string} line
 * @returns {{ type: string, data: any }}
 */
function parse(toolId, line) {
    return getAdapter(toolId).parse(line);
}

module.exports = { getAdapter, parse };
