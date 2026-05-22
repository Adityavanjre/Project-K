/**
 * KALI Auto-Optimization Engine — v1.0 SOVEREIGN
 * Control loop for detecting slow tools and auto-fixing errors.
 */

class Optimizer {
    constructor() {
        this.toolStats = new Map();
        this.errorLog = [];
    }

    logExecution(toolId, durationMs, success, errorMsg = null) {
        if (!this.toolStats.has(toolId)) {
            this.toolStats.set(toolId, { count: 0, totalDuration: 0, errors: 0 });
        }
        
        const stats = this.toolStats.get(toolId);
        stats.count += 1;
        stats.totalDuration += durationMs;
        
        if (!success) {
            stats.errors += 1;
            this.errorLog.push({ toolId, time: new Date(), errorMsg });
            this._analyzeErrors(toolId);
        }

        const avgDuration = stats.totalDuration / stats.count;
        if (avgDuration > 15000) { // 15 seconds threshold
            console.warn(`[Optimizer] Tool ${toolId} is consistently slow (Avg: ${Math.round(avgDuration)}ms). Consider optimization.`);
        }
    }

    _analyzeErrors(toolId) {
        const recentErrors = this.errorLog.filter(e => e.toolId === toolId && (Date.now() - e.time.getTime() < 3600000));
        if (recentErrors.length > 5) {
            console.error(`[Optimizer] CRITICAL: Tool ${toolId} has failed ${recentErrors.length} times in the last hour. Suggesting architectural review.`);
        }
    }
}

module.exports = new Optimizer();
