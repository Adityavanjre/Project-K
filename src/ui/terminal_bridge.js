/**
 * KALI Terminal Bridge — v1.0
 *
 * Acts as the SocketIO client on the Node.js side.
 * Receives raw tool output from RuntimeManager via EventEmitter,
 * strips ANSI codes, and relays structured events to the Flask
 * SocketIO server so the browser can render tool output inline.
 *
 * Event flow:
 *   RuntimeManager.emitOutput()
 *       → TerminalBridge.emit('output', payload)
 *           → Flask SocketIO @ http://localhost:5000
 *               → browser terminal_ui.js
 */

const { io } = require('socket.io-client');
const EventBus = require('../core/shared/event_bus');

// ─── ANSI STRIP ──────────────────────────────────────────────────────────────
// Remove all ANSI escape sequences so raw CLI output is clean text in the UI
const ANSI_RE = /\x1b\[[0-9;]*[a-zA-Z]|\x1b\][^\x07]*\x07|\x1b[^[\]]/g;
function stripAnsi(str) {
    return str.replace(ANSI_RE, '').replace(/\r/g, '');
}

class TerminalBridge {
    constructor() {
        this.socket = null;
        this.connected = false;
        this.queue = [];          // Buffer events while disconnected
        this.flaskUrl = 'http://localhost:5000';
        this._reconnectTimer = null;
    }

    /**
     * Connect to the Flask SocketIO server.
     * Called once by orchestrator.js on startup.
     */
    connect(flaskUrl = 'http://localhost:5000') {
        this.flaskUrl = flaskUrl;

        this.socket = io(this.flaskUrl, {
            reconnectionDelayMax: 5000,
            path: '/socket.io',
            transports: ['websocket', 'polling']
        });

        this.socket.on('connect', () => {
            this.connected = true;
            console.log(`[TerminalBridge] Connected to Flask @ ${this.flaskUrl}`);
            // Flush buffered events
            while (this.queue.length > 0) {
                this._send(this.queue.shift());
            }
        });

        this.socket.on('disconnect', (reason) => {
            this.connected = false;
            console.warn(`[TerminalBridge] Disconnected: ${reason}`);
        });

        this.socket.on('connect_error', (err) => {
            // Silent — Flask may not be running yet
        });

        // Listen for standard output events from anywhere on the EventBus
        EventBus.on('tool:output', (payload) => this._handleOutput(payload));
        EventBus.on('tool:done', (payload) => this.toolDone(payload.tool_id, payload.exit_code));
        
        // Relay system health
        EventBus.on('system:health', (payload) => {
            this._send({
                output_type: 'health',
                data: payload,
                timestamp: new Date().toISOString()
            });
        });

        // Relay domain switch
        EventBus.on('domain:switched', (payload) => {
            this._send({
                output_type: 'domain_switch',
                data: payload,
                timestamp: new Date().toISOString()
            });
        });
    }

    /**
     * Called by RuntimeManager for every stdout/stderr chunk.
     * payload: { source: toolId, type: 'stream'|'log', data: string, status: string, timestamp }
     */
    _handleOutput(payload) {
        const clean = stripAnsi(payload.data || '');
        // Split multi-line chunks into individual line events
        const lines = clean.split('\n').filter(l => l.trim().length > 0);

        for (const line of lines) {
            const event = {
                tool_id: payload.source,
                line,
                output_type: payload.type,     // 'stream' | 'log'
                status: payload.status,         // 'success' | 'error'
                timestamp: payload.timestamp || new Date().toISOString()
            };
            this._send(event);
        }
    }

    /**
     * Emit a tool_done event when a process exits.
     */
    toolDone(toolId, exitCode) {
        this._send({
            tool_id: toolId,
            line: `[Process exited with code ${exitCode}]`,
            output_type: 'done',
            status: exitCode === 0 ? 'success' : 'error',
            timestamp: new Date().toISOString()
        });
    }

    /**
     * Send a structured event to Flask. Buffers if disconnected.
     */
    _send(event) {
        if (this.connected && this.socket) {
            this.socket.emit('tool_output', event);
        } else {
            // Buffer up to 200 lines
            if (this.queue.length < 200) {
                this.queue.push(event);
            }
        }
    }
}

// Singleton
module.exports = new TerminalBridge();
