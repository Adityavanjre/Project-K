/**
 * KALI Purifier — v1.0 SOVEREIGN
 * Codebase cleanup enforcer. Scans for orphaned manifests or unused code.
 */

const fs = require('fs');
const path = require('path');
const { scanCapabilities } = require('./capability_scanner');

class Purifier {
    constructor() {}

    runPurge() {
        console.log("[Purifier] Scanning for stale dependencies and dead capabilities...");
        const capabilities = scanCapabilities();
        const activeDirs = new Set(capabilities.map(c => path.resolve(c.working_directory || '.')));

        // Scan integrations folder
        const integrationsDir = path.join(__dirname, '../../integrations');
        if (fs.existsSync(integrationsDir)) {
            const dirs = fs.readdirSync(integrationsDir, { withFileTypes: true });
            dirs.forEach(dirent => {
                if (dirent.isDirectory()) {
                    const fullPath = path.join(integrationsDir, dirent.name);
                    const manifestPath = path.join(fullPath, 'manifest.json');
                    
                    if (!fs.existsSync(manifestPath)) {
                        console.warn(`[Purifier] Notice: Directory ${dirent.name} has no manifest.json. Consider archiving.`);
                    }
                }
            });
        }
        console.log("[Purifier] Codebase purity check complete.");
    }
}

module.exports = new Purifier();
