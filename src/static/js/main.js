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
        this.modes = ['learn', 'visual', 'build', 'archives', 'agent'];
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
        });

        // Resize Three.js if entering visual mode
        if (newMode === 'visual') {
            setTimeout(() => this.visualizer.resizeCanvas(), 100);
        }

        // Update Nav UI
        document.querySelectorAll('.nav-btn').forEach(btn => {
            // Simplified logic: visual cue handled mainly by switching content
            if (btn.innerText.toLowerCase().includes(newMode) || btn.innerHTML.includes(newMode)) {
                btn.classList.add('text-cyan-400', 'border-b-2', 'border-cyan-400');
            } else {
                btn.classList.remove('text-cyan-400', 'border-b-2', 'border-cyan-400');
            }
        });
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
}

class VoiceModule {
    constructor() {
        this.recognition = null;
        this.isListening = false;
        this.speechEnabled = true; // For output
        this.synth = window.speechSynthesis;

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
            };

            this.recognition.onend = () => {
                this.isListening = false;
                this.updateBtnState(false);
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
        // Put text in input
        const input = document.getElementById('chat-input');
        if (input) {
            input.value = text;
            // Auto submit
            document.getElementById('chat-form').dispatchEvent(new Event('submit'));
        }
    }

    speak(text) {
        if (!this.speechEnabled) return;

        try {
            // Cancel any current speech
            this.synth.cancel();

            // Clean text of markdown/visual cues before speaking
            const cleanText = text.replace(/>/g, '').replace(/\*/g, '').replace(/_/g, '');

            const utter = new SpeechSynthesisUtterance(cleanText);
            utter.rate = 1.0;
            utter.pitch = 1.0; // Standard pitch for KALI

            // Try to find a male voice safely
            const voices = this.synth.getVoices();
            if (voices.length > 0) {
                const preferred = voices.find(v => v.name.includes('Google US English') || v.name.includes('David') || v.name.includes('Male'));
                if (preferred) utter.voice = preferred;
            }

            this.synth.speak(utter);
        } catch (e) {
            console.warn("Audio Output Failed:", e);
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
                
                // Update Perc & Bar
                const p = s.consciousness_level.toFixed(1) + "%";
                this.perc.innerText = p;
                this.bar.style.width = p;
                
                // Update Metadata
                this.mission.innerText = s.active_mission.toUpperCase();
                this.disc.innerText = s.last_discovery.substring(0, 15) + (s.last_discovery.length > 15 ? '...' : '');
                
                // Update Trace Status
                const h = s.heartbeat;
                this.trace.innerText = h.status || "OFFLINE";
                if (this.power) this.power.innerText = s.power_mode || "TURBO";

                // Singularity Updates
                if (s.system_load !== undefined) {
                    this.cpuVal.innerText = `${Math.round(s.system_load)}%`;
                    this.cpuBar.style.width = `${s.system_load}%`;
                }
                if (s.memory_load !== undefined) {
                    this.memVal.innerText = `${Math.round(s.memory_load)}%`;
                    this.memBar.style.width = `${s.memory_load}%`;
                }
                if (s.tension !== undefined) {
                    const t = s.tension * 100;
                    this.tensionBar.style.width = `${t}%`;
                    this.tensionLabel.innerText = t > 80 ? "RESONANCE: HIGH_TENSION" : "RESONANCE: STEADY";
                    this.tensionLabel.style.color = t > 80 ? "#ec4899" : "#00f3ff";
                }
                if (this.sovereignStatus && s.sovereign_msg) {
                    this.sovereignStatus.innerText = s.sovereign_msg;
                    this.sovereignStatus.style.color = s.is_sovereign ? "#00f3ff" : "#ef4444";
                }

                // Phase 30: Predictive Intent
                if (s.next_predictions && s.next_predictions.length > 0) {
                    this.predictiveContainer.classList.remove('opacity-0');
                    this.predictiveChips.innerHTML = s.next_predictions.map(p => `
                        <button onclick="window.app.quickChat('${p}')" class="px-2 py-1 rounded-md bg-blue-500/10 border border-blue-500/20 text-[10px] text-blue-400 hover:bg-blue-500/20 transition-all font-mono">
                            # ${p.toUpperCase()}
                        </button>
                    `).join('');
                } else {
                    this.predictiveContainer.classList.add('opacity-0');
                }
                
                if (h.status === "CONNECTED") {
                    this.trace.classList.remove('text-red-500', 'text-yellow-500');
                    this.trace.classList.add('text-green-500');
                } else {
                    this.trace.classList.add('text-red-500');
                }
            }
        } catch (e) {
            console.warn("HUD Update Failed:", e);
        }
    }

    async handleIngest(input) {
        const file = input.files[0];
        if (!file) return;

        if (this.mission) this.mission.innerText = "INGESTING: " + file.name.substring(0, 10).toUpperCase() + "...";
        
        try {
            const formData = new FormData();
            formData.append('file', file);

            const res = await fetch('/api/ingest_document', {
                method: 'POST',
                body: formData
            });
            const data = await res.json();

            if (data.success) {
                if (this.mission) {
                    this.mission.innerText = "INGESTION COMPLETE";
                    setTimeout(() => this.mission.innerText = "READY", 3000);
                }
            } else {
                if (this.mission) this.mission.innerText = "INGESTION FAILED";
            }
        } catch (e) {
            console.error("Ingestion failed:", e);
            if (this.mission) this.mission.innerText = "SYSTEM ERROR";
        }
    }

    async togglePower() {
        const current = this.power.innerText;
        const next = current === "TURBO" ? "ECO" : "TURBO";
        
        try {
            const res = await fetch('/api/toggle_power', {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify({mode: next})
            });
            const data = await res.json();
            if (data.success) {
                this.power.innerText = data.mode;
                if (this.mission) this.mission.innerText = "MODE: " + data.mode;
            }
        } catch (e) {
            console.error("Power toggle failed:", e);
        }
    }
}

class VoiceModule {
    constructor() {
        this.synth = window.speechSynthesis;
        this.isSpeaking = false;
        this.currentUtterance = null;
    }

    speak(text) {
        if (!text) return;
        
        // Stop current if any (Point 4: State-Aware Interruption)
        this.stop();

        this.currentUtterance = new SpeechSynthesisUtterance(text);
        
        // KALI's Voice Characteristics
        this.currentUtterance.rate = 1.0;
        this.currentUtterance.pitch = 0.9; // Slightly deeper, authoritative
        this.currentUtterance.volume = 1.0;

        this.currentUtterance.onstart = () => { this.isSpeaking = true; };
        this.currentUtterance.onend = () => { this.isSpeaking = false; };
        this.currentUtterance.onerror = (e) => { 
            console.error("Vocal failure:", e);
            this.isSpeaking = false; 
        };

        this.synth.speak(this.currentUtterance);
    }

    stop() {
        if (this.synth.speaking) {
            this.synth.cancel();
            this.isSpeaking = false;
            console.log("KALI Vocal Flow Interrupted.");
        }
    }
}

// Check for cached credential on boot
document.addEventListener('DOMContentLoaded', () => {
    try {
        window.app = new App();
        window.hud = new HUDController();
        // Late Init for modules added via replace
        window.app.home = new SmartHome();
        window.app.agent = new AgentMode();

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
