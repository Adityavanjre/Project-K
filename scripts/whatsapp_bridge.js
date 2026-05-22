/**
 * KALI WhatsApp Bridge — scripts/whatsapp_bridge.js
 * SOVEREIGN: Channel Gateway Layer
 *
 * A local Node.js microservice that bridges WhatsApp <-> KALI's Python gateway.
 * Uses whatsapp-web.js (the same protocol as WhatsApp Web in your browser).
 *
 * HOW IT WORKS:
 *   1. Run: node scripts/whatsapp_bridge.js
 *   2. A QR code appears in the terminal
 *   3. Open WhatsApp on your phone -> Linked Devices -> Scan QR
 *   4. Done. KALI is now a WhatsApp contact you can message from anywhere.
 *
 * No Twilio. No fees. Works globally via Meta's servers.
 * KALI's machine only needs internet access.
 *
 * SETUP:
 *   cd scripts
 *   npm install whatsapp-web.js express qrcode-terminal
 *   node whatsapp_bridge.js
 */

const { Client, LocalAuth, MessageMedia } = require('whatsapp-web.js');
const express = require('express');
const qrcode = require('qrcode-terminal');
const fs = require('fs');
const path = require('path');

// ─── Configuration ────────────────────────────────────────────────────────────

const BRIDGE_PORT = process.env.BRIDGE_PORT || 3001;
const KALI_GATEWAY_URL = process.env.KALI_GATEWAY_URL || 'http://localhost:8001/channel/whatsapp';
const SESSION_DIR = path.join(__dirname, '..', '.wwa_session');

// ─── WhatsApp Client ──────────────────────────────────────────────────────────

const client = new Client({
    authStrategy: new LocalAuth({
        dataPath: SESSION_DIR,
        clientId: 'kali-gateway'
    }),
    puppeteer: {
        headless: true,
        args: [
            '--no-sandbox',
            '--disable-setuid-sandbox',
            '--disable-dev-shm-usage',
            '--disable-gpu',
        ]
    }
});

let bridgeState = 'INITIALIZING';
let qrReady = false;

// ─── WhatsApp Events ──────────────────────────────────────────────────────────

client.on('qr', (qr) => {
    console.log('\n[KALI WhatsApp Bridge] QR Code ready. Scan with WhatsApp > Linked Devices:\n');
    qrcode.generate(qr, { small: true });
    bridgeState = 'AWAITING_SCAN';
    qrReady = true;
});

client.on('ready', () => {
    console.log('\n[KALI WhatsApp Bridge] CONNECTED. KALI is now on WhatsApp.\n');
    bridgeState = 'CONNECTED';
    qrReady = false;
});

client.on('authenticated', () => {
    console.log('[KALI WhatsApp Bridge] Authenticated. Session saved.');
    bridgeState = 'AUTHENTICATED';
});

client.on('auth_failure', (msg) => {
    console.error('[KALI WhatsApp Bridge] Auth failed:', msg);
    bridgeState = 'AUTH_FAILED';
});

client.on('disconnected', (reason) => {
    console.warn('[KALI WhatsApp Bridge] Disconnected:', reason);
    bridgeState = 'DISCONNECTED';
});

// ─── Inbound Message Handler ──────────────────────────────────────────────────

client.on('message', async (message) => {
    try {
        const payload = {
            from: message.from,
            to: message.to,
            body: message.body,
            type: message.type,
            fromMe: message.fromMe,
            timestamp: message.timestamp,
            hasMedia: message.hasMedia,
        };

        // Download media if present
        if (message.hasMedia && ['image', 'audio', 'document'].includes(message.type)) {
            try {
                const media = await message.downloadMedia();
                if (media) {
                    // Save to temp file so KALI can read it
                    const ext = media.mimetype.split('/')[1].split(';')[0];
                    const tmpPath = path.join(__dirname, '..', 'data', `media_${Date.now()}.${ext}`);
                    fs.mkdirSync(path.dirname(tmpPath), { recursive: true });
                    fs.writeFileSync(tmpPath, Buffer.from(media.data, 'base64'));
                    payload.mediaUrl = `file://${tmpPath}`;
                    payload.mediaMime = media.mimetype;
                }
            } catch (mediaErr) {
                console.error('[Bridge] Media download failed:', mediaErr.message);
            }
        }

        // Forward to KALI's gateway
        const response = await fetch(KALI_GATEWAY_URL, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload),
            signal: AbortSignal.timeout(120000)  // 2 min timeout for KALI's response
        });

        if (!response.ok) {
            console.error('[Bridge] KALI gateway error:', response.status);
        }

    } catch (err) {
        console.error('[Bridge] Message handling error:', err.message);
    }
});

// ─── Express REST API (for KALI Python to call) ───────────────────────────────

const app = express();
app.use(express.json({ limit: '50mb' }));

/**
 * GET /status
 * Returns bridge connection state.
 * KALI's WhatsAppChannel.connect() calls this.
 */
app.get('/status', (req, res) => {
    res.json({
        state: bridgeState,
        qr_ready: qrReady,
        bridge: 'KALI WhatsApp Bridge v1.0'
    });
});

/**
 * POST /send
 * Send a text message. Called by KALI's WhatsAppChannel.send()
 * Body: { "to": "919876543210@c.us", "message": "Hello from KALI" }
 */
app.post('/send', async (req, res) => {
    const { to, message } = req.body;

    if (!to || !message) {
        return res.status(400).json({ error: 'Missing to or message' });
    }

    if (bridgeState !== 'CONNECTED') {
        return res.status(503).json({ error: `Bridge not ready. State: ${bridgeState}` });
    }

    try {
        await client.sendMessage(to, message);
        console.log(`[Bridge] Sent to ${to}: ${message.substring(0, 60)}...`);
        res.json({ success: true });
    } catch (err) {
        console.error('[Bridge] Send error:', err.message);
        res.status(500).json({ error: err.message });
    }
});

/**
 * POST /send-media
 * Send an image or file. Called by KALI for 3D diagrams, blueprints etc.
 * Body: multipart/form-data with 'media' file and 'to', 'caption' fields
 */
app.post('/send-media', async (req, res) => {
    try {
        const { to, caption, mediaPath } = req.body;
        if (!to || !mediaPath) {
            return res.status(400).json({ error: 'Missing to or mediaPath' });
        }

        const media = MessageMedia.fromFilePath(mediaPath);
        await client.sendMessage(to, media, { caption: caption || '' });
        res.json({ success: true });
    } catch (err) {
        console.error('[Bridge] Media send error:', err.message);
        res.status(500).json({ error: err.message });
    }
});

// ─── Start ────────────────────────────────────────────────────────────────────

app.listen(BRIDGE_PORT, () => {
    console.log(`[KALI WhatsApp Bridge] REST API on port ${BRIDGE_PORT}`);
    console.log(`[KALI WhatsApp Bridge] Forwarding messages to: ${KALI_GATEWAY_URL}`);
    console.log('[KALI WhatsApp Bridge] Initializing WhatsApp client...\n');
});

client.initialize();
