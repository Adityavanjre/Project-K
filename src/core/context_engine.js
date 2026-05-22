const path = require('path');
const fs = require('fs');
let internalIp;
try {
    const configPath = path.join(__dirname, '../../config/config.json');
    const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
    internalIp = config.sovereign?.internal?.ip;
} catch (e) {
    console.warn("[ContextEngine] Failed to load config.json for internal IP.");
}

/**
 * KALI Context Engine — v1.0
 *
 * Extracts structured facts from raw tool output.
 * Propagates those facts as enriched args for subsequent chain steps.
 * Makes KALI context-aware between tool executions.
 */

// ─── FACT EXTRACTORS (per tool_id) ───────────────────────────────────────────
// Each extractor processes a buffer of output lines and returns structured facts.

const EXTRACTORS = {

    sovereign_recon: (lines) => {
        const facts = { open_ports: [], services: {}, host_up: false };
        // PORT_RE: "80/tcp   open  http   Apache 2.4"
        const PORT_RE = /^(\d+)\/(tcp|udp)\s+(open|closed|filtered)\s+(\S+)(?:\s+(.+))?$/i;
        for (const line of lines) {
            const m = line.trim().match(PORT_RE);
            if (m && m[3] === 'open') {
                const port = parseInt(m[1], 10);
                facts.open_ports.push(port);
                facts.services[port] = { proto: m[2], service: m[4], version: m[5] || '' };
            }
            if (/Host is up/i.test(line)) facts.host_up = true;
        }
        return facts;
    },

    web_recon: (lines) => {
        const facts = { endpoints: [], subdomains: [] };
        for (const line of lines) {
            // Match paths like "/admin" "/api/v1"
            const pathM = line.match(/\/([\w\-/]+)/);
            if (pathM) facts.endpoints.push(pathM[0]);
            // Match subdomain.domain.tld
            const subM = line.match(/([a-z0-9\-]+\.[a-z0-9\-]+\.[a-z]{2,})/gi);
            if (subM) facts.subdomains.push(...subM);
        }
        facts.endpoints = [...new Set(facts.endpoints)].slice(0, 50);
        facts.subdomains = [...new Set(facts.subdomains)].slice(0, 20);
        return facts;
    },

    osint_engine: (lines) => {
        const facts = { emails: [], ips: [], domains: [] };
        const EMAIL_RE = /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/g;
        const IP_RE    = /\b(?:\d{1,3}\.){3}\d{1,3}\b/g;
        for (const line of lines) {
            const emails = line.match(EMAIL_RE) || [];
            const ips    = line.match(IP_RE) || [];
            facts.emails.push(...emails);
            facts.ips.push(...ips.filter(ip => ip !== internalIp));
        }
        facts.emails  = [...new Set(facts.emails)].slice(0, 50);
        facts.ips     = [...new Set(facts.ips)].slice(0, 30);
        return facts;
    },

    xss_hunter: (lines) => {
        const facts = { xss_findings: [] };
        for (const line of lines) {
            if (/xss|payload|reflected|stored|vulnerable/i.test(line)) {
                facts.xss_findings.push(line.trim().slice(0, 100));
            }
        }
        return facts;
    },

    sql_injection: (lines) => {
        const facts = { sqli_findings: [] };
        for (const line of lines) {
            if (/injectable|error-based|boolean|time-based|dumped/i.test(line)) {
                facts.sqli_findings.push(line.trim().slice(0, 100));
            }
        }
        return facts;
    },

    exploit_generator: (lines) => {
        const facts = { poc_code: lines.join('\n').slice(0, 2000) };
        return facts;
    },

    code_auditor: (lines) => {
        const facts = { audit_findings: [] };
        for (const line of lines) {
            if (/error|warning|severity|vulnerability|issue/i.test(line)) {
                facts.audit_findings.push(line.trim().slice(0, 120));
            }
        }
        return facts;
    },

    auto_refactor: (lines) => {
        const facts = { changed_files: [] };
        for (const line of lines) {
            const m = line.match(/(?:modified|created|updated):\s+(\S+)/i);
            if (m) facts.changed_files.push(m[1]);
        }
        return facts;
    },

    // Default: no structured extraction
    _default: (_lines) => ({})
};

// ─── PUBLIC API ───────────────────────────────────────────────────────────────

/**
 * Extract structured facts from raw output lines for a given tool.
 * @param {string}   toolId
 * @param {string[]} lines   Array of clean (ANSI-stripped) output lines
 * @returns {object}         Structured facts
 */
function extractOutputFacts(toolId, lines) {
    const extractor = EXTRACTORS[toolId] || EXTRACTORS._default;
    try {
        return extractor(lines);
    } catch (e) {
        console.error(`[ContextEngine] Extraction failed for ${toolId}: ${e.message}`);
        return {};
    }
}

/**
 * Build enriched args for the next chain step by mapping accumulated facts
 * to the next tool's input_schema fields.
 *
 * @param {object} accumulatedFacts   All facts from prior steps
 * @param {string} nextToolId
 * @param {object} baseArgs           Original user-provided args (target, etc.)
 * @returns {object}                  Merged args for next tool
 */
function buildChainArgs(accumulatedFacts, nextToolId, baseArgs = {}) {
    const merged = { ...baseArgs };

    // Universal fact propagation rules
    const facts = accumulatedFacts;

    // Target is always passed through
    if (baseArgs.target) merged.target = baseArgs.target;

    // Port-aware tools get the first open port if available
    if (facts.open_ports && facts.open_ports.length > 0) {
        merged.port = facts.open_ports[0];
        merged.ports = facts.open_ports.join(',');
    }

    // Endpoint-aware tools get top discovered paths
    if (facts.endpoints && facts.endpoints.length > 0) {
        merged.endpoints = facts.endpoints.slice(0, 10).join(',');
    }

    // Report generator gets a structured summary of all findings
    if (nextToolId === 'report_generator') {
        merged.findings = JSON.stringify({
            open_ports:     facts.open_ports    || [],
            xss_findings:   facts.xss_findings  || [],
            sqli_findings:  facts.sqli_findings || [],
            emails:         facts.emails        || [],
            ips:            facts.ips           || [],
            audit_findings: facts.audit_findings || []
        });
    }

    // Bounty submission gets report summary
    if (nextToolId === 'bounty_hunter') {
        const vuln_count =
            (facts.xss_findings?.length  || 0) +
            (facts.sqli_findings?.length || 0);
        merged.severity = vuln_count > 3 ? 'critical' : vuln_count > 0 ? 'high' : 'low';
        merged.title    = `Automated findings for ${baseArgs.target || 'target'}`;
    }

    return merged;
}

/**
 * Enrich an intent analysis result with past context for the same target.
 * Called before chain execution to inject historical awareness.
 *
 * @param {object} analysis     IntentEngine.analyzeIntent() result
 * @param {object} args         User args (target, etc.)
 * @param {object} memory       MemoryService module reference
 * @returns {object}            Enriched analysis with context annotation
 */
function enrich(analysis, args, memory) {
    const target = args?.target;
    if (!target || !memory) return analysis;

    const pastRuns = memory.getContext(target);
    if (pastRuns.length === 0) return analysis;

    // Aggregate past facts
    const pastFacts = {};
    for (const run of pastRuns) {
        if (run.facts && typeof run.facts === 'object') {
            Object.assign(pastFacts, run.facts);
        }
    }

    return {
        ...analysis,
        context: {
            target,
            past_runs: pastRuns.length,
            known_facts: pastFacts,
            last_seen: pastRuns[0]?.timestamp
        }
    };
}

/**
 * Merge two fact objects (accumulator pattern).
 */
function mergeFacts(existing, newFacts) {
    const merged = { ...existing };
    for (const [key, val] of Object.entries(newFacts)) {
        if (Array.isArray(val) && Array.isArray(merged[key])) {
            // Deduplicate arrays
            merged[key] = [...new Set([...merged[key], ...val])];
        } else {
            merged[key] = val;
        }
    }
    return merged;
}

module.exports = { extractOutputFacts, buildChainArgs, enrich, mergeFacts };
