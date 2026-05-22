/**
 * KALI OS — NATIVE MODULE LAYER (WEB COMPONENTS)
 * Each integrated repo is now a first-class DOM element.
 */

class KaliResearchModule extends HTMLElement {
    constructor() {
        super();
        this.attachShadow({ mode: 'open' });
    }

    connectedCallback() {
        this.render();
        // Register this module to the main app
        if (window.kaliApp) window.kaliApp.modules.set('research', this);
    }

    render() {
        // We use the global design tokens for styling
        const style = document.createElement('style');
        style.textContent = `
            @import "/static/css/tokens.css";
            .module-wrap { display: flex; flex-direction: column; gap: 12px; }
            .k-module-card { 
                background: var(--k-bg-card); 
                border: var(--k-border); 
                border-radius: var(--k-radius); 
                padding: 1rem; 
                backdrop-filter: blur(10px); 
            }
            .hud-label { color: var(--k-accent); font-family: var(--k-font-mono); font-size: 10px; margin-bottom: 8px; }
            .k-input { 
                background: var(--k-bg-deep); border: var(--k-border); color: white; 
                font-family: var(--k-font-mono); padding: 8px; width: 100%; border-radius: 4px; outline: none; 
            }
            .k-btn { 
                background: rgba(56, 189, 248, 0.1); border: 1px solid rgba(56, 189, 248, 0.4); 
                color: var(--k-accent); padding: 8px; cursor: pointer; text-transform: uppercase; font-size: 9px;
            }
        `;

        const container = document.createElement('div');
        container.className = 'module-wrap k-module-card';
        container.innerHTML = `
            <div class="hud-label">TACTICAL_SCANNER_v2 (HackingTool)</div>
            <input type="text" id="scan-target" class="k-input" placeholder="TARGET_IP">
            <button class="k-btn" id="run-scan">INITIATE_REAL_SCAN</button>
            <div id="status" style="font-size: 8px; color: #64748b; font-family: monospace; margin-top: 5px;">Awaiting uplink...</div>
        `;

        this.shadowRoot.append(style, container);
        this.shadowRoot.getElementById('run-scan').onclick = () => this.executeScan();
    }

    async executeScan() {
        console.log("UI_EVENT_TRIGGERED", "research", "nmap"); // TRACE 1
        const target = this.shadowRoot.getElementById('scan-target').value;
        const status = this.shadowRoot.getElementById('status');
        if (!target) return;

        status.textContent = `[SYSTEM] Spawning nmap for ${target}...`;
        console.log("API_CALL_INITIATED", "/api/possession/invoke", {module: 'hackingtool', target}); // TRACE 2
        
        try {
            const res = await fetch('/api/possession/invoke', {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify({module: 'hackingtool', action: 'nmap', params: {target}})
            });
            const data = await res.json();
            
            if (data.success) {
                status.textContent = "[SUCCESS] Scan complete.";
                // ACTUAL DATA BINDING: Update the global Proxy state
                window.KALI_STATE.research = { last_scan: data.output, active_vectors: 12 };
            }
        } catch (e) {
            status.textContent = "[FATAL] Backend offline. UI persistent.";
        }
    }
}

customElements.define('kali-research-module', KaliResearchModule);
