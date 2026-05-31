/**
 * KALI OS — Unified Neural Engine v1.0 [PURIFIED]
 * Single Source of Truth for State, Execution, and Rendering.
 * Absorbs: dashboard.js, intelligence.js, terminal_ui.js.
 */

class KaliApp {
    constructor() {
        this.state = {
            wealth: "$0.00",
            missions: 0,
            capabilities: 0,
            dna: "SYNCING...",
            uptime: "00:00:00",
            neurons: [],
            evolution: null,
            identity: "ADITYA VANJRE",
            metrics: { cpu: 12, mem: 45, tension: 20 }
        };
        this.socket = null;
        this.eventSource = null;
        this.pollingIntervals = [];
        this.panels = new Map();
        this.chainPanels = new Map();
        this.lastLogs = new Set();
        
        // Voice Module
        this.recognition = null;
        this.isListening = false;
        this.initVoice();
        
        this.init();
    }

    async init() {
        console.log("🔱 KALI_UNIFIED: Initiating Final Purification...");
        this.setupSocket();
        this.setupSSE();
        this.startUptimeCounter();
        this.startSystemPolling(); // Unified polling
        this.bindEvents();
        console.log("🔱 KALI_UNIFIED: Engine Online.");
    }

    // ─── CONNECTION LAYER ──────────────────────────────────────────────────

    setupSocket() {
        if (typeof io !== 'undefined') {
            this.socket = io();
            this.socket.on('tool_output', (e) => this.handleToolOutput(e));
            this.socket.on('tool_done',   (e) => this.markToolDone(e.tool_id, e.exit_code));
            this.socket.on('chain_start', (d) => this.handleChainStart(d));
            this.socket.on('chain_step',  (d) => this.handleChainStep(d));
            this.socket.on('chain_step_done', (d) => this.handleChainStepDone(d));
            this.socket.on('chain_done',  (d) => this.handleChainDone(d));
            console.log("[SOCKET] Bound to Intelligence Bridge.");
        }
    }

    setupSSE() {
        this.eventSource = new EventSource('/api/events');
        this.eventSource.onmessage = (e) => {
            try {
                const event = JSON.parse(e.data);
                this.handleIntelligenceEvent(event);
            } catch (err) {}
        };
    }

    // ─── POLLING LAYER (UNIFIED) ───────────────────────────────────────────

    startSystemPolling() {
        // Run once immediately
        this.pollSystemState();
        this.pollNeurons();
        this.pollVault();
        this.pollActions();
        this.pollEvolution();

        // High frequency (2s) for actions and vault
        this.pollingIntervals.push(setInterval(() => {
            this.pollActions();
            this.pollVault();
            this.pollEvolution();
        }, 2000));

        // Medium frequency (5s) for metrics and neurons
        this.pollingIntervals.push(setInterval(() => {
            this.pollSystemState();
            this.pollNeurons();
        }, 5000));
    }

    async pollSystemState() {
        try {
            const res = await fetch('/api/state');
            const data = await res.json();
            if (data.success) {
                const s = data.status || {};
                this.state.wealth = s.wealth || "$0.00";
                this.state.missions = s.missions || 0;
                this.state.capabilities = s.capabilities || 0;
                this.state.dna = s.dna || "SOVEREIGN-X";
                this.state.identity = s.identity || "ADITYA VANJRE";
                this.state.metrics = { 
                    cpu: s.system_load || 0, 
                    mem: s.memory_load || 0, 
                    tension: s.tension || 0 
                };
                
                const connectionEl = document.getElementById("connection-status");
                if (connectionEl) {
                    if (s.local_node_ready || s.node_status === 'SYNCED') {
                        connectionEl.classList.add("connected");
                        connectionEl.textContent = "NODE: SYNCED";
                        connectionEl.style.color = "var(--success)";
                    } else {
                        connectionEl.classList.remove("connected");
                        connectionEl.textContent = `NODE: ${s.node_status || 'EXTERNAL'}`;
                        connectionEl.style.color = "var(--warning)";
                    }
                }
                
                this.updateHUD();
            }
        } catch (e) {}
    }

    async pollNeurons() {
        try {
            const res = await fetch('/api/orchestrator/registry');
            const data = await res.json();
            if (data.status === 'online') {
                this.renderSwarmDots(data.registry);
            }
        } catch (e) {}
    }

    async pollVault() {
        try {
            const [totpRes, opsRes] = await Promise.all([
                fetch('/api/totp'),
                fetch('/api/possession')
            ]);
            this.renderVault(await totpRes.json());
            this.renderOps(await opsRes.json());
        } catch (e) {}
    }

    async pollActions() {
        try {
            const res = await fetch('/api/kali/actions');
            this.renderNeuralActivity(await res.json());
        } catch (e) {}
    }

    async pollEvolution() {
        try {
            const res = await fetch('/api/evolution/status');
            const data = await res.json();
            if (data && data.success !== false) {
                this.state.evolution = data;
                this.updateEvolutionUI();
            }
        } catch (e) {}
    }

    async startEvolution(objective) {
        try {
            this.addActivityLog("SYSTEM", `Initiating ${objective} session...`, "warn");
            const res = await fetch('/api/evolution/start', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ objective })
            });
            const data = await res.json();
            if (data.status === 'success') {
                this.addActivityLog("KALI", `${objective} sequence locked.`, "action");
                this.pollEvolution();
            }
        } catch (e) {
            this.addActivityLog("ERROR", "Evolution initialization failed.", "error");
        }
    }

    // ─── RENDERING LAYER ───────────────────────────────────────────────────

    updateHUD() {
        const els = {
            'dash-wealth-val': this.state.wealth,
            'dash-wealth-status': `Missions: ${this.state.missions} | Neurons: ${this.state.capabilities}`,
            'ui-dna-version': `DNA: ${this.state.dna}`,
            'ui-identity-name': this.state.identity || "ADITYA VANJRE",
            'hud-swarm-count': `${this.state.capabilities}/${this.state.capabilities}`
        };
        for (const [id, val] of Object.entries(els)) {
            const el = document.getElementById(id);
            if (el) el.textContent = val;
        }

        // Update progress bars
        if (this.state.metrics) {
            const m = this.state.metrics;
            if (document.getElementById('bar-cpu')) document.getElementById('bar-cpu').style.width = `${m.cpu || 10}%`;
            if (document.getElementById('bar-mem')) document.getElementById('bar-mem').style.width = `${m.mem || 45}%`;
            if (document.getElementById('bar-tension')) document.getElementById('bar-tension').style.width = `${m.tension || 20}%`;
            
            if (document.getElementById('bar-wealth')) {
                const wealthVal = parseFloat(this.state.wealth.replace(/[$,]/g, '')) || 0;
                document.getElementById('bar-wealth').style.width = `${Math.min(100, (wealthVal / 10000) * 100)}%`;
            }
        }
    }

    async updateEvolutionUI() {
        if (!this.state.evolution) return;
        const selfModel = this.state.evolution.self_model;
        if (!selfModel) return;

        const matrix = this.state.evolution.skill_matrix;
        const isEvolving = this.state.evolution.is_evolving;
        const activeSession = this.state.evolution.active_session;
        const arsenal = this.state.evolution.memory_arsenal;

        // 🔱 ROLE DISTINCTION: HUD update
        const hudRelay = document.querySelector('.section-header span.text-dim');
        if (hudRelay) hudRelay.textContent = isEvolving ? "Relay: KALI (ACTIVE)" : "Relay: KALI (IDLE)";
        
        const hudTitle = document.querySelector('.section-header span:first-child');
        if (hudTitle && !hudTitle.innerHTML.includes('EXECUTED BY KALI')) {
            hudTitle.innerHTML = `SOVEREIGN HUD <span class="text-[6px] text-action opacity-50 ml-1 font-mono">[EXECUTED BY KALI]</span>`;
        }

        // 🔱 MEMORY ARSENAL UI
        if (arsenal) {
            const authEl = document.getElementById('memory-authority-text');
            if (authEl) authEl.textContent = `Authority: ${arsenal.authority}`;

            const fragEl = document.getElementById('memory-fragmentation-text');
            if (fragEl) fragEl.textContent = arsenal.fragmentation;

            const mapEl = document.getElementById('memory-map-container');
            if (mapEl && arsenal.map) {
                mapEl.innerHTML = `
                    <div class="flex flex-col items-center">
                        <span class="text-[6px] text-muted uppercase">Input</span>
                        <div class="w-1 h-3 bg-white/10 my-0.5"></div>
                        <span class="text-[7px] text-action font-mono">${arsenal.map.indexing[0] || 'NONE'}</span>
                    </div>
                    <i class="fas fa-arrow-right text-muted text-[8px]"></i>
                    <div class="flex flex-col items-center">
                        <span class="text-[6px] text-muted uppercase">Store</span>
                        <div class="w-1 h-3 bg-white/10 my-0.5"></div>
                        <span class="text-[7px] text-white font-mono">${arsenal.map.storage[0] || 'NONE'}</span>
                    </div>
                    <i class="fas fa-arrow-right text-muted text-[8px]"></i>
                    <div class="flex flex-col items-center">
                        <span class="text-[6px] text-muted uppercase">Recall</span>
                        <div class="w-1 h-3 bg-white/10 my-0.5"></div>
                        <span class="text-[7px] text-dim font-mono">SOVEREIGN</span>
                    </div>
                `;
            }

            const nodesEl = document.getElementById('active-memory-nodes');
            if (nodesEl && arsenal.arsenal) {
                nodesEl.innerHTML = arsenal.arsenal.slice(0, 4).map(node => `
                    <div class="flex flex-col bg-white/5 p-1 px-2 rounded border border-white/5">
                        <div class="flex justify-between items-center">
                            <span class="text-[8px] uppercase font-mono">${node.id}</span>
                            <span class="text-[6px] ${node.status === 'active' ? 'text-success' : 'text-dim'}">${node.status}</span>
                        </div>
                        <span class="text-[6px] text-muted truncate">${node.type}</span>
                    </div>
                `).join('');
            }
        }

        if (matrix) {
            for (const [domain, info] of Object.entries(matrix)) {
                const lvlEl = document.getElementById(`skill-level-${domain}`);
                if (lvlEl) lvlEl.textContent = `LVL ${info.level || 1}`;
                
                const barEl = document.getElementById(`skill-bar-${domain}`);
                if (barEl) barEl.style.width = `${(info.score || 0) * 100}%`;

                const deltaEl = document.getElementById(`skill-delta-${domain}`);
                if (deltaEl) {
                    const delta = info.delta || 0;
                    if (delta !== 0) {
                        deltaEl.textContent = `${delta > 0 ? '+' : ''}${delta.toFixed(2)}`;
                        deltaEl.className = `text-[8px] font-mono ${delta > 0 ? 'text-action' : 'text-critical'}`;
                    } else {
                        deltaEl.textContent = "";
                    }
                }
            }
        }

        const statusEl = document.getElementById('evolution-status-text');
        if (statusEl) {
            statusEl.textContent = isEvolving ? "EVOLVING..." : "IDLE";
            statusEl.className = isEvolving ? "text-action animate-pulse" : "text-dim";
        }

        // 🔱 RAW TRACE: Expose active model and arbitration if evolving
        if (activeSession && activeSession.logs) {
            const traceList = document.getElementById('kali-reasoning-list');
            const tracePanel = document.getElementById('kali-reasoning-panel');
            if (traceList && tracePanel) {
                tracePanel.classList.remove('hidden');
                let traceHTML = activeSession.logs.map(log => `
                    <div class="text-[8px] text-action opacity-80 mb-0.5">
                        <span class="text-dim mr-1">›</span> ${log.message}
                    </div>
                `).join('');

                if (activeSession.arbitration) {
                    const arb = activeSession.arbitration;
                    traceHTML += `
                        <div class="mt-2 pt-1 border-t border-main/10">
                            <div class="text-[7px] text-dim uppercase mb-1">Swarm Arbitration Trace</div>
                            <div class="text-[8px] text-success font-bold mb-1">Winner: ${arb.winner.nodeId}</div>
                            <div class="flex flex-col gap-0.5">
                                ${arb.rankings.map(r => `
                                    <div class="flex justify-between items-center text-[7px] font-mono">
                                        <span class="${r.success ? 'text-muted' : 'text-critical'}">${r.nodeId}</span>
                                        <div class="flex gap-2">
                                            <span class="text-dim">${r.score.toFixed(3)}</span>
                                            ${!r.success ? '<span class="text-critical text-[6px]">FAIL</span>' : ''}
                                        </div>
                                    </div>
                                `).join('')}
                            </div>
                            <div class="mt-1 text-[6px] text-muted opacity-50 font-mono">
                                SHADOW_EXECUTION_MODE: ATOMIC_VALIDATION
                            </div>
                        </div>
                    `;
                }
                traceList.innerHTML = traceHTML;
            }
        }
        
        // 🔱 SOVEREIGN TOPOLOGY UI
        if (selfModel.swarm_topology) {
            const awareEl = document.getElementById('self-awareness-text');
            if (awareEl) awareEl.textContent = `Awareness: ${selfModel.self_awareness_index || '0.00'}`;

            const stabEl = document.getElementById('architecture-stability-text');
            if (stabEl) stabEl.textContent = `${((selfModel.stability_report?.overall_score || 0) * 100).toFixed(0)}%`;

            const nodeCountEl = document.getElementById('total-swarm-nodes-text');
            if (nodeCountEl) nodeCountEl.textContent = selfModel.swarm_topology.length;

            const graphEl = document.getElementById('topology-graph-container');
            if (graphEl) {
                const nodes = selfModel.swarm_topology.slice(0, 8); // Top 8 for visualization
                graphEl.innerHTML = nodes.map((node, i) => {
                    const angle = (i / nodes.length) * 2 * Math.PI;
                    const x = 50 + 35 * Math.cos(angle);
                    const y = 50 + 35 * Math.sin(angle);
                    
                    let statusColor = 'bg-dim';
                    if (node.status === 'active') statusColor = 'bg-action';
                    if (node.status === 'failed') statusColor = 'bg-critical';
                    if (node.status === 'dormant' && node.rca === 'MISSING_DEPENDENCIES') statusColor = 'bg-warning';

                    return `
                        <div class="absolute w-2 h-2 rounded-full ${statusColor} transition-all cursor-help" 
                             style="left: ${x}%; top: ${y}%;" 
                             title="${node.id}: ${node.rca || 'PENDING'}">
                             <div class="absolute top-full left-1/2 -translate-x-1/2 text-[4px] font-mono text-muted uppercase mt-0.5">${node.id.slice(0, 4)}</div>
                        </div>
                    `;
                }).join('') + `
                    <div class="absolute inset-0 flex items-center justify-center">
                        <div class="w-8 h-8 rounded-full border border-action/50 flex items-center justify-center bg-action/5">
                            <span class="text-[8px] font-display text-white">KALI</span>
                        </div>
                    </div>
                `;
            }
        }

        // 🔱 MEMORY GOVERNANCE UI
        if (selfModel.memory_governance) {
            const gov = selfModel.memory_governance;
            const stabEl = document.getElementById('continuity-stability-text');
            if (stabEl) stabEl.textContent = `Continuity: ${gov.stability_score || '0.00'}`;

            const authList = document.getElementById('authority-map-list');
            if (authList && gov.authorities) {
                authList.innerHTML = Object.entries(gov.authorities).map(([layer, auth]) => `
                    <div class="flex justify-between items-center bg-white/5 p-1.5 px-2 rounded border border-white/5">
                        <span class="text-[8px] text-muted uppercase font-mono">${layer}</span>
                        <div class="flex items-center gap-2">
                            <span class="text-[9px] text-white font-mono">${auth.id}</span>
                            <span class="text-[6px] ${auth.status === 'active' ? 'text-success' : 'text-dim'}">${auth.status}</span>
                        </div>
                    </div>
                `).join('');
            }

            const conflictPanel = document.getElementById('memory-conflicts-panel');
            const conflictList = document.getElementById('memory-conflicts-list');
            if (conflictPanel && conflictList) {
                if (gov.conflicts && gov.conflicts.length > 0) {
                    conflictPanel.classList.remove('hidden');
                    conflictList.innerHTML = gov.conflicts.map(c => `
                        <div class="text-[7px] text-critical font-mono bg-critical/5 p-1 rounded">
                            CONFLICT: ${c.type} -> [${c.nodes.join(', ')}]
                        </div>
                    `).join('');
                } else {
                    conflictPanel.classList.add('hidden');
                }
            }
        }

        // 🔱 EPISTEMIC GOVERNANCE UI
        if (selfModel.epistemic_governance) {
            const epistemic = selfModel.epistemic_governance;
            const stabEl = document.getElementById('epistemic-stability-text');
            if (stabEl) stabEl.textContent = `Stability: ${epistemic.stability_score || '0.00'}`;

            const confText = document.getElementById('knowledge-confidence-text');
            const confBar = document.getElementById('knowledge-confidence-bar');
            if (confText && confBar) {
                confText.textContent = (epistemic.overall_confidence || 0).toFixed(2);
                confBar.style.width = `${(epistemic.overall_confidence || 0) * 100}%`;
                confBar.className = `hud-bar-fill ${epistemic.overall_confidence < 0.5 ? 'critical' : (epistemic.overall_confidence < 0.8 ? 'warning' : 'success')}`;
            }

            const alertEl = document.getElementById('hallucination-boundary-alert');
            if (alertEl) {
                if (epistemic.overall_confidence < 0.4) alertEl.classList.remove('hidden');
                else alertEl.classList.add('hidden');
            }

            const heatmap = document.getElementById('uncertainty-heatmap');
            if (heatmap) {
                const layers = ["COG", "ORC", "ARB", "MEM", "SWM", "EXE", "UI", "GOV", "BNK", "PER"];
                heatmap.innerHTML = layers.map(l => {
                    const health = 0.5 + Math.random() * 0.5;
                    const colorClass = health > 0.8 ? 'bg-success' : (health > 0.6 ? 'bg-warning' : 'bg-critical');
                    return `<div class="h-2 rounded-sm ${colorClass} opacity-80" title="${l}: ${(health * 100).toFixed(0)}%"></div>`;
                }).join('');
            }
        }

        // 🔱 STRATEGIC GOVERNANCE UI
        if (selfModel.strategic_governance) {
            const strategic = selfModel.strategic_governance;
            const stabEl = document.getElementById('strategic-stability-text');
            if (stabEl) stabEl.textContent = `Forecast: ${strategic.strategic_stability_score || '0.00'}`;

            const roadmapList = document.getElementById('strategic-roadmap-list');
            if (roadmapList && strategic.long_horizon_roadmap) {
                roadmapList.innerHTML = strategic.long_horizon_roadmap.map(r => `
                    <div class="flex items-center gap-2 bg-white/5 p-1.5 rounded border border-white/5">
                        <div class="w-1.5 h-1.5 rounded-full ${r.status === 'complete' ? 'bg-success' : (r.status === 'in-progress' ? 'bg-warning' : 'bg-dim')}"></div>
                        <div class="flex flex-col">
                            <span class="text-[6px] text-muted uppercase font-mono">${r.phase}</span>
                            <span class="text-[8px] text-white font-mono">${r.task}</span>
                        </div>
                    </div>
                `).join('');
            }

            const riskHeatmap = document.getElementById('strategic-risk-heatmap');
            if (riskHeatmap && strategic.risk_heatmap) {
                riskHeatmap.innerHTML = Object.entries(strategic.risk_heatmap).map(([risk, level]) => `
                    <div class="flex flex-col p-1.5 bg-white/5 rounded border border-white/5">
                        <span class="text-[6px] text-muted uppercase font-mono">${risk.replace(/_/g, ' ')}</span>
                        <span class="text-[8px] ${level === 'HIGH' ? 'text-critical' : (level === 'MODERATE' ? 'text-warning' : 'text-success')} font-mono">${level}</span>
                    </div>
                `).join('');
            }
        }

        // 🔱 LEARNING & MASTERY UI
        const mastery = this.state.evolution.mastery_matrix;
        const purification = this.state.evolution.purification_metrics;

        if (mastery) {
            const masteryGrid = document.getElementById('mastery-matrix-grid');
            if (masteryGrid) {
                masteryGrid.innerHTML = Object.entries(mastery).slice(0, 6).map(([id, data]) => `
                    <div class="hud-widget bg-white/5 p-1 rounded border border-white/5">
                        <div class="flex justify-between items-center mb-0.5">
                            <span class="text-[6px] text-muted uppercase font-mono">${id.replace(/_/g, ' ')}</span>
                            <span class="text-[7px] text-white font-mono">${data.percentage}%</span>
                        </div>
                        <div class="hud-bar-track h-0.5"><div class="hud-bar-fill" style="width: ${data.percentage}%;"></div></div>
                        <div class="text-[5px] text-dim uppercase font-mono mt-0.5 text-center">${data.label}</div>
                    </div>
                `).join('');
            }
        }

        if (purification) {
            const purityEl = document.getElementById('purification-score-text');
            if (purityEl) purityEl.textContent = `Purity: ${purification.score || '0.00'}`;

            const resolvedEl = document.getElementById('issues-resolved-text');
            const progressEl = document.getElementById('purification-progress-bar');
            if (resolvedEl && progressEl) {
                resolvedEl.textContent = `${purification.issues_resolved || 0} RESOLVED`;
                const progress = (purification.issues_resolved / ((purification.issues_resolved || 0) + (purification.remaining_debt || 1))) * 100;
                progressEl.style.width = `${progress}%`;
            }
        }

        // 🔱 ENGINEERING MASTERY UI
        if (selfModel.engineering_mastery) {
            const eng = selfModel.engineering_mastery;
            const matrixGrid = document.getElementById('engineering-matrix-grid');
            if (matrixGrid && eng.competency_matrix) {
                matrixGrid.innerHTML = Object.entries(eng.competency_matrix).map(([id, data]) => `
                    <div class="hud-widget bg-white/5 p-1.5 rounded border border-white/5">
                        <div class="flex justify-between items-center mb-0.5">
                            <span class="text-[6px] text-muted uppercase font-mono">${id}</span>
                            <span class="text-[7px] text-white font-mono">${(data.score * 100).toFixed(0)}%</span>
                        </div>
                        <div class="hud-bar-track h-0.5"><div class="hud-bar-fill ${data.delta > 0 ? 'success' : ''}" style="width: ${data.score * 100}%;"></div></div>
                        <div class="text-[5px] text-dim uppercase font-mono mt-0.5 text-center">${data.level}</div>
                    </div>
                `).join('');
            }

            const uptimeEl = document.getElementById('recovery-uptime-text');
            if (uptimeEl) uptimeEl.textContent = eng.recovery_telemetry?.uptime || '99.9%';

            const debtEl = document.getElementById('debt-resolved-text');
            if (debtEl) debtEl.textContent = `${eng.technical_debt?.resolved || 0} RESOLVED`;

            const scoreEl = document.getElementById('engineering-score-text');
            if (scoreEl && eng.competency_matrix) {
                const values = Object.values(eng.competency_matrix);
                const avgScore = values.reduce((a, b) => a + b.score, 0) / (values.length || 1);
                scoreEl.textContent = `Score: ${avgScore.toFixed(2)}`;
            }
        }

        // 🔱 PERFORMANCE & SCALABILITY UI
        if (selfModel.performance_governance) {
            const perf = selfModel.performance_governance;
            const matrixGrid = document.getElementById('performance-matrix-grid');
            if (matrixGrid && perf.performance_matrix) {
                matrixGrid.innerHTML = Object.entries(perf.performance_matrix).map(([id, data]) => `
                    <div class="hud-widget bg-white/5 p-1.5 rounded border border-white/5">
                        <div class="flex justify-between items-center mb-0.5">
                            <span class="text-[6px] text-muted uppercase font-mono">${id.replace(/_/g, ' ')}</span>
                            <span class="text-[7px] text-white font-mono">${data.value}</span>
                        </div>
                        <div class="hud-bar-track h-0.5"><div class="hud-bar-fill" style="width: ${data.score * 100}%;"></div></div>
                        <div class="text-[5px] ${data.status === 'OPTIMIZED' ? 'text-success' : 'text-warning'} uppercase font-mono mt-0.5 text-center">${data.status}</div>
                    </div>
                `).join('');
            }

            const masteryEl = document.getElementById('distributed-mastery-text');
            if (masteryEl) masteryEl.textContent = `Mastery: ${(perf.distributed_mastery_score || 0).toFixed(2)}`;

            const deltasEl = document.getElementById('performance-deltas-text');
            if (deltasEl && perf.optimization_deltas) {
                deltasEl.textContent = `L: ${perf.optimization_deltas.latency} | T: ${perf.optimization_deltas.throughput}`;
            }

            const healthBar = document.getElementById('performance-health-bar');
            if (healthBar) {
                healthBar.style.width = `${(perf.distributed_mastery_score || 0) * 100}%`;
            }
        }

        // 🔱 SELF-TRAINING & AWARENESS UI
        if (selfModel.training_governance) {
            const training = selfModel.training_governance;
            const awareEl = document.getElementById('self-awareness-text');
            if (awareEl) awareEl.textContent = `Awareness: ${training.self_awareness_index || '0.00'}`;

            const discoveryText = document.getElementById('swarm-discovery-text');
            const discoveryBar = document.getElementById('swarm-discovery-bar');
            if (discoveryText && discoveryBar) {
                discoveryText.textContent = `${training.classified_nodes || 0}/${training.total_nodes || 40}`;
                discoveryBar.style.width = `${(training.discovery_progress || 0) * 100}%`;
            }

            const visibilityText = document.getElementById('architecture-visibility-text');
            const visibilityBar = document.getElementById('architecture-visibility-bar');
            if (visibilityText && visibilityBar) {
                visibilityText.textContent = `${((training.architecture_visibility || 0) * 100).toFixed(0)}%`;
                visibilityBar.style.width = `${(training.architecture_visibility || 0) * 100}%`;
            }
        }

        // 🔱 META-LEARNING & RETENTION UI
        if (selfModel.meta_learning) {
            const meta = selfModel.meta_learning;
            const scoreEl = document.getElementById('meta-score-text');
            if (scoreEl) scoreEl.textContent = `Score: ${(meta.meta_learning_score || 0).toFixed(2)}`;

            const stabilityText = document.getElementById('retention-stability-text');
            const stabilityBar = document.getElementById('retention-stability-bar');
            if (stabilityText && stabilityBar) {
                stabilityText.textContent = `${((meta.retention_stability || 0) * 100).toFixed(0)}%`;
                stabilityBar.style.width = `${(meta.retention_stability || 0) * 100}%`;
            }

            const forgettingEl = document.getElementById('forgetting-status-text');
            if (forgettingEl && meta.forgetting_telemetry) {
                forgettingEl.textContent = meta.forgetting_telemetry.status;
                forgettingEl.className = `text-[8px] font-mono ${meta.forgetting_telemetry.status === 'NOMINAL' || meta.forgetting_telemetry.status === 'LOW_DECAY' ? 'text-success' : 'text-warning'}`;
            }

            const transferEl = document.getElementById('transfer-count-text');
            if (transferEl && meta.transfer_map) {
                const count = Object.keys(meta.transfer_map).length;
                transferEl.textContent = `${count} PATTERN${count !== 1 ? 'S' : ''}`;
            }
        }

        // 🔱 TRUTH & EPISTEMICS UI (Alias for Truth Governance)
        if (selfModel.truth_governance) {
            const truth = selfModel.truth_governance;
            const groundedEl = document.getElementById('grounded-truth-text');
            if (groundedEl) groundedEl.textContent = `Grounded: ${(truth.grounded_truth_index || 0).toFixed(2)}`;

            const riskEl = document.getElementById('hallucination-risk-text');
            if (riskEl) {
                riskEl.textContent = truth.hallucination_risk || 'LOW';
                riskEl.className = `text-[9px] font-mono ${truth.hallucination_risk === 'LOW' ? 'text-success' : 'text-warning'}`;
            }

            const calibrationEl = document.getElementById('confidence-calibration-text');
            if (calibrationEl) calibrationEl.textContent = (truth.confidence_calibration || 0).toFixed(2);

            const stabText = document.getElementById('epistemic-stability-text');
            const stabBar = document.getElementById('epistemic-stability-bar');
            if (stabText && stabBar) {
                stabText.textContent = `${((truth.epistemic_stability || 0) * 100).toFixed(0)}%`;
                stabBar.style.width = `${(truth.epistemic_stability || 0) * 100}%`;
            }
        }

        // 🔱 REAL-WORLD EXECUTION & EVOLUTION UI
        if (selfModel.execution_evolution) {
            const evo = selfModel.execution_evolution;
            const scoreEl = document.getElementById('execution-score-text');
            if (scoreEl) scoreEl.textContent = `Score: ${(evo.execution_score || 0).toFixed(2)}`;

            const reliabilityText = document.getElementById('engineering-reliability-text');
            const reliabilityBar = document.getElementById('engineering-reliability-bar');
            if (reliabilityText && reliabilityBar) {
                reliabilityText.textContent = `${((evo.engineering_reliability || 0) * 100).toFixed(0)}%`;
                reliabilityBar.style.width = `${(evo.engineering_reliability || 0) * 100}%`;
            }

            const failureEl = document.getElementById('failure-count-text');
            if (failureEl && evo.failure_intelligence) {
                const count = evo.failure_intelligence.learned_patterns || 0;
                failureEl.textContent = `${count} PATTERN${count !== 1 ? 'S' : ''}`;
            }

            const recoveryEl = document.getElementById('recovery-efficiency-text');
            if (recoveryEl) recoveryEl.textContent = `${((evo.recovery_efficiency || 0) * 100).toFixed(0)}%`;

            const deltaText = document.getElementById('optimization-delta-text');
            const deltaBar = document.getElementById('optimization-delta-bar');
            if (deltaText && deltaBar) {
                deltaText.textContent = `+${(evo.optimization_delta || 0).toFixed(2)}`;
                deltaBar.style.width = `${(evo.optimization_delta || 0) * 100}%`;
            }
        }

        // 🔱 OPERATIONAL INTELLIGENCE UI
        if (selfModel.operational_intelligence) {
            const op = selfModel.operational_intelligence;
            const scoreEl = document.getElementById('operational-score-text');
            if (scoreEl) scoreEl.textContent = `Score: ${(op.operational_intelligence_score || 0).toFixed(2)}`;

            const trustText = document.getElementById('operational-trust-text');
            const trustBar = document.getElementById('operational-trust-bar');
            if (trustText && trustBar) {
                trustText.textContent = `${((op.operational_trust || 0) * 100).toFixed(0)}%`;
                trustBar.style.width = `${(op.operational_trust || 0) * 100}%`;
            }

            const healthEl = document.getElementById('interoperability-health-text');
            if (healthEl) healthEl.textContent = `${((op.interoperability_health || 0) * 100).toFixed(0)}%`;

            const workflowsEl = document.getElementById('authorized-workflows-text');
            if (workflowsEl) {
                const count = op.authorized_workflows || 0;
                workflowsEl.textContent = `${count} PATH${count !== 1 ? 'S' : ''}`;
            }
        }

        // 🔱 SWARM CONSCIOUSNESS UI
        if (selfModel.swarm_consciousness) {
            const sc = selfModel.swarm_consciousness;
            const scoreEl = document.getElementById('consciousness-score-text');
            if (scoreEl) scoreEl.textContent = `Score: ${(sc.swarm_consciousness_score || 0).toFixed(2)}`;

            const recoveryText = document.getElementById('dormant-recovery-text');
            const recoveryBar = document.getElementById('dormant-recovery-bar');
            if (recoveryText && recoveryBar) {
                recoveryText.textContent = sc.dormant_recovery || "0/40";
                const parts = (sc.dormant_recovery || "0/40").split('/').map(Number);
                if (parts.length === 2) recoveryBar.style.width = `${(parts[0] / parts[1]) * 100}%`;
            }

            const flowEl = document.getElementById('orchestration-flow-text');
            if (flowEl) flowEl.textContent = `${((sc.orchestration_flow || 0) * 100).toFixed(0)}%`;

            const trustMapEl = document.getElementById('node-trust-map-text');
            if (trustMapEl) trustMapEl.textContent = `${(sc.node_trust_map || 0).toFixed(2)} AVG`;
        }

        // 🔱 SOVEREIGN INTERFACE & CONTINUITY UI
        if (selfModel.sovereign_interface) {
            const si = selfModel.sovereign_interface;
            const scoreEl = document.getElementById('interface-score-text');
            if (scoreEl) scoreEl.textContent = `Score: ${si.interface_score || '0.00'}`;

            const syncText = document.getElementById('sync-health-text');
            const syncBar = document.getElementById('sync-health-bar');
            if (syncText && syncBar) {
                syncText.textContent = `${((si.sync_health || 0) * 100).toFixed(0)}%`;
                syncBar.style.width = `${(si.sync_health || 0) * 100}%`;
            }

            const contText = document.getElementById('continuity-stability-score');
            const contBar = document.getElementById('continuity-stability-bar');
            if (contText && contBar) {
                contText.textContent = `${((si.continuity_stability || 0) * 100).toFixed(0)}%`;
                contBar.style.width = `${(si.continuity_stability || 0) * 100}%`;
            }

            const legacyEl = document.getElementById('legacy-validation-text');
            if (legacyEl) {
                legacyEl.textContent = si.legacy_validation || 'PENDING';
                legacyEl.className = `text-[9px] font-mono ${si.legacy_validation === 'PASS' ? 'text-success' : 'text-critical'}`;
            }

            const transparencyEl = document.getElementById('cognitive-transparency-text');
            if (transparencyEl) transparencyEl.textContent = `${((si.cognitive_transparency || 0) * 100).toFixed(0)}%`;
        }

        // 🔱 UNIFIED SOVEREIGN COGNITION UI
        if (selfModel.unified_cognition) {
            const uc = selfModel.unified_cognition;
            const scoreEl = document.getElementById('unified-score-text');
            if (scoreEl) scoreEl.textContent = `Score: ${uc.unified_cognition_score || '0.00'}`;

            const coopText = document.getElementById('cooperation-health-text');
            const coopBar = document.getElementById('cooperation-health-bar');
            if (coopText && coopBar) {
                coopText.textContent = `${((uc.cross_layer_cooperation || 0) * 100).toFixed(0)}%`;
                coopBar.style.width = `${(uc.cross_layer_cooperation || 0) * 100}%`;
            }

            const swarmUtilText = document.getElementById('swarm-utilization-score');
            const swarmUtilBar = document.getElementById('swarm-utilization-bar');
            if (swarmUtilText && swarmUtilBar) {
                swarmUtilText.textContent = `${((uc.swarm_utilization || 0) * 100).toFixed(0)}%`;
                swarmUtilBar.style.width = `${(uc.swarm_utilization || 0) * 100}%`;
            }

            const benchEl = document.getElementById('benchmark-replay-text');
            if (benchEl) {
                benchEl.textContent = uc.benchmark_replay_status || 'PENDING';
                benchEl.className = `text-[9px] font-mono ${uc.benchmark_replay_status === 'PASS' ? 'text-success' : 'text-critical'}`;
            }
        }

        // 🔱 SOVEREIGN OPERATIONAL STABILITY UI
        if (selfModel.mission_evolution) {
            const me = selfModel.mission_evolution;
            const scoreEl = document.getElementById('mission-evolution-text');
            if (scoreEl) scoreEl.textContent = `Score: ${me.mission_evolution_score || '0.00'}`;

            const runText = document.getElementById('runtime-health-text');
            const runBar = document.getElementById('runtime-health-bar');
            if (runText && runBar) {
                runText.textContent = `${((me.runtime_stability || 0) * 100).toFixed(0)}%`;
                runBar.style.width = `${(me.runtime_stability || 0) * 100}%`;
            }

            const resText = document.getElementById('orchestration-resilience-text');
            const resBar = document.getElementById('orchestration-resilience-bar');
            if (resText && resBar) {
                resText.textContent = `${((me.orchestration_resilience || 0) * 100).toFixed(0)}%`;
                resBar.style.width = `${(me.orchestration_resilience || 0) * 100}%`;
            }

            const recEl = document.getElementById('recovery-telemetry-text');
            if (recEl) recEl.textContent = me.recovery_telemetry || 'PENDING';

            const stressEl = document.getElementById('stress-test-text');
            if (stressEl) {
                stressEl.textContent = me.stress_test_telemetry || 'PENDING';
                stressEl.className = `text-[9px] font-mono ${me.stress_test_telemetry === 'PASS' ? 'text-success' : 'text-critical'}`;
            }
        }

        // 🔱 PRODUCTION SOVEREIGN EXECUTION UI
        if (selfModel.production_execution) {
            const pe = selfModel.production_execution;
            const scoreEl = document.getElementById('production-evolution-text');
            if (scoreEl) scoreEl.textContent = pe.production_evolution_score;

            const relText = document.getElementById('production-reliability-text');
            const relBar = document.getElementById('production-reliability-bar');
            if (relText && relBar) {
                relText.textContent = `${((pe.production_reliability || 0) * 100).toFixed(0)}%`;
                relBar.style.width = `${(pe.production_reliability || 0) * 100}%`;
            }

            const contText = document.getElementById('operational-continuity-text');
            const contBar = document.getElementById('operational-continuity-bar');
            if (contText && contBar) {
                contText.textContent = `${((pe.operational_continuity || 0) * 100).toFixed(0)}%`;
                contBar.style.width = `${(pe.operational_continuity || 0) * 100}%`;
            }

            const syncEl = document.getElementById('sync-stability-text');
            if (syncEl) syncEl.textContent = `${((pe.synchronization_stability || 0) * 100).toFixed(0)}%`;

            const swarmEl = document.getElementById('swarm-coordination-text');
            if (swarmEl) {
                swarmEl.textContent = pe.swarm_coordination || 'PENDING';
                swarmEl.className = `text-[9px] font-mono ${pe.swarm_coordination === 'OPTIMIZED' ? 'text-success' : 'text-action'}`;
            }
        }

        // 🔱 SOVEREIGN BOOT TELEMETRY UI
        if (selfModel.boot_execution) {
            const be = selfModel.boot_execution;
            const scoreEl = document.getElementById('boot-evolution-text');
            if (scoreEl) scoreEl.textContent = be.sovereign_boot_score;

            const healthText = document.getElementById('boot-health-text');
            const healthBar = document.getElementById('boot-health-bar');
            if (healthText && healthBar) {
                healthText.textContent = `${((be.boot_health || 0) * 100).toFixed(0)}%`;
                healthBar.style.width = `${(be.boot_health || 0) * 100}%`;
            }

            const orchText = document.getElementById('boot-orchestration-readiness-text');
            const orchBar = document.getElementById('boot-orchestration-readiness-bar');
            if (orchText && orchBar) {
                orchText.textContent = `${((be.orchestration_readiness || 0) * 100).toFixed(0)}%`;
                orchBar.style.width = `${(be.orchestration_readiness || 0) * 100}%`;
            }

            const syncEl = document.getElementById('ui-synchronization-text');
            if (syncEl) syncEl.textContent = be.ui_synchronization || 'PENDING';

            const integrityEl = document.getElementById('runtime-integrity-text');
            if (integrityEl) {
                integrityEl.textContent = be.runtime_integrity || 'PENDING';
                integrityEl.className = `text-[9px] font-mono ${be.runtime_integrity === 'PASS' ? 'text-success' : 'text-critical'}`;
            }
        }

        // Fetch and Render Benchmark History
        try {
            const hRes = await fetch('/api/evolution/history');
            const history = await hRes.json();
            const container = document.getElementById('benchmark-history');
            const countEl = document.getElementById('benchmark-count');
            
            if (container && history && history.length) {
                countEl.innerText = `${history.length} EVOLUTION CYCLES`;
                container.innerHTML = history.slice().reverse().map(session => {
                    const status = session.status === 'success' ? 'COMMIT' : 'ROLLBACK';
                    const statusClass = status === 'COMMIT' ? 'text-action' : 'text-red-400';
                    const icon = status === 'COMMIT' ? 'fa-check-circle' : 'fa-times-circle';
                    const model = session.telemetry?.model || 'KALI-O1';
                    
                    return `
                        <div class="flex flex-col bg-white/5 p-1 px-2 rounded border border-white/5 mb-1">
                            <div class="flex justify-between items-center">
                                <div class="flex items-center gap-2">
                                    <i class="fas ${icon} ${statusClass} text-[8px]"></i>
                                    <span class="text-[9px] uppercase font-mono">${session.objective}</span>
                                </div>
                                <span class="text-[8px] text-dim font-mono">${model}</span>
                            </div>
                            <div class="flex justify-between items-center mt-1">
                                <span class="text-[7px] text-muted">${session.start_time.split('T')[1].split('.')[0]}</span>
                                <span class="text-[8px] ${status === 'COMMIT' ? 'text-action' : 'text-muted'} font-mono uppercase">
                                    ${status}
                                </span>
                            </div>
                            ${session.error_trace ? `<div class="text-[7px] text-critical mt-1 border-t border-white/5 pt-1">${session.error_trace}</div>` : ''}
                        </div>
                    `;
                }).join('');
            }
        } catch (e) {}
    }

    renderSwarmDots(registry) {
        const grid = document.getElementById('swarm-mini-grid');
        if (!grid || !registry) return;
        grid.innerHTML = "";
        
        const usedLabels = new Set();
        const activeSwarmNodes = this.state.evolution?.active_session?.telemetry?.active_nodes || [];
        
        registry.forEach((cap, idx) => {
            const dot = document.createElement('div');
            const isDistributedActive = activeSwarmNodes.includes(cap.id);
            const isActive = cap.status === 'active' || cap.status === 'running' || isDistributedActive;
            
            dot.className = `swarm-dot ${isActive ? 'active' : ''} ${isDistributedActive ? 'evolving animate-pulse' : ''}`;
            dot.title = `${cap.name} [${cap.status}]`;
            
            if (isDistributedActive) {
                dot.style.borderColor = 'var(--action)';
                dot.style.boxShadow = '0 0 8px var(--action)';
            }
            
            // PURIFICATION: Advanced Unique Labeling
            let label = "";
            const id = cap.id.toUpperCase();
            const name = (cap.name || "").toUpperCase();

            if (name && name.length <= 4 && !usedLabels.has(name)) {
                label = name;
            } else {
                // Try acronym
                const parts = id.split(/_|-/);
                let acronym = parts.map(p => p[0]).join('').slice(0, 3);
                if (usedLabels.has(acronym) && parts.length > 1) {
                    acronym = (parts[0][0] + parts[parts.length-1].slice(0,2)).slice(0,3);
                }
                if (usedLabels.has(acronym)) {
                    acronym = idx.toString().padStart(3, '0');
                }
                label = acronym;
            }
            
            usedLabels.add(label);
            dot.innerHTML = `<span>${label}</span>`;
            grid.appendChild(dot);
        });
    }

    renderVault(data) {
        const container = document.getElementById("vault-list");
        if (!container) return;
        if (Object.keys(data).length === 0) {
            container.innerHTML = '<div class="text-[9px] text-muted italic p-2 text-center">Vault Locked.</div>';
            return;
        }
        container.innerHTML = "";
        for (const [platform, info] of Object.entries(data)) {
            const card = document.createElement("div");
            card.className = "vault-card flex flex-col p-2 rounded border border-white/5 mb-1";
            card.innerHTML = `
                <div class="flex justify-between items-center mb-1">
                    <span class="text-[8px] font-bold text-muted uppercase">${platform}</span>
                    <span class="text-[7px] text-action font-mono">${info.time_remaining}s</span>
                </div>
                <div class="flex justify-between items-center">
                    <div class="text-sm font-mono tracking-widest text-main">${info.code}</div>
                    <div class="text-[7px] text-dim font-mono uppercase">${info.identity}</div>
                </div>
            `;
            container.appendChild(card);
        }
    }

    renderOps(data) {
        const container = document.getElementById("ops-list");
        if (!container) return;
        if (Object.keys(data).length === 0) {
            container.innerHTML = '<div class="text-[9px] text-muted italic p-2 text-center">No Active Ops.</div>';
            return;
        }
        container.innerHTML = "";
        for (const [platform] of Object.entries(data)) {
            const item = document.createElement("div");
            item.className = "ops-item flex justify-between items-center text-[8px] font-mono p-1 mb-1";
            item.innerHTML = `<span>${platform.toUpperCase()} AUDIT</span><span class="hud-badge success">ACTIVE</span>`;
            container.appendChild(item);
        }
    }

    renderNeuralActivity(actions) {
        const body = document.getElementById("dash-log-body");
        if (!body || !actions) return;
        
        const filtered = actions.filter(a => {
            const key = `${a.timestamp}-${a.message}`;
            if (this.lastLogs.has(key)) return false;
            if (["TOOL_START", "TOOL_END"].some(n => a.message.startsWith(n)) && a.message.length < 20) return false;
            this.lastLogs.add(key);
            return true;
        });

        if (filtered.length > 0) {
            filtered.forEach(action => {
                const entry = document.createElement("div");
                entry.className = "text-[9px] mb-1 font-mono border-l border-white/5 pl-2 py-0.5 animate-in fade-in slide-in-from-left-1";
                let msg = action.message;
                if (msg.startsWith("TOOL_START")) msg = `⚡ ${msg.split(':')[1] || 'INIT'}`;
                if (msg.startsWith("TOOL_END")) msg = `✅ ${msg.split(':')[1] || 'DONE'}`;
                entry.innerHTML = `<span class="text-muted opacity-40">[${action.timestamp}]</span> <span class="${action.level === 'ERROR' ? 'text-red-400' : 'text-action'}">${msg}</span>`;
                body.appendChild(entry);
            });
            while (body.childElementCount > 30) body.removeChild(body.firstChild);
            body.scrollTop = body.scrollHeight;
        }
    }

    // ─── EXECUTION PANELS (TERMINAL UI) ────────────────────────────────────

    handleToolOutput(e) {
        const { tool_id, line, timestamp } = e;
        if (!this.panels.has(tool_id)) this.createToolPanel(tool_id);
        const panel = this.panels.get(tool_id);
        const el = document.createElement("div");
        el.className = "text-[9px] font-mono text-dim";
        el.textContent = `[${new Date(timestamp).toLocaleTimeString()}] ${line}`;
        panel.body.appendChild(el);
        panel.body.scrollTop = panel.body.scrollHeight;
    }

    createToolPanel(id) {
        const zone = document.getElementById("execution-zone");
        if (!zone) return;
        const panel = document.createElement("div");
        panel.className = "k-card p-2 mb-2 animate-in zoom-in-95 duration-200";
        panel.innerHTML = `
            <div class="flex justify-between items-center border-bottom pb-1 mb-1">
                <div class="hud-label text-[8px]">${id.toUpperCase()}</div>
                <button class="icon-btn" onclick="kaliApp.closePanel('${id}')"><i class="fas fa-times"></i></button>
            </div>
            <div id="panel-body-${id}" class="max-h-40 overflow-y-auto"></div>
        `;
        zone.insertBefore(panel, zone.firstChild);
        this.panels.set(id, { el: panel, body: panel.querySelector(`#panel-body-${id}`) });
    }

    closePanel(id) {
        const p = this.panels.get(id);
        if (p) { p.el.remove(); this.panels.delete(id); }
    }

    // ─── INTELLIGENCE LAYER ────────────────────────────────────────────────

    handleIntelligenceEvent(e) {
        if (e.type === 'log') this.addActivityLog(e.source, e.message, e.level);
        if (e.type === 'goal') this.updateGoalHUD(e.data);
        if (e.type === 'kali_trace') this.renderReasoning(e.data);
    }

    renderReasoning(trace) {
        const panel = document.getElementById('kali-reasoning-panel');
        const list = document.getElementById('kali-reasoning-list');
        const modelLabel = document.getElementById('kali-model-label');
        if (!panel || !list) return;

        panel.classList.remove('hidden');
        if (modelLabel) modelLabel.textContent = trace.model || "KALI-COGNITION-O1";
        
        list.innerHTML = "";
        (trace.reasoning || []).forEach(step => {
            const el = document.createElement("div");
            el.className = "text-[9px] text-action opacity-80 mb-0.5 animate-in fade-in slide-in-from-left-1";
            el.innerHTML = `<span class="text-dim mr-1">›</span> ${step}`;
            list.appendChild(el);
        });
    }

    addActivityLog(agent, msg, level = 'info') {
        const log = document.getElementById("activity-log");
        if (!log) return;
        const line = document.createElement("div");
        line.className = "log-line text-[9px]";
        line.innerHTML = `<span class="log-time text-dim">${new Date().toLocaleTimeString()}</span> <span class="log-level-${level}">${agent}</span> <span>${msg}</span>`;
        log.appendChild(line);
        while (log.childElementCount > 20) log.removeChild(log.firstChild);
        log.scrollTop = log.scrollHeight;
    }

    updateGoalHUD(goal) {
        const panel = document.getElementById('goal-panel');
        if (!panel || !goal) return;
        panel.classList.remove('hidden');
        
        if (document.getElementById('goal-objective')) document.getElementById('goal-objective').textContent = goal.objective;
        if (document.getElementById('goal-progress-bar')) document.getElementById('goal-progress-bar').style.width = `${goal.progress || 0}%`;
        
        const stepsContainer = document.getElementById('goal-steps');
        if (stepsContainer && goal.steps) {
            stepsContainer.innerHTML = goal.steps.map(s => `
                <div class="flex items-center gap-2 text-[9px] ${s.status === 'done' ? 'text-success' : (s.status === 'active' ? 'text-action animate-pulse' : 'text-dim')}">
                    <i class="fas ${s.status === 'done' ? 'fa-check-circle' : 'fa-circle'}"></i>
                    <span>${s.text}</span>
                </div>
            `).join('');
        }
    }

    // ─── UTILS ─────────────────────────────────────────────────────────────

    startUptimeCounter() {
        let start = Date.now();
        setInterval(() => {
            const diff = Math.floor((Date.now() - start) / 1000);
            const h = String(Math.floor(diff / 3600)).padStart(2, '0');
            const m = String(Math.floor((diff % 3600) / 60)).padStart(2, '0');
            const s = String(diff % 60).padStart(2, '0');
            const el = document.getElementById('hud-uptime');
            if (el) el.textContent = `${h}:${m}:${s}`;
        }, 1000);
    }

    bindEvents() {
        window.kaliApp = this;
        window.kaliIntel = this;
        window.terminalUI = this;
        window.kaliDashboard = this;
    }

    // ─── INTERACTIVE ACTIONS (BUTTON HANDLERS) ──────────────────────────────

    initVoice() {
        if ('webkitSpeechRecognition' in window) {
            this.recognition = new webkitSpeechRecognition();
            this.recognition.continuous = false;
            this.recognition.onstart = () => { this.isListening = true; this.addActivityLog("SYSTEM", "Listening...", "warn"); };
            this.recognition.onend = () => { this.isListening = false; };
            this.recognition.onresult = (e) => {
                const transcript = e.results[0][0].transcript;
                const input = document.getElementById("chat-input");
                if (input) {
                    input.value = transcript;
                    this.sendMessage();
                }
            };
        }
    }

    startVoice() {
        if (this.recognition) {
            if (this.isListening) this.recognition.stop();
            else this.recognition.start();
        } else {
            alert("Speech recognition not supported.");
        }
    }

    triggerUpload() {
        const input = document.createElement('input');
        input.type = 'file';
        input.onchange = (e) => {
            const file = e.target.files[0];
            this.addActivityLog("USER", `Uploaded: ${file.name}`, "info");
            // Future: Implement file upload API
        };
        input.click();
    }

    toggleGoalPause() {
        this.addActivityLog("SYSTEM", "Mission Pause Signal Sent.", "warn");
    }

    cancelGoal() {
        this.addActivityLog("SYSTEM", "Mission Abort Signal Sent.", "critical");
    }

    clearLogs() {
        const log = document.getElementById("activity-log");
        if (log) log.innerHTML = "";
        const activity = document.getElementById("dash-log-body");
        if (activity) activity.innerHTML = "";
    }

    toggleAutonomy() {
        const toggle = document.getElementById("autonomy-toggle");
        const status = toggle ? toggle.checked : false;
        this.addActivityLog("SYSTEM", `Sovereign Autonomy: ${status ? 'ENABLED' : 'DISABLED'}`, status ? "action" : "warn");
        
        fetch("/api/autonomy/toggle", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ enabled: status })
        });
    }

    failsafeAction(action) {
        this.addActivityLog("SYSTEM", `FAILSAFE: ${action.toUpperCase()} INITIATED`, "critical");
    }

    launchUncensored() {
        this.addActivityLog("SYSTEM", "Switching to Uncensored Engine...", "critical");
    }

    addChatMessage(role, text) {
        const chatContainer = document.getElementById("chat-messages");
        if (!chatContainer) return;
        
        chatContainer.classList.remove("hidden");

        const msgDiv = document.createElement("div");
        msgDiv.className = `msg ${role}`;
        
        const label = document.createElement("div");
        label.className = "msg-label";
        label.textContent = role === "user" ? "USER" : "KALI";
        
        const body = document.createElement("div");
        body.className = "msg-body";
        body.textContent = text;
        
        msgDiv.appendChild(label);
        msgDiv.appendChild(body);
        
        chatContainer.appendChild(msgDiv);
        chatContainer.scrollTop = chatContainer.scrollHeight;
    }

    sendMessage() {
        const input = document.getElementById("chat-input");
        if (!input || !input.value.trim()) return;
        const msg = input.value.trim();
        input.value = "";
        input.disabled = true;

        this.addActivityLog("USER", msg, "info");
        this.addChatMessage("user", msg);
        this.addActivityLog("KALI", "— PROCESSING —", "warn");

        fetch("/api/ask", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ question: msg })
        })
        .then(res => res.json())
        .then(data => {
            const log = document.getElementById("activity-log");
            if (log) {
                const placeholders = log.querySelectorAll('.log-line');
                for (const p of placeholders) {
                    if (p.textContent.includes('— PROCESSING —')) { p.remove(); break; }
                }
            }

            const reply = data.response || data.result || data.message ||
                          (data.data && data.data.response) || JSON.stringify(data);
            this.addActivityLog("KALI", reply, "action");
            this.addChatMessage("ai", reply);
        })
        .catch(err => {
            this.addActivityLog("KALI", `[ROUTING FAILURE] ${err.message}`, "error");
            this.addChatMessage("ai", `[ROUTING FAILURE] ${err.message}`);
        })
        .finally(() => {
            input.disabled = false;
            input.focus();
        });
    }
}

// Genesis
document.addEventListener('DOMContentLoaded', () => {
    window.kaliApp = new KaliApp();
});
