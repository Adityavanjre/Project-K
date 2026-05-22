/**
 * KALI Self-Auditor — v1.0 SOVEREIGN
 * Scans the codebase for drift, hardcoding, and inefficiencies.
 */

const fs = require('fs');
const path = require('path');

class SelfAuditor {
    constructor() {
        this.scanDirs = [
            path.join(__dirname, '../../src/core'),
            path.join(__dirname, '../../src/static/js')
        ];
        this.rules = [
            {
                name: 'HARDCODED_PATTERN',
                regex: /(https?:\/\/(?!127\.0\.0\.1|localhost)[^\s'"]+)|(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(?!\.0\.0\.1))/,
                severity: 'high',
                message: 'Hardcoded external IP or URL detected. Must use configuration registry.'
            },
            {
                name: 'MOCK_SYSTEM_FALLBACK',
                regex: /return\s+.*mock.*|callback\(.*mock.*\)|res\.send\(.*mock.*\)/i,
                severity: 'critical',
                message: 'Active mock fallback detected. System must be grounded in real swarm telemetry.'
            },
            {
                name: 'DUPLICATE_LOGIC_CANDIDATE',
                regex: /function\s+\w+\(\)\s*\{\s*\w+\(\);?\s*\}/,
                severity: 'medium',
                message: 'Potential passthrough/redundant function detected. Candidate for architectural flattening.'
            },
            {
                name: 'UNSTABLE_IMPORT',
                regex: /require\(.*(?:\.\.\/){3,}.*\)/,
                severity: 'medium',
                message: 'Deep relative import detected (>3 levels). Suggests fragmented architecture.'
            },
            {
                name: 'DEAD_CODE_MARKER',
                regex: /\/\/\s*TEMP:|\/\/\s*FIXME:|\/\/\s*STUB:/i,
                severity: 'low',
                message: 'Development marker remains in sovereign core.'
            }
        ];
    }

    runAudit() {
        console.log("[SelfAuditor] Initiating zero-drift codebase scan...");
        const report = { timestamp: new Date().toISOString(), issues: [] };

        this.scanDirs.forEach(dir => {
            if (!fs.existsSync(dir)) return;
            this._scanDirectory(dir, report);
        });

        // Write report
        const reportPath = path.join(__dirname, '../../data/audit_report.json');
        fs.writeFileSync(reportPath, JSON.stringify(report, null, 2));

        if (report.issues.length > 0) {
            console.warn(`[SelfAuditor] Warning: ${report.issues.length} structural issues detected. Check data/audit_report.json`);
        } else {
            console.log("[SelfAuditor] Audit complete: Codebase is 100% pure. Zero drift.");
        }

        return report;
    }

    _scanDirectory(dir, report) {
        const files = fs.readdirSync(dir);
        files.forEach(file => {
            const fullPath = path.join(dir, file);
            const stat = fs.statSync(fullPath);
            if (stat.isDirectory()) {
                this._scanDirectory(fullPath, report);
            } else if (file.endsWith('.js') || file.endsWith('.py')) {
                this._analyzeFile(fullPath, report);
            }
        });
    }

    _analyzeFile(filePath, report) {
        // 🔱 ARCHITECTURAL PROTECTION: Exclude core configuration and the auditor itself
        const excluded = ["config.json", "self_auditor.js", "self_auditor.py", ".claude", "logs", "data", "scratch"];
        if (excluded.some(ex => filePath.includes(ex))) return;

        const content = fs.readFileSync(filePath, 'utf8');
        const lines = content.split('\n');

        lines.forEach((line, idx) => {
            this.rules.forEach(rule => {
                if (rule.regex.test(line)) {
                    report.issues.push({
                        file: path.basename(filePath),
                        line: idx + 1,
                        rule: rule.name,
                        severity: rule.severity,
                        message: rule.message,
                        snippet: line.trim()
                    });
                }
            });
        });
    }
}

module.exports = new SelfAuditor();
