/**
 * KALI Scheduler — v1.0 SOVEREIGN
 * Scans for scheduled missions and moves them to pending when their time arrives.
 */

const MissionEngine = require('./mission_engine');

function checkSchedule() {
    const scheduledMissions = MissionEngine.listMissions('scheduled');
    const now = Date.now();

    for (const mission of scheduledMissions) {
        if (!mission.scheduled_for) continue;
        
        const targetTime = new Date(mission.scheduled_for).getTime();
        if (now >= targetTime) {
            console.log(`[Scheduler] Mission ${mission.id} reached scheduled time. Moving to pending.`);
            MissionEngine.addLog(mission.id, 'Scheduled time reached. Queuing for execution.');
            MissionEngine.updateStatus(mission.id, 'pending');
        }
    }
}

function init() {
    console.log("[Scheduler] Initialized.");
    setInterval(checkSchedule, 10000); // Check every 10 seconds
}

module.exports = { init };
