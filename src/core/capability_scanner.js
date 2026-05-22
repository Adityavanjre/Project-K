/**
 * KALI Capability Scanner — v1.0 SOVEREIGN
 * Auto-discovers capabilities by scanning directories for manifest.json files.
 */

const fs = require('fs');
const path = require('path');

const SCAN_DIRS = [
    path.join(__dirname, '../../integrations'),
    path.join(__dirname, '../../') // Root for local_ai/swarm services
];

function scanCapabilities() {
    const capabilities = [];
    const scannedDirs = new Set();

    SCAN_DIRS.forEach(dir => {
        if (!fs.existsSync(dir)) return;
        
        // Scan 1 level deep for manifests
        const entries = fs.readdirSync(dir, { withFileTypes: true });
        
        // Check if the dir itself has a manifest (e.g. root)
        const rootManifestPath = path.join(dir, 'manifest.json');
        if (fs.existsSync(rootManifestPath) && !scannedDirs.has(rootManifestPath)) {
            scannedDirs.add(rootManifestPath);
            try {
                const manifest = JSON.parse(fs.readFileSync(rootManifestPath, 'utf8'));
                if (manifest.capabilities && Array.isArray(manifest.capabilities)) {
                    manifest.capabilities.forEach(cap => {
                        if (!capabilities.some(c => c.id === cap.id)) {
                            capabilities.push(cap);
                        }
                    });
                }
            } catch (e) {
                console.error(`[Scanner] Failed to parse ${rootManifestPath}: ${e.message}`);
            }
        }

        // Check subdirectories
        entries.forEach(entry => {
            if (entry.isDirectory()) {
                const manifestPath = path.join(dir, entry.name, 'manifest.json');
                if (fs.existsSync(manifestPath) && !scannedDirs.has(manifestPath)) {
                    scannedDirs.add(manifestPath);
                    try {
                        const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
                        if (manifest.capabilities && Array.isArray(manifest.capabilities)) {
                            manifest.capabilities.forEach(cap => {
                                if (!capabilities.some(c => c.id === cap.id)) {
                                    capabilities.push(cap);
                                }
                            });
                        }
                    } catch (e) {
                        console.error(`[Scanner] Failed to parse ${manifestPath}: ${e.message}`);
                    }
                }
            }
        });
    });

    console.log(`[CapabilityScanner] Discovered ${capabilities.length} UNIQUE capabilities.`);
    return capabilities;
}

module.exports = { scanCapabilities };
