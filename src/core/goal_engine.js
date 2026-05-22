/**
 * KALI Goal Engine — v1.0 SOVEREIGN
 * Parses natural language into a structured Goal object.
 * Uses the fast AI model for interpretation.
 */

const ModelManager = require('./model_manager');
const ModelRouter  = require('./model_router');

/**
 * Interpret a user message into a Goal.
 * @param {string} message 
 * @returns {Promise<Object>} { goal, strategy_type, priority, confidence }
 */
async function interpretGoal(message) {
    if (!message || typeof message !== 'string' || !message.trim()) {
        return { goal: null, actionable: false };
    }

    console.log(`[GoalEngine] Interpreting: "${message.substring(0, 50)}..."`);

    // ── Phase 1: Fast-Path Execution Check (Zero Latency) ─────────────────────
    // If input matches a strict toolchain keyword, bypass AI entirely.
    try {
        const chainsPath = require('path').join(__dirname, 'toolchains.json');
        if (require('fs').existsSync(chainsPath)) {
            const { chains } = JSON.parse(require('fs').readFileSync(chainsPath, 'utf8'));
            const lower = message.toLowerCase();
            for (const chain of chains) {
                const hit = chain.trigger_keywords.some(kw => {
                    const kwLower = kw.toLowerCase();
                    if (lower.includes(kwLower)) return true;
                    // Check if all significant words of the keyword are present in the input
                    const words = kwLower.split(/\s+/).filter(w => w.length > 3);
                    return words.length > 0 && words.every(w => lower.includes(w.substring(0, w.length - 1)));
                });

                if (hit) {
                    console.log(`[GoalEngine] Fast-Path HIT: "${chain.id}"`);
                    return {
                        original_input: message,
                        actionable: true,
                        goal: chain.name,
                        strategy_type: 'chain',
                        priority: 'high',
                        confidence: 1.0,
                        target: null
                    };
                }
            }
        }
    } catch (e) {
        console.error("[GoalEngine] Fast-Path error:", e.message);
    }

    // ── Phase 2: AI Interpretation (Reasoning Layer) ──────────────────────────
    const modelId = ModelRouter.route('fast'); 
    const systemPrompt = `You are the KALI Goal Engine. Your job is to parse the user's intent into a structured JSON goal.
Extract the following fields:
- "goal": A clear, concise summary of what the user wants to achieve (e.g. "Find vulnerabilities on example.com").
- "strategy_type": Must be one of ["single", "chain", "dynamic"]. Use "single" for a one-off tool, "chain" for a known sequence, "dynamic" if complex planning is needed.
- "priority": Must be one of ["high", "medium", "low"]. "high" for exploit/security, "low" for background osint.
- "confidence": Float between 0.0 and 1.0 representing how sure you are of the intent.
- "target": The IP, domain, or target mentioned, or null.

Respond ONLY with valid JSON. Do not include markdown blocks.`;

    try {
        const result = await ModelManager.query(modelId, [
            { role: 'system', content: systemPrompt },
            { role: 'user', content: message }
        ], { temperature: 0.1 });

        if (result.success) {
            let jsonStr = result.content.trim();
            // Clean up possible markdown code blocks
            if (jsonStr.startsWith('```')) {
                jsonStr = jsonStr.replace(/^```json/i, '').replace(/^```/, '').replace(/```$/, '').trim();
            }
            
            const parsed = JSON.parse(jsonStr);
            return {
                original_input: message,
                actionable: parsed.confidence > 0.3,
                goal: parsed.goal,
                strategy_type: parsed.strategy_type || 'single',
                priority: parsed.priority || 'medium',
                confidence: parsed.confidence || 0.5,
                target: parsed.target || null
            };
        }
    } catch (err) {
        console.error(`[GoalEngine] Parsing failed:`, err);
    }

    // Fallback: Use simple keyword classifier if AI fails
    const intentType = ModelRouter.classifyIntent(message);
    return {
        original_input: message,
        actionable: true,
        goal: `Execute ${intentType} task`,
        strategy_type: 'chain',
        priority: 'medium',
        confidence: 0.5,
        target: null
    };
}

module.exports = { interpretGoal };
