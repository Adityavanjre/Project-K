/**
 * KALI Strategy Planner — v1.0 SOVEREIGN
 * Converts a Goal into an actionable execution plan.
 * Synthesizes dynamic chains for complex tasks (with safeguards).
 */

const fs = require('fs');
const path = require('path');
const ModelManager = require('./model_manager');
const ModelRouter  = require('./model_router');

const REGISTRY_FILE = path.join(__dirname, 'capability_registry.json');
const CHAINS_FILE   = path.join(__dirname, 'toolchains.json');

function getRegistry() {
    return JSON.parse(fs.readFileSync(REGISTRY_FILE, 'utf-8')).capabilities;
}

function getStaticChains() {
    return JSON.parse(fs.readFileSync(CHAINS_FILE, 'utf-8')).chains;
}

/**
 * Plan execution based on a structured goal.
 * STRICT PHASE 11 ENFORCEMENT: No dynamic chains allowed. Only 4 core outcome loops.
 * @param {Object} goalObj { goal, strategy_type, priority, target }
 * @returns {Promise<Object>} { type: 'static_chain', steps: Array, plan_id: string }
 */
async function createPlan(goalObj) {
    console.log(`[StrategyPlanner] Planning for goal: "${goalObj.goal}"`);

    const chains = getStaticChains();
    const goalStr = (goalObj.goal || "").toLowerCase();
    const inputStr = (goalObj.original_input || "").toLowerCase();

    // 1. Strict mapping to 4 core loops
    for (const chain of chains) {
        for (const kw of chain.trigger_keywords) {
            const lowerKw = kw.toLowerCase();
            if (goalStr.includes(lowerKw) || inputStr.includes(lowerKw)) {
                console.log(`[StrategyPlanner] Mapped to strictly defined Outcome Loop: ${chain.name}`);
                return { type: 'static_chain', steps: chain.steps, plan_id: chain.id };
            }
        }
    }

    // 2. Fallback: If no match, we refuse to execute a toolchain.
    // The Orchestrator will catch the empty steps array and fall back to Conversational AI.
    console.log(`[StrategyPlanner] Goal does not map to a strict outcome loop. Yielding to AI layer.`);
    return { type: 'unsupported', steps: [], plan_id: null };
}

module.exports = { createPlan };
