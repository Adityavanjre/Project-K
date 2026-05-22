/**
 * KALI Domain Engine — v1.0 SOVEREIGN
 * Dynamically detects the operational domain of a user request using keyword heuristics.
 * Guarantees sub-10ms classification before hitting the LLM or orchestrator flow.
 */

const DOMAINS = {
    cybersecurity: {
        keywords: ['scan', 'hack', 'vulnerability', 'exploit', 'nmap', 'sqlmap', 'recon', 'bounty', 'xss'],
        weight: 1.2
    },
    development: {
        keywords: ['code', 'refactor', 'build', 'script', 'git', 'deploy', 'debug', 'compile', 'aider', 'api'],
        weight: 1.0
    },
    education: {
        keywords: ['explain', 'learn', 'how does', 'what is', 'teach', 'tutorial', 'guide', 'understand'],
        weight: 1.0
    },
    '3d_engineering': {
        keywords: ['3d', 'print', 'cad', 'assembly', 'part', 'components', 'stl', 'design', 'hardware'],
        weight: 1.5 // Higher weight because these words are very specific
    },
    finance: {
        keywords: ['bounty', 'bounties', 'wallet', 'crypto', 'earnings', 'payout', 'balance', 'track', 'hackerone', 'bugcrowd'],
        weight: 1.2
    },
    identity_management: {
        keywords: ['login', 'account', 'sync', 'profile', 'credentials', 'token', 'auth', 'session'],
        weight: 1.1
    }
};

/**
 * Detect the domain of a given message.
 * Returns { domain: string, confidence: number }
 */
function detectDomain(message) {
    if (!message || typeof message !== 'string') return { domain: 'development', confidence: 0.1 };

    const lowerMsg = message.toLowerCase();
    const tokens = lowerMsg.replace(/[^a-z0-9 ]/g, ' ').split(/\s+/).filter(Boolean);
    const scores = {};

    // Initialize scores
    Object.keys(DOMAINS).forEach(d => scores[d] = 0);

    // Calculate heuristic scores based on whole word tokens
    for (const [domain, config] of Object.entries(DOMAINS)) {
        for (const kw of config.keywords) {
            // Check if the exact keyword is a token, OR if it's a multi-word phrase included in the raw string
            if (kw.includes(' ')) {
                if (lowerMsg.includes(kw)) scores[domain] += config.weight;
            } else {
                if (tokens.includes(kw)) {
                    scores[domain] += config.weight;
                }
            }
        }
    }

    // Find the highest scoring domain
    let topDomain = 'development'; // Default fallback
    let topScore = 0;

    for (const [domain, score] of Object.entries(scores)) {
        if (score > topScore) {
            topScore = score;
            topDomain = domain;
        }
    }

    // Calculate pseudo-confidence (max out at 0.99 for heuristics)
    const confidence = Math.min(topScore / 3, 0.99);

    return {
        domain: topDomain,
        confidence: parseFloat(confidence.toFixed(2))
    };
}

module.exports = { detectDomain, DOMAINS };
