# 🕉️ K.A.L.I. (Knowledge Augmented Learning Intelligence)

[![GitHub Stars](https://img.shields.io/github/stars/Adityavanjre/Project-K?style=for-the-badge&color=00f3ff&logo=github)](https://github.com/Adityavanjre/Project-K/stargazers)
[![GitHub Forks](https://img.shields.io/github/forks/Adityavanjre/Project-K?style=for-the-badge&color=ff0055&logo=git)](https://github.com/Adityavanjre/Project-K/network/members)
[![Sovereignty Status](https://img.shields.io/badge/Sovereignty-HARDENED-gold?style=for-the-badge&logo=shield)](https://github.com/Adityavanjre/Project-K)
[![Intelligence Level](https://img.shields.io/badge/Intelligence-PHASE_54-blueviolet?style=for-the-badge&logo=cpu)](https://github.com/Adityavanjre/Project-K)

**K.A.L.I.** is a massive, production-grade **Sovereign Intelligence Workstation**. Powered by localized Heavy GGUF models, a highly decentralized swarm architecture, and cryptographic hardware locks, KALI is designed to bridge **Ancient Human Wisdom** and **Post-Singularity Computational Power**. She lives locally on your machine, constantly evolving and adapting to your unique User DNA.

---

## 🌌 1. PROJECT OVERVIEW & THE MASSIVE ECOSYSTEM

KALI is not just a chat interface. She is an operating system for cognition. The Project-K ecosystem is immense—scaling into thousands of active components across 41 isolated nodes, multi-GB vectorized knowledge structures (ChromaDB), and heavy local LLM integration. 

At her core, she solves the **Loss of Digital Sovereignty** by providing a completely private, un-censorable, and continuously learning intelligence framework. 

---

## 🚀 2. CORE SKILLS (THE PENTAGON)

KALI's true power lies in her dynamically evolving core skills, tailored to empower the user:

### 🧠 Teacher (Progressive Explainer)
KALI actively teaches complex concepts by modifying her delivery to match your precise complexity needs (Beginner, Intermediate, Advanced) using her `explainer.py` engine.

### 🛡️ Mentor (Proactive Guidance)
Acting as an advanced Engineering Mentor, KALI detects vulnerabilities in your logic. Using `gap_detector.py` and `user_dna.py`, she proactively identifies knowledge gaps, offering architectural advice and tactical blueprints.

### 🔄 Self-Learner (Subconscious Evolution)
KALI is in a constant state of self-evolution. Her **Subconscious Learning Loop** (`subconscious.py`) processes knowledge in the background, and her **Failure Intelligence** module allows her to permanently adapt to mistakes.

### 💻 Autonomous Coder (Code Executor)
She doesn't just talk; she writes and executes code locally using her `autonomous_coder.py` and `code_executor.py` layers.

### 👁️ Security Auditor
Her `self_auditor.py` and `integrity.py` scripts act as an immune system, actively checking for anti-patterns and code vulnerabilities.

---

## ⚙️ 3. THE SOVEREIGN SWARM (41+ INTEGRATIONS)

KALI orchestrates a massive fleet of 41+ sub-agents and integration modules. These are just a few of her active "neurons":
- **GitNexus**: Autonomous repository management, commits, and branch strategies.
- **AgentFM**: Background P2P compute and resource monetization.
- **Kiro**: Automated GitHub issue intelligence.
- **Computer Use Agent (CUA)**: Complete headless browser automation.
- **Voice Interface**: Real-time STT/TTS hands-free communication.
- **Graphify**: Generates dynamic knowledge graphs.

---

## 🏗️ 4. SYSTEM ARCHITECTURE

```mermaid
graph TD
    User((User)) --> KaliBat[kali.bat - Ignition]
    KaliBat --> Flask[Flask Gateway / UI]
    Flask --> Processor[DoubtProcessor - Orchestrator]
    
    subgraph Core Skills
        Processor --> Explainer[explainer.py - Teacher]
        Processor --> Mentor[gap_detector.py - Mentor]
        Processor --> SelfLearn[subconscious.py - Self-Learner]
        Processor --> Auditor[self_auditor.py - Auditor]
    end
    
    subgraph The Swarm (41 Nodes)
        Processor --> Integrations[41+ integrations/]
    end

    subgraph Deep Memory
        Processor --> DNA[user_dna.db]
        Processor --> Memory[ChromaDB - Vector Storage]
    end
```

---

## 📂 5. SETUP & INSTALLATION

### 💻 Local Ignition
1. **Secure Clone**:
   ```bash
   git clone https://github.com/Adityavanjre/Project-K.git
   cd Project-K
   ```
2. **Environment Initialization**:
   ```bash
   python -m venv venv
   source venv/bin/activate  # Windows: venv\Scripts\activate
   pip install -r requirements.txt
   ```
3. **Identity & Security Setup**:
   - Copy `.env.example` to `.env` and populate the **REQUIRED** keys. **CRITICAL**: You must set a strong `SECRET_KEY` (min 32 chars) for the Neural Gateway to boot.
   - Copy `config/config.json.example` to `config/config.json` so the Swarm modules have their required endpoints.

4. **Download Sovereign Models**:
   KALI's brain requires local Heavy GGUF models to function securely without cloud reliance.
   - Download the trained models from the Hugging Face Repository: [adityavanjre/KALI-Sovereign-Models](https://huggingface.co/adityavanjre/KALI-Sovereign-Models)
   - Place all downloaded `.gguf` files directly into the `models/` directory at the root of Project-K.

5. **Start KALI**:
   You can ignite KALI using her Python core scripts:
   - **Neural Web Gateway**: `python start_web.py` (Runs locally on port 5000)
   - **Terminal UI**: `python start_cli.py` (Headless operations)
   - **Ollama CLI**: If Ollama is installed, you can use `kali.bat`

---

## 🤝 6. CONTRIBUTION GUIDE
We welcome elite AI/ML engineers. To contribute:
1. Fork the repository.
2. Implement your module in `integrations/` or `src/core/plugins/`.
3. Submit a PR. Note that PRs will be heavily audited for **Sovereignty Compliance** by KALI's internal safety gates.

**Architect**: Aditya Vanjre  
**Mission**: Absolute Knowledge Sovereignty.

---

> *"Arise, awake, find out the great ones and learn of them."* — Katha Upanishad
