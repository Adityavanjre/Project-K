/**
 * KALI Memory Service — v1.0
 *
 * Persistent execution log with LRU eviction.
 * Tracks per-tool effectiveness metrics.
 * Zero external dependencies — flat JSON file on disk.
 *
 * Schema per record:
 * {
 *   id:            string   (uuid-style)
 *   tool_id:       string
 *   args:          object
 *   exit_code:     number   (0 = success)
 *   duration_ms:   number
 *   output_summary:string   (first meaningful output line)
 *   facts:         object   (structured facts extracted by ContextEngine)
 *   timestamp:     ISO 8601
 *   chain_id:      string | null
 *   chain_step:    number | null
 *   domain:        string | null
 * }
 */

const fs   = require('fs');
const path = require('path');

const MEMORY_FILE = path.join(__dirname, 'execution_memory.json');
const MAX_RECORDS = 500;

// ─── INIT ─────────────────────────────────────────────────────────────────────
function loadMemory() {
    try {
        if (fs.existsSync(MEMORY_FILE)) {
            return JSON.parse(fs.readFileSync(MEMORY_FILE, 'utf-8'));
        }
    } catch (_) {}
    return { records: [], metrics: {} };
}

function saveMemory(state) {
    try {
        fs.writeFileSync(MEMORY_FILE, JSON.stringify(state, null, 2), 'utf-8');
    } catch (e) {
        console.error('[MemoryService] Save failed:', e.message);
    }
}

// In-memory state (loaded once, flushed to disk on writes)
let _state = loadMemory();

// ─── SIMPLE ID GENERATOR ──────────────────────────────────────────────────────
function genId() {
    return Date.now().toString(36) + Math.random().toString(36).slice(2, 7);
}

// ─── PUBLIC API ───────────────────────────────────────────────────────────────

/**
 * Record a completed tool execution.
 * @param {object} execution
 */
function record(execution) {
    const entry = {
        id:             genId(),
        tool_id:        execution.tool_id   || 'unknown',
        args:           execution.args       || {},
        exit_code:      execution.exit_code  ?? -1,
        duration_ms:    execution.duration_ms || 0,
        output_summary: (execution.output_summary || '').slice(0, 200),
        facts:          execution.facts      || {},
        timestamp:      new Date().toISOString(),
        chain_id:       execution.chain_id   || null,
        chain_step:     execution.chain_step ?? null,
        domain:         execution.domain     || 'development'
    };

    // LRU eviction: remove oldest if over limit
    _state.records.push(entry);
    if (_state.records.length > MAX_RECORDS) {
        _state.records = _state.records.slice(_state.records.length - MAX_RECORDS);
    }

    // Update metrics
    const toolId = entry.tool_id;
    if (!_state.metrics[toolId]) {
        _state.metrics[toolId] = { runs: 0, successes: 0, failures: 0, total_duration_ms: 0 };
    }
    const m = _state.metrics[toolId];
    m.runs++;
    m.total_duration_ms += entry.duration_ms;
    if (entry.exit_code === 0) m.successes++;
    else m.failures++;

    saveMemory(_state);
    return entry;
}

/**
 * Get recent execution history.
 * @param {string|null} toolId   Filter by tool (optional)
 * @param {number}      limit    Max records to return
 * @param {string|null} domain   Filter by domain (optional)
 */
function getHistory(toolId = null, limit = 20, domain = null) {
    let records = _state.records;
    if (domain) records = records.filter(r => r.domain === domain);
    if (toolId) records = records.filter(r => r.tool_id === toolId);
    return records.slice(-limit).reverse(); // Most recent first
}

/**
 * Get tool effectiveness metrics.
 */
function getMetrics() {
    const result = {};
    for (const [toolId, m] of Object.entries(_state.metrics)) {
        result[toolId] = {
            runs:       m.runs,
            successes:  m.successes,
            failures:   m.failures,
            success_rate: m.runs > 0 ? parseFloat((m.successes / m.runs).toFixed(3)) : 0,
            avg_duration_ms: m.runs > 0 ? Math.round(m.total_duration_ms / m.runs) : 0
        };
    }
    return result;
}

/**
 * Get past facts about a specific target (IP, domain, etc.)
 * @param {string} target
 * @param {string|null} domain Filter context strictly by domain
 */
function getContext(target, domain = null) {
    if (!target) return [];
    const normalized = target.toLowerCase();
    return _state.records
        .filter(r => {
            if (domain && r.domain !== domain) return false;
            const argsStr = JSON.stringify(r.args).toLowerCase();
            return argsStr.includes(normalized);
        })
        .slice(-10)
        .reverse();
}

/**
 * Get the best performing tool for a given category (by success_rate).
 * Used by FailureHandler to suggest alternatives.
 */
function getBestTool(candidateIds) {
    const metrics = getMetrics();
    let best = null;
    let bestScore = -1;
    for (const id of candidateIds) {
        const m = metrics[id];
        if (!m) continue; // Never run — treat as unknown
        if (m.success_rate > bestScore) {
            bestScore = m.success_rate;
            best = id;
        }
    }
    return best;
}

/**
 * Clear all memory (destructive).
 */
function clearMemory() {
    _state = { records: [], metrics: {} };
    saveMemory(_state);
}

module.exports = { record, getHistory, getMetrics, getContext, getBestTool, clearMemory };
