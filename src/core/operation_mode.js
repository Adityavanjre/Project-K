/**
 * KALI Operational Mode Engine — v1.0 SOVEREIGN
 * Governs the high-level focus state of KALI.
 */

const fs = require('fs');
const path = require('path');
const EventBus = require('./shared/event_bus');

const MODES = [
    'bug_hunting',
    'development',
    'learning',
    '3d_build',
    'automation'
];

class OperationMode {
    constructor() {
        this.currentMode = 'automation'; // Default
        this.configPath = path.join(__dirname, '../../data/op_mode.json');
        this._loadState();
    }

    _loadState() {
        if (fs.existsSync(this.configPath)) {
            try {
                const data = JSON.parse(fs.readFileSync(this.configPath, 'utf8'));
                if (MODES.includes(data.mode)) {
                    this.currentMode = data.mode;
                }
            } catch (e) {
                console.error("[OperationMode] Failed to load state.");
            }
        }
    }

    _saveState() {
        if (!fs.existsSync(path.dirname(this.configPath))) {
            fs.mkdirSync(path.dirname(this.configPath), { recursive: true });
        }
        fs.writeFileSync(this.configPath, JSON.stringify({ mode: this.currentMode, updated_at: new Date() }, null, 2));
    }

    setMode(modeStr) {
        if (!MODES.includes(modeStr)) return false;
        if (this.currentMode !== modeStr) {
            this.currentMode = modeStr;
            this._saveState();
            console.log(`[OperationMode] Switched to [${this.currentMode.toUpperCase()}]`);
            EventBus.emit('mode:switched', { mode: this.currentMode });
        }
        return true;
    }

    getMode() {
        return this.currentMode;
    }

    inferModeFromIntent(intentStr) {
        const lower = intentStr.toLowerCase();
        if (lower.includes('bounty') || lower.includes('hack') || lower.includes('scan') || lower.includes('exploit')) {
            return this.setMode('bug_hunting');
        } else if (lower.includes('code') || lower.includes('build') || lower.includes('refactor') || lower.includes('fix')) {
            return this.setMode('development');
        } else if (lower.includes('3d') || lower.includes('print') || lower.includes('cad') || lower.includes('model')) {
            return this.setMode('3d_build');
        } else if (lower.includes('learn') || lower.includes('read') || lower.includes('study')) {
            return this.setMode('learning');
        }
        return this.setMode('automation');
    }
}

module.exports = new OperationMode();
