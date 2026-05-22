/**
 * KALI Mission Engine — v1.0 SOVEREIGN
 * Manages the CRUD lifecycle and persistence of long-running autonomous missions.
 */

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const MISSIONS_FILE = path.join(__dirname, '../../data/missions.json');

// Ensure file exists
function ensureFile() {
    if (!fs.existsSync(MISSIONS_FILE)) {
        fs.writeFileSync(MISSIONS_FILE, JSON.stringify({ missions: [] }, null, 2));
    }
}

function loadMissions() {
    ensureFile();
    try {
        const raw = fs.readFileSync(MISSIONS_FILE, 'utf-8');
        return JSON.parse(raw).missions;
    } catch (e) {
        console.error(`[MissionEngine] Corrupt missions.json, resetting.`, e);
        return [];
    }
}

function saveMissions(missions) {
    ensureFile();
    fs.writeFileSync(MISSIONS_FILE, JSON.stringify({ missions }, null, 2));
}

/**
 * Generate a unique ID
 */
function generateId() {
    return 'm_' + crypto.randomBytes(4).toString('hex');
}

/**
 * Create a new Mission from a Goal and Strategy Plan
 */
function createMission(goalObj, planObj, scheduledFor = null) {
    const missions = loadMissions();
    
    const mission = {
        id: generateId(),
        goal: goalObj.goal,
        target: goalObj.target,
        priority: goalObj.priority,
        plan_id: planObj.plan_id,
        plan_type: planObj.type,
        steps: planObj.steps,
        current_step_idx: 0,
        status: scheduledFor ? 'scheduled' : 'pending', // pending | scheduled | running | paused | completed | failed
        scheduled_for: scheduledFor, // ISO String or null
        facts: {},
        logs: [],
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString()
    };

    missions.push(mission);
    saveMissions(missions);
    console.log(`[MissionEngine] Mission Created: ${mission.id} -> ${mission.goal}`);
    return mission;
}

/**
 * Retrieve a mission by ID
 */
function getMission(id) {
    const missions = loadMissions();
    return missions.find(m => m.id === id) || null;
}

/**
 * Get all missions optionally filtered by status
 */
function listMissions(status = null) {
    const missions = loadMissions();
    if (status) return missions.filter(m => m.status === status);
    return missions;
}

/**
 * Update mission status
 */
function updateStatus(id, status, errorMsg = null) {
    const missions = loadMissions();
    const idx = missions.findIndex(m => m.id === id);
    if (idx === -1) return false;

    missions[idx].status = status;
    missions[idx].updated_at = new Date().toISOString();
    
    if (errorMsg) {
        missions[idx].logs.push(`[${new Date().toISOString()}] ERROR: ${errorMsg}`);
    }

    saveMissions(missions);
    console.log(`[MissionEngine] Mission ${id} status -> ${status}`);
    return missions[idx];
}

/**
 * Progress mission to next step
 */
function advanceStep(id, stepFacts) {
    const missions = loadMissions();
    const idx = missions.findIndex(m => m.id === id);
    if (idx === -1) return false;

    const mission = missions[idx];
    mission.current_step_idx += 1;
    mission.facts = { ...mission.facts, ...stepFacts };
    mission.updated_at = new Date().toISOString();

    if (mission.current_step_idx >= mission.steps.length) {
        mission.status = 'completed';
    }

    saveMissions(missions);
    return mission;
}

/**
 * Log a message to the mission history
 */
function addLog(id, message) {
    const missions = loadMissions();
    const idx = missions.findIndex(m => m.id === id);
    if (idx === -1) return false;

    missions[idx].logs.push(`[${new Date().toISOString()}] ${message}`);
    saveMissions(missions);
    return true;
}

module.exports = {
    createMission,
    getMission,
    listMissions,
    updateStatus,
    advanceStep,
    addLog
};
