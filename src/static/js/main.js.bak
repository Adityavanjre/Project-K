/**
 * K.A.L.I. Frontend Logic
 */

class Archives {
    constructor() {
        this.container = document.getElementById('archives-grid');
    }

    async loadArchives() {
        if (!this.container) return;

        this.container.innerHTML = `
            <div class="col-span-full flex flex-col items-center justify-center text-cyan-400 animate-pulse">
                <i class="fas fa-spinner fa-spin text-4xl mb-4"></i>
                <p>SYNCING WITH MEMORY CORE...</p>
            </div>
        `;

        try {
            const res = await fetch('/api/history');
            const json = await res.json();

            if (json.success) {
                this.renderCards(json.data);
            } else {
                this.showError("Access Denied: " + json.error);
            }
        } catch (e) {
            this.showError("Connection Failure: " + e.message);
        }
    }

    renderCards(sessions) {
        if (sessions.length === 0) {
            this.container.innerHTML = `
                <div class="col-span-full flex flex-col items-center justify-center text-cyan-900/40">
                    <i class="fas fa-folder-open text-6xl mb-4"></i>
                    <p>MEMORY BANKS EMPTY</p>
                </div>
            `;
            return;
        }

        this.container.innerHTML = sessions.map(session => `
            <div class="bg-cyan-900/10 border border-cyan-500/20 p-4 hover:bg-cyan-900/30 transition-all cursor-pointer group"
                onclick="window.app.restoreSession('${session.session_id}')">
                <div class="flex justify-between items-start mb-2">
                    <div class="p-2 bg-cyan-900/50 rounded text-cyan-400 group-hover:text-white transition-colors">
                        <i class="fas fa-cube"></i>
                    </div>
                    <span class="text-[10px] font-mono text-cyan-600">${new Date(session.timestamp).toLocaleDateString()}</span>
                </div>
                <h3 class="text-cyan-100 font-bold mb-1 truncate">${session.topic || "Unknown Session"}</h3>
                <div class="text-[10px] text-cyan-500 font-mono">ID: ${session.session_id.substring(0, 8)}...</div>
            </div>
        `).join('');
    }

    showError(msg) {
        this.container.innerHTML = `<div class="text-red-400 col-span-full text-center">${msg}</div>`;
    }
}

class App {
    constructor() {
        this.mode = 'learn';
        this.chat = new Chat();
        this.visualizer = new Visualizer();
        this.mentor = new ProjectMentor();
        this.archives = new Archives();
        this.agent = new AgentMode();
        this.core = new CoreMode();
        this.voice = new VoiceModule();

        window.addEventListener('modeChanged', (e) => this.switchMode(e.detail.mode));

        // Initial System Check Sound
        // setTimeout(() => this.voice.speak("System online. Ready for input, Sir."), 1000);

        // Boot Sequence Cleanup
        setTimeout(() => {
            const boot = document.getElementById('boot-sequence');
            if (boot) {
                gsap.to(boot, {
                    opacity: 0,
                    duration: 1,
                    onComplete: () => boot.remove()
                });
            }
        }, 2500); // Wait for typing effect to finish
    }

    switchMode(newMode) {
        this.mode = newMode;

        // Hide all sections
        this.modes = ['learn', 'visual', 'build', 'archives', 'agent', 'core'];
        this.modes.forEach(m => {
            const el = document.getElementById(`mode-${m}`);
            if (el) {
                if (m === newMode) {
                    el.classList.remove('hidden');
                    gsap.fromTo(el, { opacity: 0, scale: 0.98 }, { opacity: 1, scale: 1, duration: 0.3, ease: "power2.out" });

                    // Trigger specific loads
                    if (m === 'archives') this.archives.loadArchives();
                } else {
                    el.classList.add('hidden');
                }
            }

            // Sync nav buttons
            const nav = document.getElementById(`nav-${m}`);
            if (nav) {
                if (m === newMode) {
                    nav.classList.add('bg-blue-600', 'text-white', 'shadow-lg', 'shadow-blue-500/20');
                    nav.classList.remove('text-slate-400', 'hover:text-white', 'hover:bg-white/5');
                    
                    if (m === 'core') {
                        nav.classList.remove('bg-blue-600');
                        nav.classList.add('bg-amber-600', 'text-white', 'border-amber-400');
                    }
                } else {
                    nav.classList.remove('bg-blue-600', 'bg-amber-600', 'text-white', 'shadow-lg', 'shadow-blue-500/20', 'border-amber-400');
                    nav.classList.add('text-slate-400');
                }
            }
        });

        // Resize Three.js if entering visual mode
        if (newMode === 'visual') {
            setTimeout(() => this.visualizer.resizeCanvas(), 100);
        }
    }

    startBuildFromChat(msgId) {
        const msgEl = document.getElementById(msgId);
        if (!msgEl) return;

        // Get text and clean it (remove the "> " prefix if present)
        let text = msgEl.innerText.replace(/^>\s*/, '').trim();

        // Remove the "BUILD THIS" button text if it was included in innerText
        text = text.replace(/\[ 🛠️ BUILD THIS \]$/, '').trim();

        // Switch to Project Mentor
        document.getElementById('nav-build').click();

        // Wait a small amount for transition
        setTimeout(() => {
            const titleInput = document.getElementById('build-title');
            const descInput = document.getElementById('build-description');

            // Heuristic for Title: First 4-6 words
            const title = text.split(' ').slice(0, 5).join(' ') + '...';

            if (titleInput) titleInput.value = title;
            if (descInput) descInput.value = text;

            // Optional: visual cue
            if (descInput) {
                descInput.classList.add('bg-cyan-900/50');
                setTimeout(() => descInput.classList.remove('bg-cyan-900/50'), 500);
            }
        }, 100);
    }


    // Placeholder for restoration logic (for now just logs)
    // Restoration Protocol
    async restoreSession(sessionId) {
        console.log("Restoring session:", sessionId);

        // Show loading state
        this.switchMode('learn'); // Switch to chat view to show progress
        const loadingId = this.chat.addMessage('> INITIATING TEMPORAL RESTORATION...', 'ai', true);

        try {
            const res = await fetch(`/api/history/${sessionId}`);
            const json = await res.json();

            if (json.success) {
                // Clear current chat
                this.chat.container.innerHTML = '';

                // Replay history
                const messages = json.data;
                for (const msg of messages) {
                    // Check if message contains JSON (Blueprint)
                    if (msg.role === 'model' && msg.content.trim().startsWith('{')) {
                        try {
                            const projectData = JSON.parse(msg.content);
                            // If it's a project plan, render it in Build Mode
                            if (projectData.project_name) {
                                this.switchMode('build'); // Switch to build mode for blueprints
                                this.mentor.renderPlan(projectData);
                            }
                        } catch (e) {
                            // Not JSON, render as text
                            this.chat.addMessage(msg.content, 'ai');
                        }
                    } else {
                        // Standard Message
                        this.chat.addMessage(msg.content, msg.role === 'user' ? 'user' : 'ai');
                    }
                }

                if (this.voice) {
                    this.voice.speak("Session restored successfully, Sir.");
                }

            } else {
                this.chat.addMessage("RESTORATION FAILED: " + json.error, 'ai');
            }
        } catch (e) {
            console.error(e);
            this.chat.addMessage("SYSTEM ERROR: " + e.message, 'ai');
        }
    }

    showEvolutionNotification(skillName) {
        const toast = document.createElement('div');
        toast.className = 'fixed bottom-24 left-1/2 -translate-x-1/2 bg-cyan-900/80 border border-cyan-400 px-6 py-3 rounded-sm backdrop-blur-md z-[100] animate-bounce shadow-[0_0_20px_rgba(34,211,238,0.3)]';
        toast.innerHTML = `<div class="text-cyan-400 text-xs font-bold tracking-widest flex items-center gap-2">
            <i class="fas fa-microchip"></i> KALI EVOLUTION: Manifested New Skill [${skillName}]
        </div>`;
        document.body.appendChild(toast);
        setTimeout(() => {
            gsap.to(toast, { opacity: 0, y: 20, duration: 0.5, onComplete: () => toast.remove() });
        }, 4000);
        
        if (this.voice) {
            this.voice.speak(`Organic intelligence growth detected. Mastered new skill: ${skillName.replace('.py', '').replace('_', ' ')}.`);
        }
    }

    async showTetherModal() {
        const modal = document.getElementById('tether-modal');
        const urlEl = document.getElementById('tether-url');
        const qrContainer = document.getElementById('tether-qr-container');
        
        if (!modal) return;
        modal.classList.remove('hidden');
        
        try {
            const res = await fetch('/api/network');
            const data = await res.json();
            
            if (data.success) {
                const url = data.url;
                urlEl.innerText = url;
                // Using a public QR API for the tether bridge
                qrContainer.innerHTML = `
                    <div class="bg-white p-2 border-2 border-blue-500 rounded-sm">
                        <img src="https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=${encodeURIComponent(url)}" 
                             alt="KALI TETHER QR" class="w-40 h-40">
                    </div>
                `;
            } else {
                urlEl.innerText = "BRIDGE_ERROR: INTERNAL_FAIL";
            }
        } catch (e) {
            urlEl.innerText = "BRIDGE_OFFLINE: NETWORK_BLOCK";
        }
    }

    // Phase 30: Quick Chat for Predictive Intent
    quickChat(text) {
        const input = document.getElementById('chat-input');
        if (input) {
            input.value = text;
            input.focus();
            document.getElementById('chat-form').dispatchEvent(new Event('submit'));
        }
    }

    // Phase 34: Neural HUD Mode Controller
    setHudMode(mode) {
        const hud = document.getElementById('neural-hud');
        if (!hud) return;

        // Reset classes
        hud.classList.remove('glow-protocol-eng', 'glow-protocol-res', 'glow-protocol-sov');
        const btns = document.querySelectorAll('.mode-btn');
        btns.forEach(b => b.classList.remove('active'));

        // Apply new mode
        if (mode === 'engineering') {
            hud.classList.add('glow-protocol-eng');
            const btn = document.getElementById('btn-mode-eng');
            if(btn) btn.classList.add('active');
        } else if (mode === 'research') {
            hud.classList.add('glow-protocol-res');
            const btn = document.getElementById('btn-mode-res');
            if(btn) btn.classList.add('active');
        } else if (mode === 'sovereign') {
            hud.classList.add('glow-protocol-sov');
            const btn = document.getElementById('btn-mode-sov');
            if(btn) btn.classList.add('active');
        }
        
        console.log(`KALI Singularity: Interface Shifted to ${mode.toUpperCase()} protocol.`);
    }
}

class VoiceModule {
    constructor() {
        this.recognition = null;
        this.isListening = false;
        this.speechEnabled = true;
        this.synth = window.speechSynthesis;
        this.isSpeaking = false;
        this.currentUtterance = null;

        this.initRecognition();
        this.setupUI();
    }

    initRecognition() {
        if ('webkitSpeechRecognition' in window) {
            this.recognition = new webkitSpeechRecognition();
            this.recognition.continuous = false;
            this.recognition.lang = 'en-US';

            this.recognition.onstart = () => {
                this.isListening = true;
                this.updateBtnState(true);
                if(window.app && window.app.hud) window.app.hud.setVocalState('listening');
                this.synth.cancel();
            };

            this.recognition.onend = () => {
                this.isListening = false;
                this.updateBtnState(false);
                if(window.app && window.app.hud) window.app.hud.setVocalState('standby');
            };

            this.recognition.onresult = (event) => {
                const transcript = event.results[0][0].transcript;
                this.handleVoiceInput(transcript);
            };
        } else {
            console.log("Speech Recognition not supported in this browser.");
        }
    }

    setupUI() {
        const btn = document.getElementById('btn-voice-chat');
        if (btn && this.recognition) {
            btn.addEventListener('click', () => {
                if (this.isListening) this.recognition.stop();
                else this.recognition.start();
            });
        }
    }

    updateBtnState(active) {
        const btn = document.getElementById('btn-voice-chat');
        if (!btn) return;

        if (active) {
            btn.classList.add('bg-red-500/20', 'animate-pulse', 'border-red-500');
            btn.innerHTML = '<i class="fas fa-circle text-red-500"></i>';
        } else {
            btn.classList.remove('bg-red-500/20', 'animate-pulse', 'border-red-500');
            btn.innerHTML = '<i class="fas fa-microphone"></i>';
        }
    }

    handleVoiceInput(text) {
        console.log("Voice Command:", text);
        const input = document.getElementById('chat-input');
        if (input) {
            input.value = text;
            document.getElementById('chat-form').dispatchEvent(new Event('submit'));
        }
    }

    speak(text) {
        if (!this.speechEnabled || !text) return;
        this.stop();

        try {
            const cleanText = text.replace(/>/g, '').replace(/\*/g, '').replace(/_/g, '');
            this.currentUtterance = new SpeechSynthesisUtterance(cleanText);

            this.currentUtterance.rate = 1.0;
            this.currentUtterance.pitch = 0.9;
            this.currentUtterance.volume = 1.0;

            this.currentUtterance.onstart = () => {
                this.isSpeaking = true;
                if(window.app && window.app.hud) window.app.hud.setVocalState('speaking');
            };
            this.currentUtterance.onend = () => {
                this.isSpeaking = false;
                if(window.app && window.app.hud) window.app.hud.setVocalState('standby');
            };
            this.currentUtterance.onerror = (e) => {
                console.error("Vocal failure:", e);
                this.isSpeaking = false;
                if(window.app && window.app.hud) window.app.hud.setVocalState('standby');
            };

            const voices = this.synth.getVoices();
            if (voices.length > 0) {
                const preferred = voices.find(v => v.name.includes('Google US English') || v.name.includes('David') || v.name.includes('Male'));
                if (preferred) this.currentUtterance.voice = preferred;
            }

            this.synth.speak(this.currentUtterance);
        } catch (e) {
            console.warn("Audio Output Failed:", e);
        }
    }

    stop() {
        if (this.synth.speaking) {
            this.synth.cancel();
            this.isSpeaking = false;
        }
    }
}
class Chat {
    constructor() {
        this.form = document.getElementById('chat-form');
        this.input = document.getElementById('chat-input');
        this.container = document.getElementById('chat-messages');
        this.fileInput = document.getElementById('image-upload');

        if (this.form) {
            this.form.addEventListener('submit', (e) => this.handleSubmit(e));
        }

        if (this.fileInput) {
            this.fileInput.addEventListener('change', (e) => this.handleImageUpload(e));
        }
    }

    async handleImageUpload(e) {
        const file = e.target.files[0];
        if (!file) return;

        // Reset input
        this.fileInput.value = '';

        // Display "Uploading" user message
        const msgId = this.addMessage(`[UPLOADING VISUAL DATA: ${file.name}]`, 'user');

        // Show scanning effect
        const loadingId = this.addMessage('> PROCESSING VISUAL MATRIX...', 'ai', true);

        try {
            const formData = new FormData();
            formData.append('image', file);

            const res = await fetch('/api/analyze_image', {
                method: 'POST',
                body: formData
            });
            const data = await res.json();

            // Remove Loading
            document.getElementById(loadingId).remove();

            if (data.success) {
                this.addMessage(data.analysis, 'ai');
                if (window.app && window.app.voice) {
                    window.app.voice.speak("Visual scan complete. I have analyzed the data, Sir.");
                }
            } else {
                this.addMessage("Visual Analysis Failed: " + data.error, 'ai');
            }

        } catch (err) {
            document.getElementById(loadingId).innerText = "> SYSTEM ERROR: " + err.message;
        }
    }

    async handleSubmit(e) {
        e.preventDefault();
        
        // Phase 36: Interrupt speech on new query
        if (window.app.voice && window.app.voice.synth) window.app.voice.synth.cancel();
        if (window.app.hud) window.app.hud.setVocalState('standby');
        
        const msg = this.input.value.trim();
        if (!msg) return;

        // Add User Message
        this.addMessage(msg.toUpperCase(), 'user');
        this.input.value = '';

        // Show scanning effect
        const loadingId = this.addMessage('> PROCESSING REQUEST...', 'ai', true);
        console.log("Sending request to /ask:", msg);

        try {
            const res = await fetch('/ask', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ question: msg })
            });
            console.log("Response status:", res.status);

            if (!res.ok) throw new Error(`HTTP Error: ${res.status}`);

            const data = await res.json();
            console.log("Data received:", data);

            // Remove Loading
            const loader = document.getElementById(loadingId);
            if (loader) loader.remove();

            this.addMessage(data.response, 'ai', false, data.can_build, data.report_ready);

            // Phase 24: Evolution Log
            if (data.manifested_skill && window.app) {
                window.app.showEvolutionNotification(data.manifested_skill);
            }

            // Try to speak it if short enough (or always for KALI feel)
            if (data.response.length < 500 && window.app && window.app.voice) {
                window.app.voice.speak(data.response);
            }

        } catch (err) {
            console.error("Chat Error:", err);
            const loader = document.getElementById(loadingId);
            if (loader) loader.innerText = "> SYSTEM ERROR: " + err.message;
        }
    }

    addMessage(text, type, isLoading = false, canBuild = false, reportReady = false) {
        const id = 'msg-' + Date.now();
        const align = type === 'user' ? 'self-end text-right' : 'self-start text-left';
        // KALI Style: AI is Cyan, User is White/Grey
        const color = type === 'user' ? 'text-white border-r-2 border-white pr-4' : 'text-cyan-400 border-l-2 border-cyan-400 pl-4';

        const div = document.createElement('div');
        div.id = id;
        div.className = `max-w-[80%] py-2 ${align} ${color} mb-2 font-mono text-sm tracking-wide`;

        if (isLoading) {
            div.innerHTML = `<span class="animate-pulse">> ${text}</span>`;
        } else {
            // Typewriter effect could be added here
            div.innerHTML = text.replace(/\n/g, '<br>').replace(/\*\*(.*?)\*\*/g, '<b class="text-cyan-200">$1</b>');

            // Appending "Build This" action only if intent matches
            if (canBuild) {
                const btnId = 'btn-' + id;
                // Logic for building could go here
            }

            if (reportReady) {
                div.innerHTML += `
                    <div class="mt-2 flex flex-wrap gap-2 justify-start" data-msg="${text.replace(/"/g, '&quot;')}">
                        <button onclick="window.app.chat.downloadReport(this.parentElement.dataset.msg)" 
                                class="text-[10px] bg-cyan-900/50 hover:bg-cyan-500 hover:text-black border border-cyan-500/50 rounded px-2 py-1 transition-all">
                            <i class="fas fa-file-pdf"></i> GENERATE PDF REPORT
                        </button>
                        <button onclick="let c=prompt('Enter Ground Truth Correction:'); if(c) window.submitCorrection(this.parentElement.dataset.msg, '...', c)" 
                                class="text-[10px] bg-red-900/20 hover:bg-red-500 hover:text-black border border-red-500/30 rounded px-2 py-1 transition-all">
                            <i class="fas fa-brain"></i> CORRECT KALI
                        </button>
                    </div>
                `;
            } else if (type === 'ai') {
                div.innerHTML += `
                    <div class="mt-2 text-right" data-msg="${text.replace(/"/g, '&quot;')}">
                        <button onclick="let c=prompt('Enter Ground Truth Correction:'); if(c) window.submitCorrection(this.parentElement.dataset.msg, '...', c)" 
                                class="text-[8px] opacity-30 hover:opacity-100 hover:text-red-400 transition-all font-mono">
                            [CORRECT_KALI]
                        </button>
                    </div>
                `;
            }
        }

        // Smart Scroll Logic:
        // Calculate tolerance (are we near the bottom?)
        const tolerance = 50;
        const isNearBottom = this.container.scrollHeight - this.container.scrollTop - this.container.clientHeight <= tolerance;

        this.container.appendChild(div);

        // If user was at bottom, scroll; otherwise let them read history.
        if (isNearBottom || type === 'user') {
            // If the message is really long (e.g. > 500px), scroll to its TOP so user can read from start.
            // Otherwise, scroll to bottom to show it fully.
            // Using a slight delay to ensure rendering size is correct.
            setTimeout(() => {
                if (div.offsetHeight > 300) {
                    div.scrollIntoView({ behavior: 'smooth', block: 'start' });
                } else {
                    // Phase 16: Report Export Button
                    if (reportReady) {
                        const reportBtn = document.createElement('button');
                        reportBtn.className = 'glass-btn text-[10px] mt-2 flex items-center gap-2';
                        reportBtn.innerHTML = '<i class="fas fa-file-pdf"></i> GENERATE PDF REPORT';
                        reportBtn.onclick = () => this.downloadReport(reportText);
                        div.appendChild(reportBtn);
                    }

                    this.container.scrollTop = this.container.scrollHeight;
                }
            }, 100);
        }

        return id;
    }

    async downloadReport(content) {
        try {
            const response = await fetch('/api/export_report', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    title: "KALI Research Summary",
                    content: content
                })
            });
            if (response.ok) {
                const blob = await response.blob();
                const url = window.URL.createObjectURL(blob);
                const a = document.createElement('a');
                a.href = url;
                a.download = `KALI_Report_${new Date().getTime()}.pdf`;
                document.body.appendChild(a);
                a.click();
                a.remove();
            }
        } catch (e) {
            console.error("Report Download Failed:", e);
        }
    }
}

class Visualizer {
    constructor() {
        this.scene = null;
        this.camera = null;
        this.renderer = null;
        this.currentStep = 0;
        this.steps = [];
        this.audio = new Audio();

        this.initThreeJS();
        this.parts = new PartsLibrary(this.scene, THREE);
        this.setupBindings();
    }

    initThreeJS() {
        const canvasContainer = document.getElementById('three-canvas');
        if (!canvasContainer) return;

        this.scene = new THREE.Scene();
        // Transparent background to see the gradient in CSS
        this.scene.background = null;

        // Lighting
        const ambient = new THREE.AmbientLight(0x00f3ff, 0.5); // Cyan ambient
        this.scene.add(ambient);

        const directional = new THREE.DirectionalLight(0xffffff, 2);
        directional.position.set(5, 10, 7);
        this.scene.add(directional);

        // Grid Helper (Holographic floor)
        const grid = new THREE.GridHelper(20, 20, 0x00f3ff, 0x003344);
        grid.position.y = -2;
        this.scene.add(grid);

        // Camera
        this.camera = new THREE.PerspectiveCamera(75, canvasContainer.clientWidth / canvasContainer.clientHeight, 0.1, 1000);
        this.camera.position.z = 8;
        this.camera.position.y = 2;
        this.camera.lookAt(0, 0, 0);

        // Renderer
        this.renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
        this.renderer.setSize(canvasContainer.clientWidth, canvasContainer.clientHeight);
        canvasContainer.appendChild(this.renderer.domElement);

        // Controls
        const controls = new THREE.OrbitControls(this.camera, this.renderer.domElement);
        controls.enableDamping = true;
        controls.autoRotate = true;
        controls.autoRotateSpeed = 0.5;

        this.controls = controls;

        // Animation Loop
        const animate = () => {
            requestAnimationFrame(animate);
            controls.update();
            this.renderer.render(this.scene, this.camera);
        };
        animate();
    }

    resizeCanvas() {
        const container = document.getElementById('three-canvas');
        if (this.camera && this.renderer && container) {
            this.camera.aspect = container.clientWidth / container.clientHeight;
            this.camera.updateProjectionMatrix();
            this.renderer.setSize(container.clientWidth, container.clientHeight);
        }
    }

    setupBindings() {
        const btn = document.getElementById('btn-explain-visual');
        if (btn) btn.addEventListener('click', () => this.startExplanation());

        document.getElementById('btn-ask-context').addEventListener('click', () => {
            const q = prompt("Interruption Protocol: Enter your doubt based on this visual context:");
            if (q) {
                // Future: Send to api/contextual_doubt
                window.app.chat.addMessage(q.toUpperCase(), 'user');
                window.app.chat.handleSubmit(new Event('submit'), q);
            }
        });
    }

    async startExplanation() {
        const input = document.getElementById('visual-input');
        const query = input.value.trim();
        if (!query) return;

        document.getElementById('visual-loading').classList.remove('hidden');

        try {
            const payload = {
                question: query,
                context: window.currentProjectContext || null
            };

            // Clear context after use to avoid pollution
            window.currentProjectContext = null;

            const res = await fetch('/api/presentation', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload)
            });
            const data = await res.json();

            if (data.success) {
                this.steps = data.data.steps;
                this.currentStep = 0;
                this.playStep(0);
                document.getElementById('visual-loading').classList.add('hidden');
            }
        } catch (e) {
            console.error(e);
            document.getElementById('visual-loading').classList.add('hidden');
        }
    }

    playStep(index) {
        if (index >= this.steps.length) return;

        const step = this.steps[index];
        this.currentStep = index;

        // Update UI
        document.getElementById('step-text').innerHTML = `
            <div class="border-l-2 border-cyan-500 pl-4 py-2 mb-4 bg-cyan-900/10">
                <div class="text-xs text-cyan-400 font-bold mb-1 tracking-widest">>>> SEQUENCE ${index + 1}/${this.steps.length}</div>
                <div class="text-lg text-white font-bold mb-2">${step.text}</div>
                <div class="text-xs text-cyan-600 font-mono">AUDIO.PROTOCOL: ACTIVE</div>
            </div>
        `;

        // Play Audio
        if (step.audio_url) {
            this.audio.src = `/static/${step.audio_url}`;

            // Set a Safety Timeout to force next step if audio fails or hangs
            const safetyTimeout = setTimeout(() => {
                if (this.currentStep === index) {
                    console.warn("Audio timed out. Forcing next step.");
                    this.playStep(index + 1);
                }
            }, 8000); // 8 seconds max per step

            this.audio.onended = () => {
                clearTimeout(safetyTimeout);
                document.getElementById('visual-status').innerText = "AUDIO: COMPLETE. NEXT SEQ...";
                setTimeout(() => this.playStep(index + 1), 1000);
            };

            this.audio.onerror = () => {
                clearTimeout(safetyTimeout);
                console.warn("Audio failed to load. Skipping.");
                this.playStep(index + 1);
            }

            this.audio.play().catch(e => {
                console.warn("Autoplay blocked/failed:", e);
                clearTimeout(safetyTimeout);
                this.playStep(index + 1);
            });

            document.getElementById('hud-power-val').innerText = step.power_mode || '---';
            
            const traceStatus = document.getElementById('hud-trace');
            if (step.is_sovereign) {
                traceStatus.innerText = "SOVEREIGN_VERIFIED";
                traceStatus.className = "text-green-500 font-bold";
            } else {
                traceStatus.innerText = "UNAUTHORIZED_NODE";
                traceStatus.className = "text-red-500 font-bold animate-pulse";
            }
            document.getElementById('visual-status').innerText = "AUDIO: PLAYING...";
        } else {
            // No audio, just wait a bit and proceed
            setTimeout(() => this.playStep(index + 1), 4000);
        }

        // Execute Visual Code
        if (step.visual_code) {
            this.executeVisualCode(step.visual_code);
        }
    }

    executeVisualCode(code) {
        try {
            // Keep lights/grid, remove meshes
            this.scene.children = this.scene.children.filter(c => c.type === 'Light' || c.type === 'AmbientLight' || c.type === 'DirectionalLight' || c.type === 'GridHelper');

            const scene = this.scene;
            const THREE = window.THREE;
            const parts = this.parts;

            // Execute
            console.log("Run Visual Code:", code);
            new Function('scene', 'THREE', 'parts', code)(scene, THREE, parts);

        } catch (e) {
            console.error("Visual Code Error:", e);
        }
    }
}

class ProjectMentor {
    constructor() {
        const btn = document.getElementById('btn-build-project');
        if (btn) {
            btn.addEventListener('click', () => this.generatePlan());
        }
    }

    async generatePlan() {
        const titleInput = document.getElementById('build-title');
        const descInput = document.getElementById('build-description');

        const title = titleInput ? titleInput.value.trim() : '';
        const description = descInput ? descInput.value.trim() : '';

        // --- INPUT VALIDATION ---
        if (!description || description.length < 50) {
            document.getElementById('build-content').innerHTML = `
                <div class="col-span-3 flex flex-col items-center justify-center pt-20">
                    <div class="border border-red-500/50 bg-red-900/10 p-8 rounded text-center max-w-lg relative overflow-hidden">
                        <div class="absolute inset-0 bg-red-500/5 animate-pulse"></div>
                        <i class="fas fa-exclamation-circle text-4xl text-red-500 mb-4 relative z-10"></i>
                        <h3 class="text-xl font-bold text-red-400 mb-2 relative z-10">INSUFFICIENT DATA</h3>
                        <p class="text-sm font-mono text-red-200 mb-4 relative z-10">
                            "Mission Brief" is too short (${description ? description.length : 0}/50 chars). 
                            <br>Please describe the **Goal**, **Sensors**, and **Expected Behavior**.
                            <br><span class="text-cyan-600 opacity-80">Ex: "Build a smart plant waterer that uses a soil moisture sensor to activate a 5V pump when dry."</span>
                        </p>
                        <div class="text-xs text-red-500/60 font-mono relative z-10">ERROR_CODE: INPUT_UNDERFLOW</div>
                    </div>
                </div>
            `;
            return;
        }

        if (!title) {
            alert("Project Title is required.");
            return;
        }

        // Show loading state...
        document.getElementById('build-content').innerHTML = `
            <div class="col-span-3 flex flex-col items-center justify-center text-cyan-400 animate-pulse pt-20">
                <div class="w-16 h-16 border-4 border-t-cyan-400 border-r-cyan-600 border-b-cyan-800 border-l-cyan-600 rounded-full animate-spin mb-6"></div>
                <h3 class="text-xl font-tech tracking-widest">ANALYZING ENGINEERING PARAMETERS</h3>
                <p class="font-mono text-cyan-700 mt-2">> PROCESSING MISSION BRIEF: "${description.substring(0, 20)}..."</p>
                <p class="font-mono text-cyan-700">> CALCULATING SPECIFIC BOM...</p>
                <p class="font-mono text-cyan-700">> OPTIMIZING ARCHITECTURE...</p>
            </div>
        `;

        try {
            const prompt = `Project Title: ${title}. Mission Brief/Utility: ${description || 'Standard implementation'}.`;

            const res = await fetch('/api/project_plan', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ idea: prompt })
            });
            const data = await res.json();

            if (data.success) {
                // NEW: Handle Consultation Flow
                if (data.data.type === 'clarification') {
                    const reason = data.data.reason;
                    const questions = data.data.questions || [];

                    let questionsHtml = questions.map((q, i) => `
                        <div class="mb-4">
                            <label class="block text-cyan-400 text-xs font-mono mb-2">QUERY ${i + 1}: ${q}</label>
                            <input type="text" id="consult-q-${i}" class="w-full bg-black/50 border border-cyan-500/30 rounded p-2 text-cyan-100 text-sm focus:border-cyan-400 outline-none" placeholder="Enter specifications...">
                        </div>
                    `).join('');

                    document.getElementById('build-content').innerHTML = `
                        <div class="col-span-3 flex flex-col items-center justify-center pt-10 px-8">
                            <div class="border border-cyan-500/50 bg-cyan-900/10 p-8 rounded w-full max-w-2xl relative max-h-[75vh] overflow-y-auto custom-scrollbar">
                                <div class="absolute inset-0 bg-cyan-500/5 pointers-events-none sticky top-0"></div>
                                
                                <div class="flex items-center mb-6 border-b border-cyan-500/30 pb-4 relative z-10 sticky top-0 bg-black/80 backdrop-blur-sm pt-2">
                                    <i class="fas fa-user-tie text-3xl text-cyan-400 mr-4"></i>
                                    <div>
                                        <h3 class="text-xl font-bold text-cyan-300">ARCHITECT'S ANALYSIS</h3>
                                        <p class="text-xs text-cyan-500 font-mono">ENGINEERING CONSULTATION REQUIRED</p>
                                    </div>
                                </div>

                                <div class="bg-black/40 border-l-2 border-yellow-500 p-4 mb-6 relative z-10">
                                    <p class="text-sm text-cyan-200 italic">"${reason}"</p>
                                </div>

                                <div class="space-y-4 mb-8 relative z-10">
                                    ${questionsHtml}
                                </div>

                                <div class="flex justify-end relative z-10">
                                    <button id="btn-proceed-blueprint" class="bg-cyan-600 hover:bg-cyan-500 text-black font-bold py-2 px-6 rounded shadow-[0_0_15px_rgba(8,145,178,0.5)] transition-all">
                                        PROCEED TO BLUEPRINT <i class="fas fa-arrow-right ml-2"></i>
                                    </button>
                                </div>
                            </div>
                        </div>
                    `;

                    setTimeout(() => {
                        const btnProceed = document.getElementById('btn-proceed-blueprint');
                        btnProceed.addEventListener('click', () => {
                            let allValid = true;
                            // Collect answers and validate
                            const answers = questions.map((q, i) => {
                                const input = document.getElementById(`consult-q-${i}`);
                                const val = input.value.trim();

                                if (!val) {
                                    allValid = false;
                                    input.classList.add('border-red-500');
                                    input.classList.remove('border-cyan-500/30');
                                    input.placeholder = "REQUIRED: Please answer this question.";
                                } else {
                                    input.classList.remove('border-red-500');
                                    input.classList.add('border-cyan-500/30');
                                }
                                return `Q: ${q}\nA: ${val}`;
                            });

                            if (!allValid) {
                                // Visual Feedback for Error
                                btnProceed.classList.add('bg-red-600', 'animate-pulse');
                                btnProceed.innerHTML = '<i class="fas fa-exclamation-triangle mr-2"></i> MISSING INPUTS';
                                setTimeout(() => {
                                    btnProceed.classList.remove('bg-red-600', 'animate-pulse');
                                    btnProceed.classList.add('bg-cyan-600');
                                    btnProceed.innerHTML = 'PROCEED TO BLUEPRINT <i class="fas fa-arrow-right ml-2"></i>';
                                }, 1500);
                                return;
                            }

                            const enrichedPrompt = `${prompt}\n\n[USER CLARIFICATIONS]\n${answers.join('\n')}\n\n[INSTRUCTION]: Generate the final PLAN now.`;

                            // Show Loading Again
                            document.getElementById('build-content').innerHTML = `
                                <div class="col-span-3 flex flex-col items-center justify-center text-cyan-400 animate-pulse pt-20">
                                    <div class="w-16 h-16 border-4 border-t-cyan-400 border-r-cyan-600 border-b-cyan-800 border-l-cyan-600 rounded-full animate-spin mb-6"></div>
                                    <h3 class="text-xl font-tech tracking-widest">FINALIZING BLUEPRINT</h3>
                                    <p class="font-mono text-cyan-700 mt-2">> INTEGRATING NEW PARAMETERS...</p>
                                </div>
                            `;

                            fetch('/api/project_plan', {
                                method: 'POST',
                                headers: { 'Content-Type': 'application/json' },
                                body: JSON.stringify({ idea: enrichedPrompt })
                            })
                                .then(r => r.json())
                                .then(d => {
                                    if (d.success) {
                                        this.renderPlan(d.data);
                                        if (window.app && window.app.voice) {
                                            window.app.voice.speak(`Blueprint finalized. Ready for review.`);
                                        }
                                    } else {
                                        document.getElementById('build-content').innerHTML = `<div class="col-span-3 text-red-500 font-mono text-center pt-20">GENERATION FAILED: ${d.error}</div>`;
                                    }
                                });
                        });
                    }, 100);

                    return; // Stop here, wait for user input
                }

                // Standard Plan Rendering
                this.renderPlan(data.data);
                if (window.app && window.app.voice) {
                    window.app.voice.speak(`Blueprint generated for ${title}. Ready for fabrication.`);
                }
            } else {
                document.getElementById('build-content').innerHTML = `<div class="col-span-3 text-red-500 font-mono text-center pt-20">GENERATION FAILED: ${data.error}</div>`;
            }
        } catch (e) {
            console.error(e);
            document.getElementById('build-content').innerHTML = `<div class="col-span-3 text-red-500 font-mono text-center pt-20">SYSTEM ERROR: ${e.message}</div>`;
        }
    }

    renderPlan(plan) {
        if (!plan) return;
        const bom = plan.bom || [];
        const tech_stack = plan.tech_stack || [];
        const roadmap = plan.roadmap || [];

        const bomHtml = bom.map(p => `
            <div class="flex justify-between items-center p-2 border-b border-cyan-500/20 hover:bg-cyan-500/10 transition-colors">
                <div>
                    <div class="font-bold text-cyan-300 text-xs">${p.part}</div>
                    <div class="text-[10px] text-cyan-600 font-mono">${p.specs}</div>
                </div>
                <div class="text-xs font-mono text-cyan-400">${p.estimated_cost || ''}</div>
            </div>
        `).join('');

        const contextHtml = `
            <!-- Left: BOM -->
            <div class="bg-black/40 border border-cyan-500/20 rounded p-4 h-full overflow-y-auto custom-scrollbar flex flex-col">
                <h3 class="text-[10px] font-bold uppercase tracking-widest text-cyan-600 mb-3 border-b border-cyan-900 pb-2">
                    <i class="fas fa-microchip mr-2"></i>COMPONENT MANIFEST
                </h3>
                <div class="space-y-1 flex-1">
                    ${bomHtml}
                </div>
                
                <div class="mt-4 pt-4 border-t border-cyan-500/20">
                    <h3 class="text-[10px] font-bold uppercase tracking-widest text-cyan-600 mb-2">TECH STACK</h3>
                    <div class="flex flex-wrap gap-2">
                        ${tech_stack.map(t => `<span class="px-2 py-1 bg-cyan-900/40 border border-cyan-500/30 rounded text-[10px] text-cyan-300">${t}</span>`).join('')}
                    </div>
                </div>
            </div>
            
            <!-- Center: Blueprint & Steps -->
            <div class="bg-black/40 border border-cyan-500/20 rounded h-full flex flex-col relative overflow-hidden">
                <div class="absolute top-0 right-0 p-2 text-[10px] text-cyan-900 font-mono">ARCH.VIEW.01</div>
                
                <h3 class="p-4 text-[10px] font-bold uppercase tracking-widest text-cyan-600 border-b border-cyan-900/50 flex items-center">
                    <i class="fas fa-network-wired mr-2"></i>SYSTEM ARCHITECTURE
                </h3>

                <!-- Scrollable Container for Diagram AND Steps -->
                <div class="flex-1 overflow-y-auto custom-scrollbar p-4 space-y-6">
                    
                    <!-- Diagram Container -->
                    <div class="mermaid flex justify-center py-4 bg-cyan-900/5 rounded border border-cyan-500/10 min-h-[200px]">
                        ${plan.mermaid_diagram}
                    </div>

                    <!-- Steps Container -->
                    <div class="pt-4 border-t border-cyan-500/20">
                        <h3 class="text-[10px] font-bold uppercase tracking-widest text-cyan-600 mb-4">
                            <i class="fas fa-list-ol mr-2"></i>ASSEMBLY PROTOCOL
                        </h3>
                        <div class="space-y-4">
                            ${roadmap.map((step, i) => `
                                <div class="relative pl-4 border-l border-cyan-500/30 group hover:border-cyan-400 transition-colors">
                                    <div class="absolute -left-[5px] top-0 w-2 h-2 rounded-full bg-cyan-800 group-hover:bg-cyan-400 transition-colors"></div>
                                    <h4 class="text-sm font-bold text-cyan-100 mb-1">${step.phase}</h4>
                                    <p class="text-xs text-cyan-400/80 leading-relaxed mb-2">${step.description}</p>
                                    
                                    <!-- Key Concept Box -->
                                    <div class="bg-blue-900/20 border border-blue-500/20 p-2 rounded text-[10px] text-blue-300">
                                        <i class="fas fa-lightbulb mr-1 text-yellow-400"></i> <span class="font-bold">CONCEPT:</span> ${step.key_concept || "Engineering Principle"}
                                    </div>
                                </div>
                            `).join('')}
                        </div>
                    </div>
                </div>
            </div>

            <!-- Right: Code Vault -->
            <div class="bg-black/40 border border-cyan-500/20 rounded p-4 h-full overflow-y-auto custom-scrollbar flex flex-col">
                <h3 class="text-[10px] font-bold uppercase tracking-widest text-cyan-600 mb-3 border-b border-cyan-900 pb-2">
                    <i class="fas fa-code mr-2"></i>SOURCE CODE
                </h3>
                
                <div class="flex-1 bg-gray-900/80 rounded p-3 font-mono text-xs text-green-400 overflow-x-auto border border-white/5 relative">
                    <div class="absolute top-2 right-2 text-[10px] text-gray-500 uppercase">${plan.code_language || 'CPP'}</div>
                    <pre><code>${plan.code_snippet || '// Source code generation pending...'}</code></pre>
                </div>
                
                <div class="flex flex-col gap-2 mt-4">
                    <button id="btn-visualize-blueprint" class="w-full py-2 bg-cyan-900/40 hover:bg-cyan-600/40 border border-cyan-400/50 text-cyan-300 text-xs font-bold transition-all shadow-lg hover:shadow-cyan-500/50">
                        <i class="fas fa-cube mr-2"></i>VISUALIZE REALITY
                    </button>
                    <button class="w-full py-2 bg-cyan-900/20 hover:bg-cyan-600/20 border border-cyan-500/30 text-cyan-400 text-xs font-bold transition-all">
                        <i class="fas fa-download mr-2"></i>EXPORT BLUEPRINT
                    </button>
                </div>
            </div>
        `;

        const contentDiv = document.getElementById('build-content');
        contentDiv.innerHTML = contextHtml;

        // Wire up Visualization Button
        setTimeout(() => {
            const vizBtn = document.getElementById('btn-visualize-blueprint');
            if (vizBtn) {
                vizBtn.addEventListener('click', () => {
                    // Store Context Globally for Visualizer to pick up
                    window.currentProjectContext = {
                        bom: plan.bom,
                        roadmap: plan.roadmap,
                        project: plan.project_name
                    };

                    const vizQuery = `Generate a high-fidelity 3D assembly schematic for ${plan.project_name}. \nContext BOM: ${plan.bom.map(b => b.part).join(', ')}. \nInstructions: Visualize the entire assembly, connecting all components with wires on a breadboard.`;

                    // Switch to Visual Tab
                    const navVisual = document.getElementById('nav-visual');
                    if (navVisual) navVisual.click();

                    // Auto-type and submit
                    setTimeout(() => {
                        const vizInput = document.getElementById('visual-input');
                        const vizSubmit = document.getElementById('btn-explain-visual');

                        if (vizInput && vizSubmit) {
                            vizInput.value = vizQuery;
                            vizSubmit.click();
                        }
                    }, 500);
                });
            }
        }, 100);

        // Re-initialize Mermaid
        if (window.mermaid) {
            try {
                mermaid.init(undefined, document.querySelectorAll('.mermaid'));
            } catch (e) {
                console.error("Mermaid Render Error:", e);
            }
        }
    }
}

class AgentMode {
    constructor() {
        this.input = document.getElementById('agent-goal');
        this.btn = document.getElementById('btn-agent-execute');
        this.output = document.getElementById('agent-output');
        
        if (this.btn) {
            this.btn.addEventListener('click', () => this.runMission());
        }
    }

    async runMission() {
        const goal = this.input.value ? this.input.value.trim() : "";
        if (!goal) return;

        this.output.innerHTML = `
            <div class="flex flex-col items-center justify-center pt-10 animate-pulse">
                <i class="fas fa-satellite-dish text-4xl mb-4 text-purple-500"></i>
                <p class="text-xs uppercase tracking-[0.3em] font-bold text-purple-400">INITIATING DEEP RESEARCH PROTOCOL</p>
                <p class="text-[10px] text-purple-900 mt-2">> TARGET: "${goal.substring(0, 30)}..."</p>
                <p class="text-[10px] text-purple-900">> ANALYZING RELEVANT WHITEPAPERS...</p>
            </div>
        `;

        try {
            const res = await fetch('/api/agent', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ goal })
            });
            const data = await res.json();

            if (data.success) {
                this.renderResult(data.data);
            } else {
                this.output.innerHTML = `<div class="text-red-500 font-mono text-center pt-10">MISSION FAILED: ${data.error}</div>`;
            }
        } catch (e) {
            this.output.innerHTML = `<div class="text-red-500 font-mono text-center pt-10">CORE ERROR: ${e.message}</div>`;
        }
    }

    renderResult(result) {
        // Markdown-ish result parsing
        const html = result.replace(/\n/g, '<br>').replace(/### (.*)/g, '<h3 class="text-purple-400 font-bold mt-4 mb-2">$1</h3>');
        this.output.innerHTML = `
            <div class="border-l-2 border-purple-500 pl-4 py-2 bg-purple-900/10">
                <div class="text-[10px] text-purple-500 font-bold mb-4">>>> MISSION ACCOMPLISHED</div>
                <div class="leading-relaxed text-sm text-purple-100">${html}</div>
            </div>
        `;
    }
}

class CoreMode {
    constructor() {
        this.input = document.getElementById('core-input');
        this.btn = document.getElementById('btn-core-execute');
        this.logs = document.getElementById('core-logs');
        
        if (this.btn) {
            this.btn.addEventListener('click', () => this.runCommand());
            this.input.addEventListener('keypress', (e) => {
                if (e.key === 'Enter') this.runCommand();
            });
        }
    }

    addLog(msg, type = 'info') {
        const div = document.createElement('div');
        const ts = new Date().toLocaleTimeString();
        let color = 'text-amber-500/60';
        if (type === 'cmd') color = 'text-amber-400 font-bold';
        if (type === 'success') color = 'text-emerald-400';
        if (type === 'error') color = 'text-red-500';
        
        div.className = `${color} mb-1`;
        div.innerHTML = `<span class="opacity-30 mr-2">[${ts}]</span> ${msg}`;
        this.logs.appendChild(div);
        this.logs.scrollTop = this.logs.scrollHeight;
    }

    async runCommand() {
        const cmd = this.input.value ? this.input.value.trim() : "";
        if (!cmd) return;

        this.addLog(`KALI@CORE:~$ ${cmd}`, 'cmd');
        this.input.value = '';
        this.addLog("INITIATING ROOT_LEVEL_EVOLUTION_PROTOCOL...", 'info');

        try {
            const res = await fetch('/api/sovereign/cmd', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ prompt: cmd })
            });
            const data = await res.json();

            if (data.success) {
                this.addLog(">>> EVOLUTION_PROTOCOL_SUCCESS", 'success');
                this.addLog(data.data || data.message || "Root modification applied successfully.", 'info');
                this.addLog("NOTE: RESTART REQUIRED FOR FULL DNA RECLAMATION.", 'info');
            } else {
                this.addLog(`>>> PROTOCOL_ABORTED: ${data.error}`, 'error');
            }
        } catch (e) {
            this.addLog(`>>> CORE_FAIL: ${e.message}`, 'error');
        }
    }
}

class SmartHome {
    constructor() {
        this.isPartyMode = false;
        this.setupBindings();
    }

    setupBindings() {
        // Party Mode
        const btnParty = document.getElementById('btn-party-mode');
        if (btnParty) btnParty.addEventListener('click', () => this.togglePartyMode());

        // Lockdown
        const btnLock = document.getElementById('btn-lockdown');
        if (btnLock) btnLock.addEventListener('click', () => {
            btnLock.classList.toggle('bg-red-600');
            btnLock.innerText = btnLock.innerText === 'ENGAGE LOCKDOWN' ? 'DISENGAGE' : 'ENGAGE LOCKDOWN';

            if (window.app && window.app.voice) {
                window.app.voice.speak(btnLock.innerText === 'DISENGAGE' ? "Lockdown engaged. Directing power to perimeter defense." : "Lockdown disengaged. Returning to standard security protocols.");
            }
        });

        // Sponsor Evolution
        const btnSponsor = document.getElementById('btn-sponsor');
        if (btnSponsor) btnSponsor.addEventListener('click', () => {
             const modal = document.getElementById('sponsor-modal');
             if (modal) modal.classList.remove('hidden');
             if (window.app && window.app.voice) {
                 window.app.voice.speak("Sponsorship protocol initiated. Sir, the community can now fuel our evolution via GitHub, Ko-fi, or Patreon.");
             }
        });
    }

    togglePartyMode() {
        this.isPartyMode = !this.isPartyMode;
        const btn = document.getElementById('btn-party-mode');
        const body = document.body;

        if (this.isPartyMode) {
            btn.classList.add('bg-purple-600', 'animate-pulse');
            btn.innerHTML = '<i class="fas fa-pause mr-2"></i>END PROTOCOL';

            // CSS Party Effect
            body.style.animation = "party-bg 2s infinite alternate";

            // Inject Keyframes if not exists
            if (!document.getElementById('party-style')) {
                const style = document.createElement('style');
                style.id = 'party-style';
                style.innerHTML = `
                    @keyframes party-bg {
                        0% { background-color: #02040a; }
                        25% { background-color: #1a0329; }
                        50% { background-color: #031c29; }
                        75% { background-color: #1a2903; }
                        100% { background-color: #290303; }
                    }
                `;
                document.head.appendChild(style);
            }

            if (window.app && window.app.voice) {
                window.app.voice.speak("House Party Protocol initiated. Dropping the beat, Sir.");
            }

        } else {
            btn.classList.remove('bg-purple-600', 'animate-pulse');
            btn.innerHTML = '<i class="fas fa-music mr-2"></i>HOUSE PARTY PROTOCOL';
            body.style.animation = "none";

            if (window.app && window.app.voice) {
                window.app.voice.speak("Party Protocol disengaged.");
            }
        }
    }
}

// Initialize
// Google Auth Callback
async function handleCredentialResponse(response) {
    if (response.credential) {
        console.log("Processing Google Credential...");

        try {
            // Verify with Backend
            const res = await fetch('/api/verify_token', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ token: response.credential })
            });
            const data = await res.json();

            if (data.success) {
                const user = data.user;
                console.log("Authentication Successful:", user.email);

                // Update UI
                const authContainer = document.querySelector('.g_id_signin').parentNode;
                if (authContainer) {
                    authContainer.innerHTML = `
                        <div class="flex items-center gap-3">
                            <span class="text-cyan-400 text-sm hologram-text">${user.name}</span>
                            <img src="${user.picture}" class="w-8 h-8 rounded-full border border-cyan-500 shadow-[0_0_10px_#00f3ff]" alt="User">
                            <button onclick="logout()" class="text-xs text-red-500 hover:text-red-300 ml-2"><i class="fas fa-sign-out-alt"></i></button>
                        </div>
                    `;
                }

                if (window.app && window.app.voice) {
                    window.app.voice.speak(`Access Granted. Welcome back, ${user.given_name || user.name}.`);
                }

                // Refresh archives if already loaded
                if (window.app && window.app.archives) {
                    window.app.archives.loadArchives();
                }

            } else {
                console.error("Backend Auth Failed:", data.error);
                if (window.app && window.app.voice) {
                    window.app.voice.speak(`Authentication Denied. ${data.error}`);
                }
            }

        } catch (e) {
            console.error("Auth Request Failed:", e);
        }
    }
}

async function logout() {
    await fetch('/api/logout', { method: 'POST' });
    location.reload();
}

function parseJwt(token) {
    var base64Url = token.split('.')[1];
    var base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
    var jsonPayload = decodeURIComponent(window.atob(base64).split('').map(function (c) {
        return '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2);
    }).join(''));

    return JSON.parse(jsonPayload);
}

// Make globally accessible logic
App.prototype.handleCredentialResponse = handleCredentialResponse;

class HUDController {
    constructor() {
        this.perc = document.getElementById('hud-perc');
        this.bar = document.getElementById('hud-bar');
        this.trace = document.getElementById('hud-trace');
        this.mission = document.getElementById('hud-mission');
        this.disc = document.getElementById('hud-disc');
        this.power = document.getElementById('hud-power-val');
        
        // Header Status
        this.sysStatus = document.getElementById('hud-sys-status');
        this.biosChip = document.getElementById('hud-bios-chip');
        
        // Singularity Elements
        this.cpuVal = document.getElementById('hud-cpu-val');
        this.cpuBar = document.getElementById('hud-cpu-bar');
        this.memVal = document.getElementById('hud-mem-val');
        this.memBar = document.getElementById('hud-mem-bar');
        this.tensionLabel = document.getElementById('hud-tension-label');
        this.tensionBar = document.getElementById('hud-tension-bar');
        this.sovereignStatus = document.getElementById('sovereign-status');
        this.predictiveContainer = document.getElementById('predictive-container');
        this.predictiveChips = document.getElementById('predictive-chips');
        
        // Phase 31: Tactical Hardware
        this.hwVcc = document.getElementById('hw-vcc');
        this.hwRssi = document.getElementById('hw-rssi');
        this.hwStatus = document.getElementById('hw-status');
        
        // Phase 32: Swarm Intelligence
        this.swarmList = document.getElementById('swarm-list');
        this.swarmContainer = document.getElementById('hud-swarm-container');
        
        // Phase 33: Autonomous Self-Repair
        this.healContainer = document.getElementById('hud-heal-container');
        this.healCount = document.getElementById('heal-count');
        
        // Phase 35: The Great Restoration
        this.singularityEq = document.getElementById('singularity-equilibrium');
        
        // Phase 36: Neural Telepathy
        this.thinkingAura = document.getElementById('thinking-aura');
        this.vocalIndicator = document.getElementById('vocal-indicator');
        this.vocalText = document.getElementById('vocal-text');
        this.hubOverlay = document.getElementById('neural-hud');
        
        // Phase 37: Replicant Hub Kinematics
        this.jHead = document.getElementById('j-head');
        this.jArmL = document.getElementById('j-arm-l');
        this.jArmR = document.getElementById('j-arm-r');
        this.kStatus = document.getElementById('kinetic-status');
        this.jTelemetry = document.getElementById('joint-telemetry');
        
        // Phase 28: Fabrication
        this.btnManifest = document.getElementById('btn-manifest-mission');
        this.currentProjectPath = null;
        if (this.btnManifest) {
            this.btnManifest.addEventListener('click', () => this.manifestMission());
        }
        
        // Phase 26: BIOS
        this.biosVal = document.getElementById('bios-heart-val');
        this.biosPulse = document.getElementById('bios-heart-pulse');
        
        // Phase 27: Project DNA
        this.partsList = document.getElementById('hud-parts-list');
        this.costVal = document.getElementById('hud-cost-val');
        this.dnaContainer = document.getElementById('hud-dna-container');
        
        // Phase 29: Knowledge DNA
        this.dnaBar = document.getElementById('hud-dna-bar');
        this.dnaVal = document.getElementById('hud-dna-val');
        
        // Phase 38: Sovereign Cloud
        this.cloudStatus = document.getElementById('hud-cloud-status');
        this.cloudSyncBar = document.getElementById('cloud-sync-bar');
        
        // Phase 39: RLHF-DNA
        this.alignmentVal = document.getElementById('hud-alignment-val');
        this.alignmentBar = document.getElementById('hud-alignment-bar');
        
        // Phase 40: Omega Protocol
        this.btnOmega = document.getElementById('btn-omega');
        if (this.btnOmega) {
            this.btnOmega.addEventListener('click', () => this.engageOmegaProtocol());
        }
        
        // Post-Omega Training
        this.btnTrain = document.getElementById('btn-train');
        if (this.btnTrain) {
            this.btnTrain.addEventListener('click', () => this.synthesizeTraining());
        }
        
        // Phase 18: RLHF
        window.submitCorrection = (q, r, c) => {
            fetch('/api/feedback', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ q, r, c })
            }).then(resp => resp.json())
              .then(data => {
                  alert("KALI Evolutionary Trace Updated: Ground Truth Accepted.");
              });
        };
        
        if (this.perc) {
            this.startPolling();
        }
    }

    async startPolling() {
        this.updateHUD();
        setInterval(() => this.updateHUD(), 5000); // Pulse every 5s
    }

    async updateHUD() {
        try {
            const res = await fetch('/api/status');
            const json = await res.json();
            
            if (json.success) {
                const s = json.status;
                const h = s.heartbeat || {};
                this.currentProjectPath = s.manifest_path;
                
                // Core Telemetry
                if (this.perc) this.perc.innerText = s.consciousness_level.toFixed(1) + "%";
                if (this.bar) this.bar.style.width = s.consciousness_level.toFixed(1) + "%";
                if (this.mission) this.mission.innerText = s.active_mission.toUpperCase();
                if (this.disc) this.disc.innerText = s.last_discovery.substring(0, 15) + (s.last_discovery.length > 15 ? '...' : '');
                if (this.trace) this.trace.innerText = h.status || "OFFLINE";
                if (this.power) this.power.innerText = s.power_mode || "TURBO";

                // System Loads
                if (this.cpuVal) this.cpuVal.innerText = `${Math.round(s.system_load)}%`;
                if (this.cpuBar) this.cpuBar.style.width = `${s.system_load}%`;
                if (this.memVal) this.memVal.innerText = `${Math.round(s.memory_load)}%`;
                if (this.memBar) this.memBar.style.width = `${s.memory_load}%`;

                // Tension Resonance
                if (this.tensionLabel && s.tension !== undefined) {
                    const t = s.tension * 100;
                    if (this.tensionBar) this.tensionBar.style.width = `${t}%`;
                    this.tensionLabel.innerText = t > 80 ? "RESONANCE: HIGH_TENSION" : "RESONANCE: STEADY";
                    this.tensionLabel.style.color = t > 80 ? "#ec4899" : "#00f3ff";
                }

                // Phase 36: Neural Telepathy
                this.toggleThinkingAura(s.is_thinking);

                // Phase 37: Replicant Hub
                if (s.robotic_status) {
                    this.renderKinematics(s.robotic_status);
                }

                // Phase 38: Sovereign Cloud
                if (this.cloudStatus && s.cloud_status) {
                    const cs = s.cloud_status;
                    if (s.sovereign_mode) {
                        this.cloudStatus.innerText = "ABSOLUTE_LOCAL";
                        this.cloudStatus.className = "text-amber-500 font-bold uppercase tracking-widest";
                    } else {
                        this.cloudStatus.innerText = cs.status;
                        this.cloudStatus.className = `text-[10px] font-bold tracking-widest ${cs.status === 'SYNC_ACTIVE' ? 'text-blue-400 animate-pulse' : 'text-blue-500'}`;
                    }
                    if (this.cloudSyncBar) {
                        this.cloudSyncBar.classList.toggle('hidden', cs.status !== 'SYNC_ACTIVE');
                    }
                }

                // Phase 39: RLHF-DNA
                if (this.alignmentVal && s.alignment_status) {
                    const al = s.alignment_status;
                    const p = al.alignment_score.toFixed(1) + "%";
                    this.alignmentVal.innerText = p;
                    if (this.alignmentBar) this.alignmentBar.style.width = p;
                    this.alignmentVal.classList.toggle('animate-pulse', al.alignment_score < 80);
                    this.alignmentVal.style.color = al.alignment_score > 90 ? "#10b981" : "#f59e0b";
                    
                    // Show Omega button if alignment is optimal (Phase 40 gate)
                    if (this.btnOmega && al.alignment_score >= 90 && !s.omega_status?.active) {
                        this.btnOmega.classList.remove('hidden');
                    }
                }

                // Phase 40: Omega Protocol
                if (s.omega_status && s.omega_status.active) {
                    document.body.classList.add('omega-mode', 'omega-active');
                    if (this.btnOmega) this.btnOmega.classList.add('hidden');
                }

                // Sovereignty & DNA
                if (this.sovereignStatus && s.sovereign_msg) {
                    this.sovereignStatus.innerText = s.sovereign_msg;
                    this.sovereignStatus.style.color = s.is_sovereign ? "#00f3ff" : "#ef4444";
                }

                if (s.dna_count !== undefined && this.dnaVal) {
                    const dnaPerc = (s.dna_count / 50) * 100;
                    if (this.dnaBar) this.dnaBar.style.width = `${dnaPerc}%`;
                    this.dnaVal.innerText = s.dna_count >= 50 ? "EVOLUTION_READY" : `${s.dna_count}/50`;
                    this.dnaVal.classList.toggle('text-green-500', s.dna_count >= 50);
                    this.dnaVal.classList.toggle('animate-pulse', s.dna_count >= 50);
                }

                // Swarm & Repair
                if (this.swarmList) {
                    if (s.swarm_status && Object.keys(s.swarm_status).length > 0) {
                        this.swarmList.innerHTML = Object.entries(s.swarm_status).map(([a, t]) => `
                            <div class="flex justify-between items-center"><span class="text-cyan-400">${a}</span><span class="text-[7px] text-cyan-800 animate-pulse">${t}</span></div>
                        `).join('');
                    } else {
                        this.swarmList.innerHTML = '<div class="text-slate-500 italic">SWARM_IDLE</div>';
                    }
                }

                if (this.healContainer && s.repair_status) {
                    this.healContainer.classList.toggle('hidden', !s.repair_status.active);
                    if (this.healCount) this.healCount.innerText = s.repair_status.total_repairs;
                }

                // BIOS & Health (Phase 54: O-2)
                if (s.bios) {
                    const status = s.bios.status;
                    const isSecure = status === "SECURE";
                    
                    if (this.biosChip) {
                        this.biosChip.innerText = `BIOS: ${status}`;
                        this.biosChip.className = `ml-2 px-1 text-[8px] border rounded-sm transition-all ${isSecure ? 'bg-cyan-900/50 text-cyan-400 border-cyan-500/30' : 'bg-red-900/50 text-red-400 border-red-500/50 animate-pulse'}`;
                    }
                    
                    if (this.sysStatus) {
                        this.sysStatus.innerText = isSecure ? "NOMINAL" : "RECOVERY";
                        this.sysStatus.style.color = isSecure ? "#00f3ff" : "#f87171";
                    }

                    if (this.biosVal) {
                         this.biosVal.innerText = status;
                         if (this.biosPulse) {
                             this.biosPulse.className = isSecure ? "bios-pulse bios-secure" : "bios-pulse bios-warning animate-pulse";
                         }
                    }
                }
            }
        } catch (e) {
            console.warn("HUD Update Sync Error:", e);
        }
    }

    async manifestMission() {
        if (!this.currentProjectPath) return;
        this.btnManifest.innerText = "MANIFESTING...";
        try {
            const res = await fetch('/api/manifest_mission', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ path: this.currentProjectPath })
            });
            const data = await res.json();
            if (data.success) {
                window.location.href = data.download_url;
                this.btnManifest.innerText = "MANIFESTED!";
                setTimeout(() => this.btnManifest.innerText = "MANIFEST_MISSION (ZIP)", 3000);
            }
        } catch (e) {
            this.btnManifest.innerText = "MANIFEST_FAIL";
        }
    }

    toggleThinkingAura(active) {
        if (!this.hubOverlay || !this.thinkingAura) return;
        this.thinkingAura.classList.toggle('opacity-100', active);
        this.thinkingAura.classList.toggle('opacity-0', !active);
        this.hubOverlay.classList.toggle('thinking-active', active);
    }

    setVocalState(state) {
        if (!this.vocalIndicator || !this.vocalText) return;
        this.vocalIndicator.className = 'w-1.5 h-1.5 rounded-full bg-cyan-500/30'; 
        if (state === 'listening') {
            this.vocalIndicator.classList.add('listening');
            this.vocalText.innerText = 'Listening';
        } else if (state === 'speaking') {
            this.vocalIndicator.classList.add('speaking');
            this.vocalText.innerText = 'Speaking';
        } else {
            this.vocalText.innerText = 'Standby';
        }
    }

    renderKinematics(status) {
        if (!status || !status.joints) return;
        const joints = status.joints;
        
        if (this.kStatus) {
            this.kStatus.innerText = status.is_moving ? "ACTUATORS_ENGAGED" : "HUB_NOMINAL";
            this.kStatus.className = `text-[8px] font-mono ${status.is_moving ? "text-emerald-400 animate-pulse" : "text-emerald-500 opacity-60"}`;
        }
        
        if (this.jTelemetry) {
            this.jTelemetry.innerText = `UPTIME: ${status.uptime}s | INTEGRITY: ${status.system_integrity}%`;
        }

        if (this.jHead) this.jHead.classList.toggle('joint-active', Math.abs(joints.HEAD_PAN.current - joints.HEAD_PAN.target) > 0.1);
        if (this.jArmL) this.jArmL.classList.toggle('joint-active', Math.abs(joints.ARM_L_SHOULDER.current - joints.ARM_L_SHOULDER.target) > 0.1);
        if (this.jArmR) this.jArmR.classList.toggle('joint-active', Math.abs(joints.ARM_R_SHOULDER.current - joints.ARM_R_SHOULDER.target) > 0.1);
    }

    async handleIngest(input) {
        const file = input.files[0];
        if (!file) return;
        try {
            const formData = new FormData();
            formData.append('file', file);
            const res = await fetch('/api/ingest_document', { method: 'POST', body: formData });
            const data = await res.json();
            if (data.success && this.mission) {
                this.mission.innerText = "INGESTION COMPLETE";
                setTimeout(() => this.mission.innerText = "READY", 3000);
            }
        } catch (e) {
            console.error("Ingestion failed:", e);
        }
    }

    async togglePower() {
        const next = this.power.innerText === "TURBO" ? "ECO" : "TURBO";
        try {
            const res = await fetch('/api/toggle_power', { method: 'POST', headers: {'Content-Type': 'application/json'}, body: JSON.stringify({mode: next}) });
            const data = await res.json();
            if (data.success) this.power.innerText = data.mode;
        } catch (e) { console.error("Power toggle failed:", e); }
    }

    async engageOmegaProtocol() {
        if (!confirm("KALI OMEGA: ARE YOU READY FOR THE FINAL HANDOVER? THIS WILL SEAL THE SINGULARITY.")) return;
        try {
            const res = await fetch('/api/engage_omega', { method: 'POST' });
            const data = await res.json();
            if (data.status === 'OMEGA_COMPLETE') {
                alert("SINGULARITY_REACHED: KALI IS NOW ABSOLUTELY AUTONOMOUS.");
                document.body.classList.add('omega-mode', 'omega-active');
            }
        } catch (e) { console.error("Omega Protocol failed:", e); }
    }

    async synthesizeTraining() {
        if (this.btnTrain) {
            this.btnTrain.innerText = "SYNTHESIZING...";
            this.btnTrain.disabled = true;
        }
        try {
            const res = await fetch('/api/train', { method: 'POST' });
            const data = await res.json();
            if (data.status === 'SYNTHESIS_COMPLETE') {
                alert(`COGNITIVE_SYNTHESIS: Processed ${data.interactions_processed} nodes. Authority Boost: ${data.authority_boost}x`);
            } else {
                alert("SYNYTHESIS_DEFERRED: Insufficient cognitive data samples.");
            }
        } catch (e) { console.error("Synthesis failed:", e); }
        finally {
            if (this.btnTrain) {
                this.btnTrain.innerText = "SYNTHESIZE_TRAINING_DATA";
                this.btnTrain.disabled = false;
            }
        }
    }
}


class CognitiveHUD {
    constructor() {
        this.tensionEl = document.querySelector('#hud-tension span');
        this.dnaEl = document.querySelector('#hud-dna span');
        this.alertEl = document.getElementById('cognitive-alert');
        this.pollInterval = 5000; // 5 seconds
        
        if (this.tensionEl) {
            this.startPolling();
        }

        // Click to reset
        if (this.alertEl) {
            this.alertEl.addEventListener('click', () => this.performReset());
            this.alertEl.style.cursor = 'pointer';
            this.alertEl.classList.remove('pointer-events-none');
        }
    }

    async startPolling() {
        setInterval(() => this.update(), this.pollInterval);
        this.update(); // Initial call
    }

    async update() {
        try {
            const res = await fetch('/api/biometrics');
            const json = await res.json();
            
            if (json.success) {
                const data = json.data;
                if (this.tensionEl) this.tensionEl.innerText = `${data.neural_tension}%`;
                if (this.dnaEl) this.dnaEl.innerText = data.dna_level;
                
                if (data.reset_suggested) {
                    this.alertEl.classList.remove('hidden');
                } else {
                    this.alertEl.classList.add('hidden');
                }
            }
        } catch (e) {
            console.error("Cognitive Sync Failed:", e);
        }
    }

    async performReset() {
        try {
            const res = await fetch('/api/biometrics/reset', { method: 'POST' });
            const json = await res.json();
            if (json.success) {
                if (window.app && window.app.voice) {
                    window.app.voice.speak("Neural Tension Reset. System efficiency optimized. Ready for engineering execution, Sir.");
                }
                this.update();
            }
        } catch (e) {
            console.error("Reset Failed:", e);
        }
    }
}

// Check for cached credential on boot
document.addEventListener('DOMContentLoaded', () => {
    try {
        window.app = new App();
        window.hud = new HUDController();
        window.cognitiveHud = new CognitiveHUD();
        // Late Init for modules added via replace
        window.app.home = new SmartHome();
        window.app.agent = new AgentMode();
        window.app.core = new CoreMode();

        if (window.cachedCredential) {
            console.log("Processing Cached Credential...");
            window.app.handleCredentialResponse(window.cachedCredential);
        }

        console.log("K.A.L.I. Frontend Initialized Successfully.");
        
        // Phase 15: Sync Cycle Initiation
        fetch('/api/sync', { method: 'POST' })
            .then(res => res.json())
            .then(data => {
                if (data.success) {
                    console.log(`Sync Cycle Complete: Phase ${data.phase}`);
                    window.app.voice.speak(`Sync Cycle Complete, Sir. Objective persistence confirmed for Phase ${data.phase}.`);
                }
            })
            .catch(e => console.error("Sync Cycle Failed:", e));
    } catch (e) {
        console.error("Critical Initialization Error:", e);
    }
});
