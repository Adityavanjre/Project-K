/**
 * KALI Intent Engine — v2.0 SOVEREIGN
 * Maps natural language input to registered capabilities from the Capability Registry.
 * Supports multi-tool activation, confidence scoring, and fuzzy keyword matching.
 */

const fs = require('fs');
const path = require('path');
const { scanCapabilities } = require('./capability_scanner');

// Load registry dynamically via scanner
function loadRegistry() {
    return scanCapabilities();
}

/**
 * Tokenize a string into lowercase words, stripping punctuation.
 */
function tokenize(str) {
    return str.toLowerCase().replace(/[^a-z0-9 ]/g, ' ').split(/\s+/).filter(Boolean);
}

/**
 * Score a capability against the user's intent.
 * Returns a float between 0 and 1.
 */
function scoreCapability(capability, inputTokens) {
    const keywords = capability.trigger_keywords.map(k => k.toLowerCase());
    let matches = 0;

    for (const keyword of keywords) {
        const kwTokens = tokenize(keyword);
        // Check for full phrase match first (higher weight)
        const inputStr = inputTokens.join(' ');
        if (inputStr.includes(keyword.toLowerCase())) {
            matches += 2;
            continue;
        }
        // Check for individual token matches
        for (const kwToken of kwTokens) {
            if (inputTokens.includes(kwToken)) {
                matches += 1;
                break;
            }
        }
    }

    return matches / (keywords.length + 1); // Normalize
}

/**
 * Primary intent analysis function.
 * @param {string} message - Raw user input
 * @returns {Object} Analysis result with selected capabilities
 */
function analyzeIntent(message) {
    if (!message || typeof message !== 'string' || !message.trim()) {
        return {
            original_input: message,
            actionable: false,
            selected_capabilities: [],
            confidence: 0,
            reason: 'Empty or invalid input'
        };
    }

    const registry = loadRegistry();
    const inputTokens = tokenize(message);
    const ACTIVATION_THRESHOLD = 0.15; // Minimum score to activate a tool

    const scored = registry.map(cap => ({
        ...cap,
        score: scoreCapability(cap, inputTokens)
    }));

    // Sort by score descending
    scored.sort((a, b) => b.score - a.score);

    // Select all capabilities above threshold (multi-tool support)
    const selected = scored.filter(c => c.score >= ACTIVATION_THRESHOLD);

    // Cap at top 3 to avoid over-activation
    const topSelected = selected.slice(0, 3);

    const isActionable = topSelected.length > 0;
    const topScore = topSelected.length > 0 ? topSelected[0].score : 0;

    return {
        original_input: message,
        actionable: isActionable,
        confidence: parseFloat(topScore.toFixed(3)),
        selected_capabilities: topSelected.map(c => ({
            id: c.id,
            name: c.name,
            score: parseFloat(c.score.toFixed(3)),
            execution_type: c.execution_type,
            start_command: c.start_command,
            working_directory: c.working_directory,
            input_schema: c.input_schema,
            output_type: c.output_type,
            ui_mode: c.ui_mode,
            dependencies: c.dependencies
        })),
        all_scores: scored.slice(0, 5).map(c => ({ id: c.id, name: c.name, score: parseFloat(c.score.toFixed(3)) }))
    };
}

/**
 * Retrieve the full registry (for /registry endpoint).
 */
function getRegistry() {
    return loadRegistry();
}

module.exports = { analyzeIntent, getRegistry };
