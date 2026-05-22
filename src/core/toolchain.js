/**
 * KALI Toolchain Executor — v1.0
 *
 * Runs multi-step tool pipelines defined in toolchains.json.
 * Propagates context (facts) between steps.
 * Handles retries, fallback tool switching, and failure notification.
 *
 * Events emitted via TerminalBridge:
 *   chain_start       — { chain_id, chain_name, total_steps, args }
 *   chain_step        — { chain_id, step, tool_id, label, attempt }
 *   chain_step_done   — { chain_id, step, tool_id, facts, duration_ms }
 *   chain_step_failed — { chain_id, step, tool_id, error, action }
 *   chain_done        — { chain_id, total_steps, all_facts, duration_ms }
 *   chain_aborted     — { chain_id, step, reason }
 */

const fs            = require('fs');
const path          = require('path');
const ResourceManager = require('./resource_manager');
const ContextEngine  = require('./context_engine');
const MemoryService  = require('./memory_service');
const ModelManager   = require('./model_manager');
const ModelRouter    = require('./model_router');

// Lazy-load TerminalBridge to avoid circular require issues
function getBridge() {
    try { return require('../ui/terminal_bridge'); }
    catch (_) { return null; }
}

const CHAINS_FILE = path.join(__dirname, 'toolchains.json');

// ─── OUTPUT BUFFER ────────────────────────────────────────────────────────────
// Collects raw output lines per tool_id during execution for fact extraction
const outputBuffers = new Map(); // tool_id → string[]

function startBuffering(toolId) {
    outputBuffers.set(toolId, []);
}

function appendToBuffer(toolId, line) {
    const buf = outputBuffers.get(toolId);
    if (buf && buf.length < 1000) buf.push(line);
}

function flushBuffer(toolId) {
    const buf = outputBuffers.get(toolId) || [];
    outputBuffers.delete(toolId);
    return buf;
}

// ─── CHAIN RESOLUTION ────────────────────────────────────────────────────────

function loadChains() {
    const raw = fs.readFileSync(CHAINS_FILE, 'utf-8');
    return JSON.parse(raw).chains;
}

/**
 * List all defined chains.
 */
function listChains() {
    return loadChains().map(c => ({
        id:                 c.id,
        name:               c.name,
        description:        c.description,
        trigger_keywords:   c.trigger_keywords,
        step_count:         c.steps.length,
        estimated_duration: c.estimated_duration
    }));
}

/**
 * Match an intent string to a defined chain.
 * @param {string} intent 
 */
function resolveChain(intent) {
    if (!intent) return null;
    const chains = loadChains();
    const lower = intent.toLowerCase();
    return chains.find(c => 
        c.id.toLowerCase() === lower || 
        (c.trigger_keywords && c.trigger_keywords.some(kw => lower.includes(kw.toLowerCase())))
    );
}

/**
 * Execute a chain by ID.
 * @param {string} chainId 
 * @param {Object} args 
 */
async function executeChain(chainId, args = {}) {
    const chains = loadChains();
    const chain = chains.find(c => c.id === chainId);
    if (!chain) throw new Error(`Chain not found: ${chainId}`);
    return _runChain(chainId, 'static', chain.steps, args, null);
}

// ─── CHAIN EXECUTOR ───────────────────────────────────────────────────────────

/**
 * Execute a strategy plan (dynamic or static)
 * @param {Object} plan { type, steps, plan_id }
 * @param {Object} baseArgs 
 * @param {Object} goalObj { goal, priority }
 */
async function executePlan(plan, baseArgs = {}, goalObj = null) {
    if (!plan || !plan.steps || plan.steps.length === 0) {
        throw new Error('Invalid or empty execution plan');
    }
    return _runChain(plan.plan_id, plan.type, plan.steps, baseArgs, goalObj);
}

/**
 * Internal chain runner.
 */
async function _runChain(chainId, planType, steps, baseArgs, goalObj) {
    const bridge      = getBridge();
    const chainStart  = Date.now();
    let   accFacts    = { ...baseArgs };
    const stepResults = [];
    const priority    = goalObj ? goalObj.priority : 'medium';

    console.log(`[Toolchain] Starting ${planType} chain: ${chainId} (${steps.length} steps)`);

    // Emit chain_start
    _emit(bridge, 'chain_start', {
        chain_id:    chainId,
        chain_name:  `Plan: ${chainId}`,
        total_steps: steps.length,
        args:        baseArgs
    });

    for (let stepIdx = 0; stepIdx < steps.length; stepIdx++) {
        const stepDef  = steps[stepIdx];
        const stepNum  = stepIdx + 1;
        let   toolId   = stepDef.tool_id;
        let   retries  = stepDef.retry ?? 1;
        let   success  = false;
        let   lastError= '';
        let   stepFacts= {};

        // Emit chain_step
        _emit(bridge, 'chain_step', {
            chain_id:    chainId,
            step:        stepNum,
            total_steps: steps.length,
            tool_id:     toolId,
            label:       stepDef.label || toolId
        });

        // Attempt execution with retries
        for (let attempt = 1; attempt <= retries + 1; attempt++) {
            if (attempt > 1) {
                console.log(`[Toolchain] Retry ${attempt - 1}/${retries} for ${toolId}`);
                _emit(bridge, 'chain_step_failed', {
                    chain_id: chainId, step: stepNum, tool_id: toolId,
                    error: lastError, action: `Retry ${attempt - 1}/${retries}`
                });
                await sleep(1500); // Brief pause before retry
            }

            const stepStart = Date.now();
            startBuffering(toolId);

            // Build enriched args for this step from accumulated facts
            const enrichedArgs = ContextEngine.buildChainArgs(accFacts, toolId, baseArgs);

            // Hook into RuntimeManager output via event interception
            _interceptOutput(toolId);

            const result = await ResourceManager.requestExecution(toolId, enrichedArgs, priority);
            const duration = Date.now() - stepStart;

            if (result.status === 'success') {
                // Wait for process to emit some output (short poll)
                await waitForOutput(toolId, stepDef.timeout_ms || 30000);
            }

            const outputLines = flushBuffer(toolId);

            if (result.status === 'success' || result.status === 'started') {
                // Extract facts from this step's output (regex based)
                stepFacts = ContextEngine.extractOutputFacts(toolId, outputLines);
                
                // [NEW] Tool Intelligence Wrapper — AI Output Analysis
                let aiConfidence = 0.8;
                let aiSuggestions = [];
                if (outputLines.length > 0) {
                    try {
                        const fastModel = ModelRouter.route('fast');
                        const prompt = `Analyze this tool output. Is it successful? Give confidence (0-1) and next suggested tools.
Output JSON only: {"success":bool, "confidence":float, "next_suggestions":["tool_id1"]}.
Output: ${outputLines.slice(0, 20).join('\n')}`;
                        const aiRes = await ModelManager.query(fastModel, [{role: 'user', content: prompt}], {temperature: 0.1});
                        if (aiRes.success) {
                            let cleanJson = aiRes.content.trim().replace(/^```json/i, '').replace(/^```/, '').replace(/```$/, '').trim();
                            const parsed = JSON.parse(cleanJson);
                            aiConfidence = parsed.confidence || 0.8;
                            aiSuggestions = parsed.next_suggestions || [];
                            if (parsed.success === false && aiConfidence > 0.8) {
                                // AI strongly believes the tool failed conceptually despite exit code 0
                                lastError = "AI marked output as conceptual failure";
                                continue; // Trigger retry loop
                            }
                        }
                    } catch (e) { /* silent fail for AI wrapper */ }
                }

                stepFacts._ai_confidence = aiConfidence;
                if (aiSuggestions.length > 0) stepFacts._next_suggestions = aiSuggestions;

                accFacts  = ContextEngine.mergeFacts(accFacts, stepFacts);

                // Record in memory
                MemoryService.record({
                    tool_id:        toolId,
                    args:           enrichedArgs,
                    exit_code:      0,
                    duration_ms:    duration,
                    output_summary: outputLines.slice(0, 3).join(' | '),
                    facts:          stepFacts,
                    chain_id:       chainId,
                    chain_step:     stepNum
                });

                success = true;
                _emit(bridge, 'chain_step_done', {
                    chain_id:    chainId,
                    step:        stepNum,
                    tool_id:     toolId,
                    label:       stepDef.label || toolId,
                    facts:       stepFacts,
                    duration_ms: duration
                });
                break;

            } else {
                lastError = result.data || 'Unknown error';
            }
        }

        // Retries exhausted — try fallback tool
        if (!success && stepDef.fallback) {
            console.log(`[Toolchain] Switching to fallback: ${stepDef.fallback}`);
            _emit(bridge, 'chain_step_failed', {
                chain_id: chainId, step: stepNum, tool_id: toolId,
                error: lastError, action: `Switching to fallback: ${stepDef.fallback}`
            });

            const fbResult = await ResourceManager.requestExecution(stepDef.fallback, baseArgs, priority);
            if (fbResult.status === 'success') {
                await waitForOutput(stepDef.fallback, 20000);
                const fbLines = flushBuffer(stepDef.fallback);
                stepFacts = ContextEngine.extractOutputFacts(stepDef.fallback, fbLines);
                accFacts  = ContextEngine.mergeFacts(accFacts, stepFacts);

                MemoryService.record({
                    tool_id: stepDef.fallback, args: baseArgs, exit_code: 0,
                    duration_ms: 0, facts: stepFacts, chain_id: chainId, chain_step: stepNum
                });
                success = true;
                toolId = stepDef.fallback;

                _emit(bridge, 'chain_step_done', {
                    chain_id: chainId, step: stepNum, tool_id: toolId,
                    label: `[FALLBACK] ${stepDef.fallback}`, facts: stepFacts, duration_ms: 0
                });
            }
        }

        // All recovery options exhausted
        if (!success) {
            console.warn(`[Toolchain] Step ${stepNum} failed permanently: ${toolId}`);
            _emit(bridge, 'chain_step_failed', {
                chain_id: chainId, step: stepNum, tool_id: toolId,
                error: lastError, action: 'Skipping — no fallback available'
            });
            // Non-blocking: continue chain with best available facts
        }

        stepResults.push({ step: stepNum, tool_id: toolId, success, facts: stepFacts });
    }

    const totalDuration = Date.now() - chainStart;
    const allSucceeded  = stepResults.every(s => s.success);

    _emit(bridge, 'chain_done', {
        chain_id:      chainId,
        chain_name:    `Plan: ${chainId}`,
        total_steps:   steps.length,
        steps_passed:  stepResults.filter(s => s.success).length,
        all_facts:     accFacts,
        duration_ms:   totalDuration,
        success:       allSucceeded
    });

    console.log(`[Toolchain] Plan '${chainId}' complete in ${(totalDuration / 1000).toFixed(1)}s`);

    return {
        chain_id:     chainId,
        chain_name:   `Plan: ${chainId}`,
        steps:        stepResults,
        all_facts:    accFacts,
        duration_ms:  totalDuration,
        success:      allSucceeded
    };
}

// ─── HELPERS ─────────────────────────────────────────────────────────────────

function _emit(bridge, event, data) {
    if (!bridge) return;
    try {
        bridge._send({ tool_id: `chain:${data.chain_id}`, line: JSON.stringify({ event, ...data }), output_type: event, status: 'info', timestamp: new Date().toISOString() });
    } catch (_) {}
}

function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}

/**
 * Intercept RuntimeManager output events for a given toolId
 * and write them into our local output buffer.
 */
function _interceptOutput(toolId) {
    // RuntimeManager emitOutput calls TerminalBridge.emit('output', payload)
    // We hook into the bridge's own EventEmitter to capture lines
    const bridge = getBridge();
    if (!bridge) return;

    const handler = (payload) => {
        if (payload.source === toolId) {
            const lines = (payload.data || '').split('\n').filter(l => l.trim());
            lines.forEach(l => appendToBuffer(toolId, l));
        }
    };

    bridge.once('output', handler); // Only intercept once to avoid accumulation
    bridge.on('output', handler);

    // Remove listener after timeout to prevent memory leaks
    setTimeout(() => {
        bridge.removeListener('output', handler);
    }, 120000);
}

/**
 * Wait for a tool's output buffer to receive at least one line,
 * or until timeout (for fast-exit tools).
 */
function waitForOutput(toolId, timeoutMs = 5000) {
    return new Promise(resolve => {
        const start  = Date.now();
        const check  = setInterval(() => {
            const buf = outputBuffers.get(toolId) || [];
            if (buf.length > 0 || Date.now() - start > timeoutMs) {
                clearInterval(check);
                resolve();
            }
        }, 200);
    });
}

module.exports = { resolveChain, listChains, executeChain, executePlan };
