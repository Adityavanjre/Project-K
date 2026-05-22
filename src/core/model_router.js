/**
 * KALI Model Router — v1.0
 *
 * Maps task types and natural language intent → best model ID.
 * Prefers already-warm models to avoid reload latency.
 * Falls back to registry default when no match.
 *
 * Usage:
 *   const router  = require('./model_router');
 *   const modelId = router.route('coding');
 *   const taskType= router.classifyIntent('write me a reverse shell in python');
 */

const fs   = require('fs');
const path = require('path');

const REGISTRY_FILE = path.join(__dirname, 'model_registry.json');

function loadRegistry() {
    return JSON.parse(fs.readFileSync(REGISTRY_FILE, 'utf-8'));
}

// ─── INTENT CLASSIFIER ────────────────────────────────────────────────────────
// Maps natural language keywords → task_type string.
// No LLM required — pure keyword scoring.

const INTENT_MAP = [
    // Coding / Engineering
    { keywords: ['code', 'write', 'function', 'script', 'program', 'python', 'javascript', 'class', 'debug', 'fix bug', 'syntax'], task: 'coding' },
    { keywords: ['refactor', 'optimize', 'rewrite', 'clean up', 'improve code', 'evolve'], task: 'refactor' },
    { keywords: ['audit', 'review code', 'check code', 'semgrep', 'static analysis'], task: 'audit' },

    // Security / Offensive
    { keywords: ['exploit', 'payload', 'shellcode', 'bypass', 'injection', 'reverse shell', 'poc', 'vulnerability', 'scan', 'recon', 'port'], task: 'exploit' },
    { keywords: ['pentest', 'penetration', 'hack', 'attack', 'offensive', 'red team', 'nmap', 'vuln'], task: 'pentest' },
    { keywords: ['uncensored', 'no filter', 'omega', 'unrestricted', 'sovereign mode'], task: 'uncensored' },

    // Research / Intelligence
    { keywords: ['research', 'osint', 'gather information', 'investigate', 'whois', 'shodan'], task: 'research' },
    { keywords: ['report', 'document', 'summarize findings', 'write report', 'generate report'], task: 'report' },
    { keywords: ['science', 'analysis', 'experiment', 'hypothesis', 'data'], task: 'science' },

    // Fast / Classification
    { keywords: ['quick', 'fast', 'short answer', 'one line', 'classify', 'yes or no'], task: 'fast' },
    { keywords: ['summarize', 'summary', 'tldr', 'brief'], task: 'fast' },

    // Reasoning / Planning
    { keywords: ['plan', 'strategy', 'roadmap', 'how to', 'explain', 'reason', 'think', 'analyze'], task: 'reasoning' },
    { keywords: ['mission', 'goal', 'objective', 'steps'], task: 'planning' },
];

/**
 * Classify natural language text into a task_type string.
 * @param {string} text
 * @returns {string} task_type
 */
function classifyIntent(text) {
    if (!text) return 'general';
    const lower = text.toLowerCase();

    let bestTask  = 'general';
    let bestScore = 0;

    for (const entry of INTENT_MAP) {
        let score = 0;
        for (const kw of entry.keywords) {
            if (lower.includes(kw)) score += kw.length; // Longer match = more specific
        }
        if (score > bestScore) {
            bestScore = score;
            bestTask  = entry.task;
        }
    }
    return bestTask;
}

// ─── MODEL SELECTOR ───────────────────────────────────────────────────────────

/**
 * Select the best model for a given task type.
 *
 * @param {string}      taskType          e.g. 'coding', 'exploit', 'general'
 * @param {string|null} preferredModelId  Override — skip selection if set
 * @param {Map}         warmModels        Set of currently warm model IDs (from ModelManager)
 * @returns {string}    model ID
 */
function route(taskType, preferredModelId = null, warmModels = new Set()) {
    const registry = loadRegistry();

    // Direct override
    if (preferredModelId) {
        const exists = registry.models.find(m => m.id === preferredModelId);
        if (exists) return preferredModelId;
    }

    // Find all models that support this task type
    const candidates = registry.models.filter(m =>
        m.task_types.some(t => t === taskType || taskType.includes(t) || t.includes(taskType))
    );

    if (candidates.length === 0) {
        // No match → fallback
        return registry.fallback_model;
    }

    // Prefer warm models (already loaded → no reload latency)
    const warmCandidates = candidates.filter(m => warmModels.has(m.id));
    if (warmCandidates.length > 0) {
        // Among warm, pick lowest priority number
        return warmCandidates.sort((a, b) => a.priority - b.priority)[0].id;
    }

    // No warm candidates — pick by priority
    return candidates.sort((a, b) => a.priority - b.priority)[0].id;
}

/**
 * Get the full model definition by ID.
 * @param {string} modelId
 * @returns {object|null}
 */
function getModelDef(modelId) {
    const registry = loadRegistry();
    return registry.models.find(m => m.id === modelId) || null;
}

/**
 * Get all model definitions.
 */
function getAllModels() {
    return loadRegistry().models;
}

/**
 * Get registry config (fallback, defaults, URLs).
 */
function getConfig() {
    const r = loadRegistry();
    let ollamaBase = r.ollama_base_url;

    // 🔱 SOVEREIGN REGISTRY OVERRIDE
    try {
        const configPath = path.join(__dirname, '../../config/config.json');
        if (fs.existsSync(configPath)) {
            const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
            ollamaBase = config.sovereign?.endpoints?.ollama || ollamaBase;
        }
    } catch (e) {}

    return {
        fallback_model:     r.fallback_model,
        default_task_type:  r.default_task_type,
        ollama_base_url:    ollamaBase,
        warm_timeout_ms:    r.warm_timeout_ms,
        query_timeout_ms:   r.query_timeout_ms
    };
}

module.exports = { route, classifyIntent, getModelDef, getAllModels, getConfig };
