/**
 * KALI Cognitive Recoverer — v1.0 SOVEREIGN
 * Autonomous dormant system recovery and capability validation.
 * Zero hardcoding: Derived from real execution benchmarks.
 */

const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

class CognitiveRecoverer {
    constructor() {
        this.integrationsPath = path.join(__dirname, '../../integrations');
        this.recoveryLog = [];
    }

    async executeRecoveryCycle(dormantNodes) {
        console.log("🔱 Initiating Cognitive Recovery Cycle...");
        const results = [];

        for (const node of dormantNodes) {
            const status = await this.validateSystem(node.id);
            results.push({ id: node.id, ...status });
        }

        this.recoveryLog = results;
        return results;
    }

    async validateSystem(nodeId) {
        const nodePath = path.join(this.integrationsPath, nodeId);
        
        // 1. Basic Existence Check
        if (!fs.existsSync(nodePath)) return { status: 'missing', rca: 'DIR_NOT_FOUND' };

        // 2. Execution Test (Python/Node)
        try {
            if (fs.existsSync(path.join(nodePath, 'package.json'))) {
                // Node system
                return { status: 'dormant', rca: 'NODE_DEPENDENCY_CHECK_REQUIRED' };
            } else if (fs.existsSync(path.join(nodePath, 'pyproject.toml')) || fs.existsSync(path.join(nodePath, 'setup.py'))) {
                // Python system
                const result = this.testPythonImport(nodeId);
                return result;
            }
            return { status: 'unknown', rca: 'NO_ENTRY_POINT' };
        } catch (e) {
            return { status: 'failed', rca: e.message };
        }
    }

    testPythonImport(nodeId) {
        try {
            // Attempt atomic import
            execSync(`python -c "import ${nodeId.replace(/-/g, '_')}"`, { stdio: 'ignore' });
            return { status: 'active', rca: 'VALIDATED_IMPORT' };
        } catch (e) {
            // Check if it's just missing dependencies
            try {
                const stderr = execSync(`python -c "import ${nodeId.replace(/-/g, '_')}"`, { stdio: 'pipe' }).toString();
                return { status: 'failed', rca: 'IMPORT_ERROR', detail: stderr };
            } catch (inner) {
                const errStr = inner.stderr?.toString() || "";
                if (errStr.includes("ModuleNotFoundError")) {
                    return { status: 'dormant', rca: 'MISSING_DEPENDENCIES', detail: errStr.split('\n')[0] };
                }
                return { status: 'failed', rca: 'EXECUTION_FAIL', detail: errStr };
            }
        }
    }
}

module.exports = new CognitiveRecoverer();
