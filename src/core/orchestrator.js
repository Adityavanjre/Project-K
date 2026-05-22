/**
 * KALI Orchestration Service — v3.0 SOVEREIGN
 * Centralized API gateway with Memory, Context, and Toolchain support.
 *
 * Routes:
 *   POST /orchestrate   — Intent analysis → single tool or chain execution
 *   POST /chain         — Execute a named chain or auto-resolve from intent
 *   GET  /chains        — List all defined toolchains
 *   GET  /memory/metrics— Tool effectiveness scores
 *   POST /stop          — Stop a running tool by ID
 *   GET  /health        — Heartbeat
 */

const RuntimeManager = require('./runtime_manager');
const ContextEngine  = require('./context_engine');
const MemoryService  = require('./memory_service');
const Toolchain      = require('./toolchain');
const TerminalBridge = require('../ui/terminal_bridge');
const ModelManager   = require('./model_manager');
const ModelRouter    = require('./model_router');
const GoalEngine     = require('./goal_engine');
const StrategyPlanner= require('./strategy_planner');
const MissionEngine  = require('./mission_engine');
const MissionRunner  = require('./mission_runner');
const Scheduler      = require('./scheduler');
const SystemMonitor  = require('./system_monitor');
const ExecutionGovernor = require('./execution_governor');
const AuditLogger    = require('./audit_logger');
const DomainEngine   = require('./domain_engine');
const PersonaManager = require('./persona_manager');
const CacheManager   = require('./cache_manager');
const Optimizer      = require('./optimizer');
const Purifier       = require('./purifier');
const SelfAuditor    = require('./self_auditor');
const EventBus       = require('./shared/event_bus');
const IntentEngine     = require('./intent_engine');
const http           = require('http');

let PORT = 8002;
let config = {};
try {
    config = JSON.parse(require('fs').readFileSync(require('path').join(__dirname, '../../config/config.json'), 'utf8'));
    if (config.orchestrator && config.orchestrator.port) {
        PORT = config.orchestrator.port;
    }
} catch (e) {
    console.warn("[Orchestrator] Failed to load config.json, using default port 8002.");
}
const activeProcesses = new Map();

// ─── CORS ─────────────────────────────────────────────────────────────────────
function setCORS(res) {
    res.setHeader('Access-Control-Allow-Origin',  '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
    res.setHeader('Content-Type', 'application/json');
}

// ─── BODY PARSER ──────────────────────────────────────────────────────────────
function parseBody(req) {
    return new Promise((resolve, reject) => {
        let body = '';
        req.on('data', chunk => { body += chunk.toString(); });
        req.on('end', () => {
            try   { resolve(JSON.parse(body || '{}')); }
            catch (_) { resolve({}); }
        });
        req.on('error', reject);
    });
}

// ─── SERVER ───────────────────────────────────────────────────────────────────
const server = http.createServer(async (req, res) => {
    setCORS(res);

    if (req.method === 'OPTIONS') { res.writeHead(204); res.end(); return; }

    const url = req.url.split('?')[0];
    
    // ── GET / (Root) + /api/health ──────────────────────────────────────────
    if (req.method === 'GET' && (url === '/' || url === '' || url === '/api/health' || url === '/health')) {
        res.writeHead(200);
        res.end(JSON.stringify({ 
            status: 'success', 
            service: 'KALI Orchestrator', 
            version: '4.0.0 [PURIFIED]',
            uptime: Math.floor(process.uptime()),
            nodes: Object.keys(MissionRunner.nodes || {}).length || 42 
        }));
        return;
    }

    // ── POST /orchestrate ─────────────────────────────────────────────────────
    if (req.method === 'POST' && url === '/orchestrate') {
        try {
            const body    = await parseBody(req);
            const { message, args } = body;

            if (!message?.trim()) {
                res.writeHead(400);
                res.end(JSON.stringify({ status: 'error', data: 'message is required' }));
                return;
            }

            console.log(`[Orchestrator] Input: "${message}"`);

            // ── Phase 8: Domain & Persona Routing ─────────────────────────────
            const { domain, confidence: domainConf } = DomainEngine.detectDomain(message);
            const persona = PersonaManager.getPersona(domain);
            
            console.log(`[Orchestrator] Domain: ${domain} (${domainConf}) | Persona: ${persona.name}`);

            // ── Phase 10: Dynamic Caching ─────────────────────────────────────
            const cacheKey = `intent:${domain}:${message}`;
            const cachedResult = CacheManager.get(cacheKey);
            if (cachedResult) {
                console.log(`[Orchestrator] Cache HIT for query: ${message}`);
                res.end(JSON.stringify(cachedResult));
                return;
            }
            
            // Broadcast domain switch so UI and Memory can adapt
            EventBus.emit('domain:switched', { domain, persona: persona.name });

            // ── Phase 5: Goal Interpretation ──────────────────────────────────
            // Inject domain and persona into GoalEngine (assuming it passes it down or we just log it for now)
            const goalObj = await GoalEngine.interpretGoal(message);
            goalObj.domain = domain; // Tag the goal with the domain
            
            // ── Phase 11: Conversational AI Fallback Function ────────────────
            const routeToAI = async () => {
                const taskType = ModelRouter.classifyIntent(message);
                const modelId  = ModelRouter.route(taskType, args?.model || persona.model_preference);
                const def      = ModelRouter.getModelDef(modelId);
                
                console.log(`[Orchestrator] AI Routing: "${taskType}" -> ${modelId}`);
                
                const aiResult = await ModelManager.query(modelId, [
                    { role: 'user', content: message }
                ]);
                
                if (aiResult.success) {
                    MemoryService.record({
                        tool_id: `ai:${modelId}`,
                        args: { prompt: message, task_type: taskType },
                        exit_code: 0,
                        duration_ms: aiResult.duration_ms,
                        output_summary: `Tokens: ${aiResult.tokens}`,
                        domain: domain
                    });
                }
                
                const payload = {
                    status:   'success',
                    mode:     'ai',
                    provenance: 'EXECUTED_BY_KALI',
                    relay: 'RELAYED_BY_ANTIGRAVITY',
                    task_type: taskType,
                    model_id:  modelId,
                    model_name: def?.name,
                    response:  aiResult.content,
                    duration_ms: aiResult.duration_ms,
                    goal:      goalObj,
                    domain:    domain,
                    persona:   persona.name
                };

                // Phase 10: Cache AI Responses
                CacheManager.set(cacheKey, payload);

                res.end(JSON.stringify(payload));
            };

            if (!goalObj.actionable) {
                await routeToAI();
                return;
            }

            // ── Phase 5: Strategy Planning ────────────────────────────────────
            const plan = await StrategyPlanner.createPlan(goalObj);

            // ── Phase 6: Mission Creation ──────────────────────────────────────
            if (plan.steps && plan.steps.length > 0) {
                const mission = MissionEngine.createMission(goalObj, plan, args?.scheduled_for);

                res.end(JSON.stringify({
                    status:       'success',
                    mode:         'mission',
                    mission_id:   mission.id,
                    goal:         mission.goal,
                    priority:     mission.priority,
                    total_steps:  mission.steps.length,
                    status_str:   mission.status,
                    message:      `Mission created: ${mission.id}`,
                    domain:       domain,
                    persona:      persona.name
                }));
            } else {
                console.log(`[Orchestrator] No strict Outcome Loop found for intent. Falling back to AI.`);
                await routeToAI();
            }

        } catch (err) {
            console.error(`[Orchestrator] Error: ${err.message}`);
            res.writeHead(500);
            res.end(JSON.stringify({ status: 'error', data: err.message }));
        }
        return;
    }

    // ── POST /chain ───────────────────────────────────────────────────────────
    if (req.method === 'POST' && url === '/chain') {
        try {
            const body    = await parseBody(req);
            const { chain_id, intent, args } = body;

            if (!chain_id && !intent) {
                res.writeHead(400);
                res.end(JSON.stringify({ status: 'error', data: 'chain_id or intent required' }));
                return;
            }

            let targetChainId = chain_id;

            if (!targetChainId && intent) {
                const matched = Toolchain.resolveChain(intent);
                if (!matched) {
                    res.end(JSON.stringify({ status: 'success', data: 'No chain matched for intent', intent }));
                    return;
                }
                targetChainId = matched.id;
            }

            const chains  = Toolchain.listChains();
            const chainDef = chains.find(c => c.id === targetChainId);

            // Respond immediately, run chain in background
            res.end(JSON.stringify({
                status:      'success',
                mode:        'chain',
                chain_id:    targetChainId,
                chain_name:  chainDef?.name || targetChainId,
                total_steps: chainDef?.step_count || 0,
                message:     `Chain '${targetChainId}' executing in background`
            }));

            Toolchain.executeChain(targetChainId, args || {})
                .catch(e => console.error(`[Chain] Error: ${e.message}`));

        } catch (err) {
            res.writeHead(500);
            res.end(JSON.stringify({ status: 'error', data: err.message }));
        }
        return;
    }

    // ── GET /chains ───────────────────────────────────────────────────────────
    if (req.method === 'GET' && url === '/chains') {
        res.end(JSON.stringify({
            status: 'success',
            chains: Toolchain.listChains()
        }));
        return;
    }

    // ── GET /memory ───────────────────────────────────────────────────────────
    if (req.method === 'GET' && url.startsWith('/memory')) {
        const isMetrics = url === '/memory/metrics';

        if (isMetrics) {
            res.end(JSON.stringify({
                status:  'success',
                metrics: MemoryService.getMetrics()
            }));
        } else {
            const baseUrl = config.sovereign?.internal?.base_url;
            const params  = new URL(req.url, `${baseUrl}:${PORT}`);
            const toolId  = params.searchParams.get('tool_id') || null;
            const limit   = parseInt(params.searchParams.get('limit') || '20', 10);
            res.end(JSON.stringify({
                status:  'success',
                history: MemoryService.getHistory(toolId, limit)
            }));
        }
        return;
    }

    // ── GET /domain ───────────────────────────────────────────────────────────
    if (req.method === 'GET' && url.startsWith('/domain')) {
        const baseUrl = config.sovereign?.internal?.base_url;
        const params  = new URL(req.url, `${baseUrl}:${PORT}`);
        const targetDomain = params.searchParams.get('name');
        
        if (targetDomain === 'finance') {
            const FinanceEngine = require('./finance_engine');
            const data = await FinanceEngine.getBalances();
            res.end(JSON.stringify(data));
            return;
        } else if (targetDomain === 'identity_management') {
            const IdentityEngine = require('./identity_engine');
            const data = await IdentityEngine.getConnectedAccounts();
            res.end(JSON.stringify(data));
            return;
        }

        res.end(JSON.stringify({ status: 'success', data: null }));
        return;
    }

    // ── GET /status ───────────────────────────────────────────────────────────
    if (req.method === 'GET' && url === '/status') {
        res.end(JSON.stringify({
            status:          'active',
            port:            PORT,
            active_tools:    Array.from(activeProcesses.values()),
            active_count:    activeProcesses.size,
            uptime_seconds:  Math.floor(process.uptime()),
            memory_records:  MemoryService.getHistory(null, 1000).length
        }));
        return;
    }

    // ── GET /registry ─────────────────────────────────────────────────────────
    if (req.method === 'GET' && url === '/registry') {
        try {
            const registry = IntentEngine.getRegistry();
            res.end(JSON.stringify({ status: 'success', registry, count: registry.length }));
        } catch (err) {
            res.writeHead(500);
            res.end(JSON.stringify({ status: 'error', data: err.message }));
        }
        return;
    }

    // ── POST /stop ────────────────────────────────────────────────────────────
    if (req.method === 'POST' && url === '/stop') {
        try {
            const body    = await parseBody(req);
            const { tool_id } = body;
            if (!tool_id) {
                res.writeHead(400);
                res.end(JSON.stringify({ status: 'error', data: 'tool_id required' }));
                return;
            }
            const result = RuntimeManager.stopTool(tool_id);
            if (result.status === 'success') activeProcesses.delete(tool_id);
            res.end(JSON.stringify(result));
        } catch (err) {
            res.writeHead(500);
            res.end(JSON.stringify({ status: 'error', data: err.message }));
        }
        return;
    }

    // ── GET /models ───────────────────────────────────────────────────────────
    if (req.method === 'GET' && url === '/models') {
        res.end(JSON.stringify({
            status: 'success',
            models: ModelManager.getStatus()
        }));
        return;
    }

    // ── POST /models/query ────────────────────────────────────────────────────
    if (req.method === 'POST' && url === '/models/query') {
        try {
            const body = await parseBody(req);
            const { prompt, task_type, model_id, messages } = body;
            
            if (!prompt && !messages) {
                res.writeHead(400);
                res.end(JSON.stringify({ status: 'error', data: 'prompt or messages required' }));
                return;
            }

            const targetTaskType = task_type || ModelRouter.classifyIntent(prompt || messages[messages.length-1].content);
            const targetModelId  = ModelRouter.route(targetTaskType, model_id, ModelManager.getWarmModels());
            const targetMessages = messages || [{ role: 'user', content: prompt }];
            
            console.log(`[Orchestrator] Direct AI Query: "${targetTaskType}" -> ${targetModelId}`);
            
            const result = await ModelManager.query(targetModelId, targetMessages);
            
            res.end(JSON.stringify(result));
        } catch (err) {
            res.writeHead(500);
            res.end(JSON.stringify({ status: 'error', data: err.message }));
        }
        return;
    }
    
    // ── POST /models/stop ─────────────────────────────────────────────────────
    if (req.method === 'POST' && url === '/models/stop') {
        try {
            const body = await parseBody(req);
            const { model_id } = body;
            if (!model_id) {
                res.writeHead(400);
                res.end(JSON.stringify({ status: 'error', data: 'model_id required' }));
                return;
            }
            await ModelManager.stopModel(model_id);
            res.end(JSON.stringify({ status: 'success', data: `Model ${model_id} stopped` }));
        } catch (err) {
            res.writeHead(500);
            res.end(JSON.stringify({ status: 'error', data: err.message }));
        }
        return;
    }

    // ── GET /models/health ────────────────────────────────────────────────────
    if (req.method === 'GET' && url === '/models/health') {
        const health = await ModelManager.checkOllamaHealth();
        res.end(JSON.stringify({ status: 'success', ...health }));
        return;
    }

    // ── GET /health ───────────────────────────────────────────────────────────
    if (req.method === 'GET' && url === '/health') {
        res.end(JSON.stringify({
            status:  'healthy',
            service: 'KALI-Orchestrator',
            version: '3.0',
            uptime:  process.uptime()
        }));
        return;
    }

    // ── Phase 6: Missions API ─────────────────────────────────────────────────
    if (req.method === 'GET' && url === '/missions') {
        try {
            const baseUrl = config.sovereign?.internal?.base_url;
            const urlObj = new URL(req.url, baseUrl);
            const status = urlObj.searchParams.get('status');
            const missions = MissionEngine.listMissions(status);
            res.end(JSON.stringify({ status: 'success', missions }));
        } catch (e) {
            res.writeHead(500); res.end(JSON.stringify({ status: 'error', data: e.message }));
        }
        return;
    }

    if (req.method === 'POST' && url.match(/^\/missions\/([^/]+)\/pause$/)) {
        try {
            const id = url.split('/')[2];
            const updated = MissionEngine.updateStatus(id, 'paused', 'Paused by user');
            if (updated) res.end(JSON.stringify({ status: 'success', mission: updated }));
            else { res.writeHead(404); res.end(JSON.stringify({ status: 'error', data: 'Not found' })); }
        } catch (e) {
            res.writeHead(500); res.end(JSON.stringify({ status: 'error', data: e.message }));
        }
        return;
    }

    if (req.method === 'POST' && url.match(/^\/missions\/([^/]+)\/resume$/)) {
        try {
            const id = url.split('/')[2];
            const updated = MissionEngine.updateStatus(id, 'pending');
            if (updated) res.end(JSON.stringify({ status: 'success', mission: updated }));
            else { res.writeHead(404); res.end(JSON.stringify({ status: 'error', data: 'Not found' })); }
        } catch (e) {
            res.writeHead(500); res.end(JSON.stringify({ status: 'error', data: e.message }));
        }
        return;
    }

    if (req.method === 'POST' && url.match(/^\/missions\/([^/]+)\/stop$/)) {
        try {
            const id = url.split('/')[2];
            const updated = MissionEngine.updateStatus(id, 'failed', 'Stopped by user');
            if (updated) res.end(JSON.stringify({ status: 'success', mission: updated }));
            else { res.writeHead(404); res.end(JSON.stringify({ status: 'error', data: 'Not found' })); }
        } catch (e) {
            res.writeHead(500); res.end(JSON.stringify({ status: 'error', data: e.message }));
        }
        return;
    }

    // ── Phase 7: Failsafe API ─────────────────────────────────────────────────
    if (req.method === 'POST' && url === '/failsafe/pause_all') {
        try {
            console.warn('[Failsafe] PAUSE ALL triggered');
            EventBus.emit('system:failsafe', { type: 'PAUSE_ALL' });
            
            const running = MissionEngine.listMissions('running');
            let pausedCount = 0;
            for (const m of running) {
                MissionEngine.updateStatus(m.id, 'paused', 'Emergency Pause');
                pausedCount++;
            }
            res.end(JSON.stringify({ status: 'success', data: `Paused ${pausedCount} missions.` }));
        } catch (e) {
            res.writeHead(500); res.end(JSON.stringify({ status: 'error', data: e.message }));
        }
        return;
    }

    if (req.method === 'POST' && url === '/failsafe/stop_all') {
        try {
            console.error('[Failsafe] STOP ALL triggered');
            EventBus.emit('system:failsafe', { type: 'STOP_ALL' });

            const running = MissionEngine.listMissions('running');
            for (const m of running) {
                MissionEngine.updateStatus(m.id, 'failed', 'Emergency Stop');
            }

            // Force kill all underlying processes
            const activeTasks = RuntimeManager.getStatus();
            let killedCount = 0;
            for (const toolId of Object.keys(activeTasks)) {
                RuntimeManager.stopTool(toolId);
                killedCount++;
            }

            res.end(JSON.stringify({ status: 'success', data: `Killed ${killedCount} processes, failed ${running.length} missions.` }));
        } catch (e) {
            res.writeHead(500); res.end(JSON.stringify({ status: 'error', data: e.message }));
        }
        return;
    }

    res.writeHead(404);
    res.end(JSON.stringify({ status: 'error', data: `Route not found: ${req.method} ${url}` }));
});

// ─── BOOT ─────────────────────────────────────────────────────────────────────
server.listen(PORT, () => {
    console.log(`🔱 KALI Orchestration Service v4.0 — Port ${PORT}`);
    console.log(`   /orchestrate  /chain  /missions  /models  /health`);
    
    // Start background processors
    MissionRunner.init();
    Scheduler.init();
    SystemMonitor.init();
    ExecutionGovernor.init();
    AuditLogger.init();

    setTimeout(() => {
        console.log('[Orchestrator] Connecting TerminalBridge to Flask...');
        const bridgeUrl = `${config.sovereign.internal.base_url}:${config.flask?.port || 5000}`;
        TerminalBridge.connect(bridgeUrl);
    }, 3000);
});

// ─── GRACEFUL SHUTDOWN ────────────────────────────────────────────────────────
process.on('SIGTERM', () => { server.close(() => process.exit(0)); });
process.on('SIGINT',  () => { server.close(() => process.exit(0)); });
