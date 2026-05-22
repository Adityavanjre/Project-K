/**
 * KALI Outcome Tracker — v1.0 SOVEREIGN
 * Measures tangible real-world value generation (money, commits, physical builds).
 */

const fs = require('fs');
const path = require('path');

class OutcomeTracker {
    constructor() {
        this.outcomesPath = path.join(__dirname, '../../data/outcomes.json');
        this.outcomes = [];
        this._load();
    }

    _load() {
        if (fs.existsSync(this.outcomesPath)) {
            try {
                this.outcomes = JSON.parse(fs.readFileSync(this.outcomesPath, 'utf8'));
            } catch (e) {
                this.outcomes = [];
            }
        }
    }

    _save() {
        if (!fs.existsSync(path.dirname(this.outcomesPath))) {
            fs.mkdirSync(path.dirname(this.outcomesPath), { recursive: true });
        }
        fs.writeFileSync(this.outcomesPath, JSON.stringify(this.outcomes, null, 2));
    }

    recordOutcome(goalId, intent, resultStr, valueGenerated = 0, timeTakenMs = 0) {
        const record = {
            id: `out_${Date.now()}`,
            goal_id: goalId,
            intent,
            status: 'completed',
            result: resultStr,
            value_generated: valueGenerated, // $ for bounties, LoC for code, etc.
            time_taken_ms: timeTakenMs,
            timestamp: new Date().toISOString()
        };

        this.outcomes.push(record);
        this._save();
        console.log(`[OutcomeTracker] Logged outcome: ${resultStr} (Value: ${valueGenerated})`);
        return record;
    }

    recordLoopOutcome(loopId, intent, resultStr, amount = 1) {
        let valueType = 'General Actions';
        let valueGenerated = amount;

        switch (loopId) {
            case 'bug_hunt_loop':
                valueType = 'Bounty Earnings ($)';
                break;
            case 'development_loop':
                valueType = 'Features Delivered';
                break;
            case '3d_project_loop':
                valueType = 'Build Plans Verified';
                break;
            case 'automation_loop':
                valueType = 'Workflows Deployed';
                break;
        }

        const record = {
            id: `out_${Date.now()}`,
            loop_id: loopId,
            intent,
            status: 'completed',
            result: resultStr,
            metric_type: valueType,
            value_generated: valueGenerated,
            timestamp: new Date().toISOString()
        };

        this.outcomes.push(record);
        this._save();
        console.log(`[OutcomeTracker] Loop [${loopId}] Outcome: ${valueGenerated} ${valueType} -> ${resultStr}`);
        return record;
    }

    getHistory() {
        return this.outcomes;
    }

    getTotalValue() {
        return this.outcomes.reduce((sum, o) => sum + (Number(o.value_generated) || 0), 0);
    }
}

module.exports = new OutcomeTracker();
