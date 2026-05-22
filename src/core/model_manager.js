/**
 * KALI Model Manager — v1.0
 *
 * Manages the lifecycle of Ollama models:
 *   - Warm-up (load into VRAM) via HTTP — no CMD windows
 *   - Query (inference) via Ollama /api/chat
 *   - Idle-timeout auto-stop to free VRAM
 *   - Health check + live status tracking
 *
 * Model states:
 *   idle    — Not loaded in Ollama (no VRAM)
 *   loading — Warm-up HTTP request in flight
 *   warm    — Loaded, ready for inference
 *   error   — Failed to load / Ollama unreachable
 *
 * Zero subprocess / CMD windows — all via Ollama HTTP API.
 */

const path = require('path');
const fs = require('fs');
const http = require('http');
const https = require('https');
const ModelRouter = require('./model_router');

let OLLAMA_BASE;
try {
    const configPath = path.join(__dirname, '../../config/config.json');
    const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    OLLAMA_BASE = config.sovereign?.endpoints?.ollama;
} catch (e) {
    console.warn("[ModelManager] Failed to load config.json for OLLAMA_BASE.");
}

// ─── STATE STORE ──────────────────────────────────────────────────────────────
// model_id → { state, idleTimer, lastUsed, requestCount, errorMsg }

const modelState = new Map();

function getState(modelId) {
    if (!modelState.has(modelId)) {
        modelState.set(modelId, {
            state:        'idle',
            idleTimer:    null,
            lastUsed:     null,
            requestCount: 0,
            errorMsg:     null
        });
    }
    return modelState.get(modelId);
}

function setState(modelId, updates) {
    const s = getState(modelId);
    Object.assign(s, updates);
}

// ─── HTTP HELPERS ─────────────────────────────────────────────────────────────

function httpPost(url, body, timeoutMs = 30000) {
    return new Promise((resolve, reject) => {
        const parsed  = new URL(url);
        const payload = JSON.stringify(body);
        const lib     = parsed.protocol === 'https:' ? https : http;

        const req = lib.request({
            hostname: parsed.hostname,
            port:     parsed.port,
            path:     parsed.pathname + parsed.search,
            method:   'POST',
            headers:  { 'Content-Type': 'application/json', 'Content-Length': Buffer.byteLength(payload) }
        }, (res) => {
            let data = '';
            res.on('data', c => { data += c; });
            res.on('end', () => {
                try   { resolve({ status: res.statusCode, body: JSON.parse(data) }); }
                catch (_) { resolve({ status: res.statusCode, body: data }); }
            });
        });

        req.setTimeout(timeoutMs, () => { req.destroy(); reject(new Error('Timeout')); });
        req.on('error', reject);
        req.write(payload);
        req.end();
    });
}

function httpGet(url, timeoutMs = 5000) {
    return new Promise((resolve, reject) => {
        const parsed = new URL(url);
        const lib    = parsed.protocol === 'https:' ? https : http;

        const req = lib.get({
            hostname: parsed.hostname,
            port:     parsed.port,
            path:     parsed.pathname + parsed.search
        }, (res) => {
            let data = '';
            res.on('data', c => { data += c; });
            res.on('end', () => {
                try   { resolve({ status: res.statusCode, body: JSON.parse(data) }); }
                catch (_) { resolve({ status: res.statusCode, body: data }); }
            });
        });

        req.setTimeout(timeoutMs, () => { req.destroy(); reject(new Error('Timeout')); });
        req.on('error', reject);
    });
}

// ─── IDLE TIMER ───────────────────────────────────────────────────────────────

function resetIdleTimer(modelId) {
    const s      = getState(modelId);
    const def    = ModelRouter.getModelDef(modelId);
    const mins   = def?.idle_timeout_min ?? 10;

    if (s.idleTimer) clearTimeout(s.idleTimer);

    s.idleTimer = setTimeout(async () => {
        console.log(`[ModelManager] Idle timeout: stopping ${modelId}`);
        await stopModel(modelId);
    }, mins * 60 * 1000);
}

// ─── PUBLIC API ───────────────────────────────────────────────────────────────

/**
 * Check Ollama service health.
 * @returns {Promise<{ healthy: boolean, models: string[] }>}
 */
async function checkOllamaHealth() {
    try {
        const res = await httpGet(`${OLLAMA_BASE}/api/tags`, 5000);
        if (res.status === 200) {
            const models = (res.body?.models || []).map(m => m.name);
            return { healthy: true, models };
        }
        return { healthy: false, models: [] };
    } catch (_) {
        return { healthy: false, models: [] };
    }
}

/**
 * Ensure a model is warm (loaded in Ollama VRAM).
 * Uses a lightweight HTTP warm-up — no CMD subprocess.
 * @param {string} modelId
 * @returns {Promise<boolean>} success
 */
async function ensureRunning(modelId) {
    const s   = getState(modelId);
    const def = ModelRouter.getModelDef(modelId);
    if (!def) return false;

    if (s.state === 'warm') {
        resetIdleTimer(modelId);
        return true;
    }

    if (s.state === 'loading') {
        // Wait for loading to complete (poll)
        return new Promise(resolve => {
            const check = setInterval(() => {
                if (getState(modelId).state !== 'loading') {
                    clearInterval(check);
                    resolve(getState(modelId).state === 'warm');
                }
            }, 300);
            setTimeout(() => { clearInterval(check); resolve(false); }, cfg.warm_timeout_ms || 30000);
        });
    }

    // Start warm-up
    setState(modelId, { state: 'loading', errorMsg: null });
    console.log(`[ModelManager] Warming: ${def.name} (${def.ollama_model})`);

    try {
        // Ollama warms a model when you send a generate request with keep_alive
        const res = await httpPost(
            `${OLLAMA_BASE}/api/generate`,
            {
                model:      def.ollama_model,
                prompt:     '',           // Empty prompt — just loads model
                keep_alive: '10m',        // Keep in VRAM for 10 minutes
                stream:     false
            },
            cfg.warm_timeout_ms || 30000
        );

        if (res.status === 200) {
            setState(modelId, { state: 'warm', lastUsed: new Date(), errorMsg: null });
            resetIdleTimer(modelId);
            console.log(`[ModelManager] ${def.name} is warm ✓`);
            return true;
        } else {
            setState(modelId, { state: 'error', errorMsg: `HTTP ${res.status}` });
            return false;
        }
    } catch (err) {
        setState(modelId, { state: 'error', errorMsg: err.message });
        console.error(`[ModelManager] Warm-up failed for ${modelId}: ${err.message}`);
        return false;
    }
}

/**
 * Run inference against a model.
 * Auto-warms if needed.
 *
 * @param {string}   modelId
 * @param {Array}    messages    OpenAI-style messages array
 * @param {object}   options     { temperature, max_tokens, stream }
 * @returns {Promise<{ success: boolean, content: string, model: string, duration_ms: number }>}
 */
async function query(modelId, messages, options = {}) {
    const def = ModelRouter.getModelDef(modelId);
    if (!def) return { success: false, content: 'Unknown model: ' + modelId };

    // Phase 11: Strict Local Enforcement
    if (!def.ollama_model && !def.local_binary) {
        console.warn(`[ModelManager] BLOCKED: External API model request detected (${modelId}). KALI is strictly local.`);
        return { success: false, content: `Blocked: KALI operates on local models only. Cannot route to external API.` };
    }

    // Ensure model is warm
    const ready = await ensureRunning(modelId);
    if (!ready) {
        return { success: false, content: `Model ${def.name} failed to load. Is Ollama running?` };
    }

    const startTime = Date.now();
    const s         = getState(modelId);
    s.requestCount++;
    s.lastUsed = new Date();
    resetIdleTimer(modelId);

    try {
        const res = await httpPost(
            `${OLLAMA_BASE}/api/chat`,
            {
                model:    def.ollama_model,
                messages,
                stream:   false,
                options:  {
                    temperature:  options.temperature ?? 0.7,
                    num_predict:  options.max_tokens  ?? 2048
                }
            },
            cfg.query_timeout_ms || 120000
        );

        const duration = Date.now() - startTime;

        if (res.status === 200 && res.body?.message?.content) {
            // Phase 10: Track model performance
            const Optimizer = require('./optimizer');
            Optimizer.logExecution(`model:${modelId}`, duration, true);

            return {
                success:     true,
                content:     res.body.message.content,
                model:       def.name,
                model_id:    modelId,
                ollama_model: def.ollama_model,
                duration_ms: duration,
                tokens:      res.body.eval_count || 0
            };
        }

        const Optimizer = require('./optimizer');
        Optimizer.logExecution(`model:${modelId}`, duration, false, `HTTP ${res.status}`);

        return {
            success:     false,
            content:     `Ollama error: ${JSON.stringify(res.body)}`,
            duration_ms: duration
        };

    } catch (err) {
        return {
            success:     false,
            content:     `Query failed: ${err.message}`,
            duration_ms: Date.now() - startTime
        };
    }
}

/**
 * Stop a model (unload from VRAM).
 * Uses Ollama's keep_alive=0 trick.
 * @param {string} modelId
 */
async function stopModel(modelId) {
    const def = ModelRouter.getModelDef(modelId);
    if (!def) return;

    const s = getState(modelId);
    if (s.idleTimer) { clearTimeout(s.idleTimer); s.idleTimer = null; }

    try {
        // Sending keep_alive: 0 tells Ollama to unload the model from VRAM
        await httpPost(
            `${OLLAMA_BASE}/api/generate`,
            { model: def.ollama_model, prompt: '', keep_alive: 0, stream: false },
            5000
        );
        setState(modelId, { state: 'idle', errorMsg: null });
        console.log(`[ModelManager] Stopped: ${def.name}`);
    } catch (err) {
        // If Ollama isn't reachable, just mark idle
        setState(modelId, { state: 'idle' });
    }
}

/**
 * Get live status of all registered models.
 * @returns {Array}
 */
function getStatus() {
    const allModels = ModelRouter.getAllModels();
    return allModels.map(def => {
        const s = modelState.get(def.id) || {};
        return {
            id:            def.id,
            name:          def.name,
            ollama_model:  def.ollama_model,
            state:         s.state || 'idle',
            task_types:    def.task_types,
            last_used:     s.lastUsed || null,
            request_count: s.requestCount || 0,
            error:         s.errorMsg || null,
            icon:          def.icon,
            color:         def.color,
            description:   def.description,
            idle_timeout_min: def.idle_timeout_min
        };
    });
}

/**
 * Get the set of currently warm model IDs.
 * Used by ModelRouter to prefer warm models.
 * @returns {Set<string>}
 */
function getWarmModels() {
    const warm = new Set();
    modelState.forEach((s, id) => { if (s.state === 'warm') warm.add(id); });
    return warm;
}

module.exports = {
    checkOllamaHealth,
    ensureRunning,
    query,
    stopModel,
    getStatus,
    getWarmModels
};
