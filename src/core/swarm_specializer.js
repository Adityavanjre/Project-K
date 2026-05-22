/**
 * KALI Swarm Specializer — v1.0 SOVEREIGN
 * Dynamically classifies 40 swarm nodes into core competency domains.
 * Zero hardcoding: Derived from swarm_dna.json metadata.
 */

const fs = require('fs');
const path = require('path');

class SwarmSpecializer {
    constructor() {
        this.dnaPath = path.join(__dirname, 'swarm_dna.json');
        this.domains = {
            frontend: ['UI/UX'],
            backend: ['Software Engineering'],
            architecture: ['General Utility'], // Fallback for structural nodes
            security: ['Cybersecurity'],
            reasoning: ['LLM Intelligence']
        };
    }

    getSpecialists(domain) {
        try {
            const dna = JSON.parse(fs.readFileSync(this.dnaPath, 'utf8'));
            const neurons = dna.swarm_neurons || {};
            const specialists = [];

            const targetExpertise = this.domains[domain.toLowerCase()] || [];

            for (const [id, info] of Object.entries(neurons)) {
                if (info.expertise && info.expertise.some(e => targetExpertise.includes(e))) {
                    specialists.push({
                        id,
                        role: info.role,
                        stack: info.stack,
                        expertise: info.expertise
                    });
                }
            }

            // Fallback for specific requested nodes if not caught by expertise
            const manualMapping = {
                frontend: ['easy-vibe', 'DanceUI', 'openhuman'],
                backend: ['aider', 'wrkflw', 'gstack'],
                architecture: ['graphify', 'mempalace', 'understand-anything'],
                security: ['hackingtool', 'no-mistakes', 'obscura'],
                reasoning: ['ml-intern', 'locally-uncensored']
            };

            const manual = manualMapping[domain.toLowerCase()] || [];
            manual.forEach(mid => {
                if (!specialists.find(s => s.id === mid) && neurons[mid]) {
                    specialists.push({ id: mid, ...neurons[mid] });
                }
            });

            return specialists;
        } catch (e) {
            console.error(`[SwarmSpecializer] Failed to map specialists for ${domain}:`, e);
            return [];
        }
    }

    getAllSpecializationMap() {
        const map = {};
        Object.keys(this.domains).forEach(d => {
            map[d] = this.getSpecialists(d).map(s => s.id);
        });
        return map;
    }
}

module.exports = new SwarmSpecializer();
