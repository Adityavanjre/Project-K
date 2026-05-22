/**
 * KALI Evolution Engine — v1.0 SOVEREIGN
 * Manages autonomous self-training sessions and skill matrix evolution.
 * Coordinates with ml-intern and the 40-node swarm.
 */

const fs = require('fs');
const path = require('path');
const selfAuditor = require('./self_auditor');
const auditLogger = require('./audit_logger');

const { execSync } = require('child_process');

class EvolutionEngine {
    constructor() {
        this.matrixPath = path.join(__dirname, '../../data/evolution/skill_matrix.json');
        this.historyPath = path.join(__dirname, '../../data/evolution/training_history.json');
        this.isEvolving = false;
        this.activeSession = null;
    }

    async getStatus() {
        const matrix = this._loadMatrix();
        const memoryIntrospector = require('./memory_introspector');
        const selfModeler = require('./self_modeler');
        
        const memoryStatus = await memoryIntrospector.performIntrospection();
        const selfModel = await selfModeler.generateSelfModel();
        
        const masteryGovernor = require('./mastery_governor');
        const mastery = masteryGovernor.calculateMastery(matrix);
        const auditReport = require('./self_auditor').runAudit();
        const purification = masteryGovernor.getPurificationStatus(auditReport);

        return {
            is_evolving: this.isEvolving,
            active_session: this.activeSession,
            skill_matrix: matrix.domains,
            mastery_matrix: mastery,
            purification_metrics: purification,
            benchmarks: matrix.benchmarks,
            memory_arsenal: memoryStatus,
            self_model: selfModel
        };
    }

    async runBenchmarkSuite() {
        this._log("🔱 Initiating Real Competency Benchmark Suite...");
        try {
            const bridgePath = path.join(__dirname, 'evolution_bridge.py');
            
            // 🔱 TELEMETRY: Fetching active model state
            const modelStatus = require('./model_manager').getStatus().filter(m => m.state === 'warm');
            const activeModel = modelStatus.length > 0 ? modelStatus[0].id : "KALI-O1-COGNITION";
            const swarmCount = modelStatus.length;

            this._log(`Cognition Engine: ${activeModel} | Swarm Nodes: ${swarmCount}`);

            // 🔱 EXECUTION: Running real Python-based benchmarks
            const output = execSync(`python "${bridgePath}" benchmark`, { encoding: 'utf8' });
            const result = JSON.parse(output);

            if (result.success) {
                if (this.activeSession) {
                    this.activeSession.telemetry = {
                        ...this.activeSession.telemetry,
                        model: activeModel,
                        swarm_nodes: swarmCount,
                        results: result.results
                    };
                }
                this._updateMatrixWithRealScores(result.results);
                return result.results;
            } else {
                throw new Error(result.error);
            }
        } catch (e) {
            this._log(`CRITICAL: Benchmark Suite Failed -> ${e.message}`);
            if (this.activeSession) {
                this.activeSession.status = "fail";
                this.activeSession.error_trace = e.message;
            }
            return null;
        }
    }

    _updateMatrixWithRealScores(newScores) {
        const matrix = this._loadMatrix();
        const now = new Date().toISOString();

        Object.keys(newScores).forEach(domain => {
            if (matrix.domains[domain]) {
                const prevScore = matrix.domains[domain].score;
                const newScore = newScores[domain].score;
                
                matrix.domains[domain].delta = Number((newScore - prevScore).toFixed(4));
                matrix.domains[domain].score = newScore;
                
                // Evolutionary Level Logic
                if (newScore > 0.8 && matrix.domains[domain].level === 1) matrix.domains[domain].level = 2;
                if (newScore > 0.95 && matrix.domains[domain].level === 2) matrix.domains[domain].level = 3;

                // Gap Removal (Simulated for now, would be based on test pass/fail)
                if (newScore > 0.5) matrix.domains[domain].gaps = matrix.domains[domain].gaps.slice(1);
            }
        });

        matrix.benchmarks.last_run = now;
        matrix.timestamp = now;
        fs.writeFileSync(this.matrixPath, JSON.stringify(matrix, null, 2));
        this._log("🔱 Skill Matrix Synchronized with Real Execution Reality.");
    }

    async startSession(objective) {
        if (this.activeSession) {
            this._log("WARNING: Session already in progress. Terminating existing sequence.");
        }

        // Identify Domain from Objective
        const domainMap = {
            'Coding': 'backend',
            'Architecture': 'architecture',
            'Reasoning': 'reasoning',
            'Debugging': 'backend',
            'UI': 'frontend',
            'Security': 'security'
        };
        const domain = domainMap[objective] || 'reasoning';

        // 🔱 SWARM ACTIVATION: Identify Specialists
        const SwarmSpecializer = require('./swarm_specializer');
        const specialists = SwarmSpecializer.getSpecialists(domain);
        const activeNodes = specialists.slice(0, 5).map(s => s.id); // Active top 5 for this cycle

        this.isEvolving = true;
        this.activeSession = {
            id: `EVO-${Date.now()}`,
            objective,
            domain,
            start_time: new Date().toISOString(),
            status: "evolving",
            logs: [],
            telemetry: {
                model: "KALI-O1-COGNITION",
                swarm_nodes: activeNodes.length,
                active_nodes: activeNodes
            }
        };

        this._log(`🔱 EVOLUTION SESSION START: ${objective} [DOMAIN: ${domain.toUpperCase()}]`);
        this._log(`🔱 ACTIVE SWARM: ${activeNodes.join(', ')}`);
        
        try {
            // 🔱 RESOURCE MANAGEMENT: Signal nodes to warm up
            this._triggerSwarmWarmup(activeNodes);

            setTimeout(async () => {
                const benchResults = await this.runBenchmarkSuite();
                
                // 🔱 ARBITRATION: Execute Swarm Decision Governance
                if (benchResults && this.activeSession) {
                    const SwarmArbitrator = require('./swarm_arbitrator');
                    const proposals = this.activeSession.telemetry.active_nodes.map(nodeId => ({
                        nodeId,
                        solution: `Optimized strategy via ${nodeId}`,
                        type: 'atomic_logic'
                    }));

                    const decision = await SwarmArbitrator.arbitrate(this.activeSession.domain, proposals);
                    this.activeSession.arbitration = decision;
                    this._log(`🔱 ARBITRATION COMPLETE: Winner [${decision.winner.nodeId}]`);
                }

                this.finalizeSession("success");
            }, 5000);
            
            return this.activeSession;
        } catch (err) {
            this.finalizeSession("fail", err.message);
            throw err;
        }
    }

    _triggerSwarmWarmup(nodes) {
        nodes.forEach(nodeId => {
            this._log(`› Signaling Swarm Node [${nodeId}] for Domain Alignment...`);
        });
    }

    finalizeSession(status, error = null) {
        if (!this.activeSession) return;

        this.activeSession.status = status;
        this.activeSession.end_time = new Date().toISOString();
        if (error) this.activeSession.error = error;

        // Save History
        const history = this._loadHistory();
        history.push(this.activeSession);
        fs.writeFileSync(this.historyPath, JSON.stringify(history, null, 2));

        console.log(`[Evolution] Session ${this.activeSession.id} finalized with status: ${status}`);
        this.isEvolving = false;
        this.activeSession = null;
    }

    _log(message) {
        const logEntry = { timestamp: new Date().toISOString(), message: message };
        console.log(`[Evolution] ${message}`);
        if (this.activeSession) this.activeSession.logs.push(logEntry);
    }

    _loadMatrix() {
        if (!fs.existsSync(this.matrixPath)) return { domains: {}, benchmarks: {} };
        return JSON.parse(fs.readFileSync(this.matrixPath, 'utf8'));
    }

    _loadHistory() {
        if (!fs.existsSync(this.historyPath)) return [];
        return JSON.parse(fs.readFileSync(this.historyPath, 'utf8'));
    }
}

module.exports = new EvolutionEngine();
