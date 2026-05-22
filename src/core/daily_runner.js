/**
 * KALI Daily Runner — v1.0 SOVEREIGN
 * Autonomous execution loop. Resumes paused/pending goals on startup
 * and prioritizes high-value tasks automatically.
 */

const MissionEngine = require('./mission_engine');
const OutcomeTracker = require('./outcome_tracker');
const OperationMode = require('./operation_mode');

class DailyRunner {
    constructor() {
        this.running = false;
        this.checkInterval = 60000; // Check every 1 minute
    }

    start() {
        if (this.running) return;
        this.running = true;
        console.log(`[DailyRunner] Autonomous operation engaged. Mode: ${OperationMode.getMode()}`);
        
        // Immediate boot check
        this._resumePendingGoals();

        // Start background loop
        setInterval(() => this._resumePendingGoals(), this.checkInterval);
    }

    _resumePendingGoals() {
        // Find all missions that are not completed or failed
        const pending = MissionEngine.listMissions('pending');
        const paused = MissionEngine.listMissions('paused');
        const running = MissionEngine.listMissions('running');

        const activeMissions = [...pending, ...paused, ...running];

        if (activeMissions.length === 0) {
            console.log("[DailyRunner] No pending tasks. KALI is idling.");
            return;
        }

        // Final Protocol: Weight-based Priority Sorting
        const loopWeights = {
            'bug_hunt_loop': 100,
            'development_loop': 90,
            '3d_project_loop': 50,
            'automation_loop': 40
        };

        activeMissions.sort((a, b) => {
            const weightA = loopWeights[a.plan_id] || 0;
            const weightB = loopWeights[b.plan_id] || 0;
            return (weightB + (b.priority || 0)) - (weightA + (a.priority || 0));
        });

        const topMission = activeMissions[0];
        if (topMission.status !== 'running') {
            console.log(`[DailyRunner] Resuming high-priority mission: [${topMission.id}]`);
            MissionEngine.updateStatus(topMission.id, 'running');
        }
    }
}

module.exports = new DailyRunner();
