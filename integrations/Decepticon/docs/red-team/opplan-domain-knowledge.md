# Red Team OPPLAN Domain Knowledge

> Research compiled 2026-04-02. Sources: redteam.guide, ThreatExpress, TIBER-EU, CBEST, CORIE,
> MITRE ATT&CK, Unified Kill Chain, Red Team Maturity Model, OffSec.

## 1. Document Hierarchy

Red team engagements use a 6-level planning hierarchy adapted from military doctrine:

| Level | Document | Purpose |
|-------|----------|---------|
| 1 | **Rules of Engagement (RoE)** | Legally binding scope, boundaries, authorization |
| 2 | **Engagement Plan** | Overarching technical requirements framework |
| 3 | **CONOPS** | Non-technical executive overview of how objectives will be met |
| 4 | **Resource Plan** | Dates, personnel, hardware, cloud requirements |
| 5 | **Operations Plan (OPPLAN)** | Specific tactical details, TTPs, stopping conditions |
| 6 | **Mission Plan** | Exact commands, execution timing, cell-specific actions |

**Key distinction from pentesting**: A pentest scope document lists target systems and authorized
test types. A red team OPPLAN is objective-driven, adversary-modeled, phase-sequenced, with
OPSEC constraints, stopping conditions, and C2 infrastructure tiers.

Sources:
- https://simpuar.github.io/posts/THM_Red_Team_Engagements/
- https://threatexpress.com/redteaming/redteamplanning/redteamchecklist/
- https://redteam.guide/docs/checklists/roe-planning/

## 2. Kill Chain Models

### Lockheed Martin Cyber Kill Chain (7 stages)
Reconnaissance → Weaponization → Delivery → Exploitation → Installation → C2 → Actions on Objectives

- Strength: Simple, executive-friendly
- Weakness: Linear, no lateral movement or post-compromise depth

### MITRE ATT&CK (14 tactics)
Reconnaissance, Resource Development, Initial Access, Execution, Persistence, Privilege Escalation,
Defense Evasion, Credential Access, Discovery, Lateral Movement, Collection, C2, Exfiltration, Impact

- Strength: Granular TTP mapping, industry standard
- Weakness: Time-agnostic (tactics have no inherent ordering)

### Unified Kill Chain (18 phases, 3 cycles)
Created by Paul Pols (2017, Fox-IT/Leiden University). Combines Lockheed Martin + ATT&CK:

**IN Cycle** (Initial Foothold — 8 phases):
Reconnaissance → Weaponization → Social Engineering → Delivery → Exploitation →
Persistence → Defense Evasion → C2

**THROUGH Cycle** (Network Propagation — 6 phases, loops):
Pivoting → Discovery → Privilege Escalation → Execution → Credential Access → Lateral Movement

**OUT Cycle** (Actions on Objectives — 4 phases):
Collection → Exfiltration → Impact → Objectives

### Practical 5-Phase Model (Decepticon)

Maps to sub-agent routing and covers the three UKC cycles:

| Phase | UKC Mapping | Sub-Agent | MITRE Tactics |
|-------|-------------|-----------|---------------|
| `recon` | IN phases 1-4 | recon | TA0043 Reconnaissance |
| `initial-access` | IN phases 5-8 | exploit | TA0001 Initial Access, TA0002 Execution |
| `post-exploit` | THROUGH phases 9-14 | postexploit | TA0003-TA0009 (Persistence thru Collection) |
| `c2` | Cross-cutting | postexploit | TA0011 Command and Control |
| `exfiltration` | OUT phases 15-18 | postexploit | TA0010 Exfiltration, Impact |

Sources:
- https://www.unifiedkillchain.com/assets/The-Unified-Kill-Chain.pdf
- https://www.splunk.com/en_us/blog/learn/cyber-kill-chains.html
- https://attack.mitre.org/resources/adversary-emulation-plans/

## 3. OPSEC in Red Team Context

OPSEC = "understanding what actions Blue can observe and minimizing exposure."

### 5-Step OPSEC Cycle
1. **Identify critical information** — what reveals the RT operation if observed
2. **Analyze threats** — defender capabilities (SIEM, EDR, SOC, etc.)
3. **Analyze vulnerabilities** — which RT actions create observable indicators
4. **Assess risk** — likelihood and impact of detection per action
5. **Apply countermeasures** — modify TTPs, C2 timing, tool signatures

### OPSEC Levels (Red Team Maturity Model)

| Level | Name | Description | C2 Tier | Constraints |
|-------|------|-------------|---------|-------------|
| 1 | **Loud** | No evasion; testing detection | Interactive | Default tool flags OK |
| 2 | **Standard** | Basic OPSEC; modify default signatures | Interactive | Custom user-agents, varied timing |
| 3 | **Careful** | Active evasion; avoid known signatures | Short Haul | LOLBins preferred, no disk drops |
| 4 | **Quiet** | Minimal footprint; blend with normal traffic | Long Haul | Living-off-the-land only, encrypted C2 |
| 5 | **Silent** | Zero detection tolerance; abort if burned | Long Haul | Custom tooling, domain fronting |

### C2 Tier Architecture

| Tier | Name | Purpose | Callback | Example |
|------|------|---------|----------|---------|
| 1 | **Interactive** | Direct operator control | Seconds | Sliver interactive, Cobalt Strike |
| 2 | **Short Haul** | Reliable access, periodic callbacks | Minutes-hours | Sliver beacon, DNS beacons |
| 3 | **Long Haul** | Persistent fallback, very low profile | Hours-days | Custom implant, domain fronting |

Sources:
- https://redteam.guide/docs/definitions/
- https://redteam.guide/docs/Planning/red-team-tradecraft/
- https://www.redteammaturity.com/

## 4. Red Team Objective Structure

### Decomposition Process
1. Start from **threat actor profile** (intent, capability, known TTPs)
2. Define **strategic goals** (business-impact: "access customer financial records")
3. Map to **kill chain phases** (IN → THROUGH → OUT)
4. Break into **discrete objectives** (one per agent context window)
5. Assign **MITRE ATT&CK technique IDs** per objective

### Required Objective Metadata

| Field | Required | Red-Team-Specific | Description |
|-------|----------|-------------------|-------------|
| ID | Yes | No | Unique identifier (OBJ-001) |
| Phase | Yes | No | Kill chain phase |
| Title | Yes | No | Short description |
| Description | Yes | No | Detailed operational instructions |
| Acceptance Criteria | Yes | No | Verifiable success conditions ("flags" in CORIE) |
| Priority | Yes | No | Execution order |
| Status | Yes | No | pending/in-progress/passed/blocked |
| MITRE ATT&CK IDs | Yes | Partially | Technique IDs being exercised |
| **OPSEC Level** | Yes | **Yes** | How stealthy this objective must be |
| **Detection Risk** | Yes | **Yes** | Expected probability of triggering alerts |
| **C2 Tier** | Recommended | **Yes** | Which C2 channel to use |
| **Concessions** | Recommended | **Yes** | Pre-authorized assists if blocked (TIBER/CORIE) |
| Blocked By | Yes | No | Dependency on other objectives |
| Owner | Yes | No | Assigned operator/sub-agent |
| Tools | Optional | No | Approved tooling for this objective |

### Concessions (TIBER-EU / CORIE Concept)

Pre-authorized assists when an objective cannot be achieved through natural attack progression.
Examples:
- "If initial access via web app fails after 5 attempts, white cell provides VPN credentials"
- "If lateral movement to domain controller is blocked, skip to credential dump on compromised host"

This is critical for autonomous agents that may get stuck at a kill chain gate.

## 5. Regulatory Frameworks

### TIBER-EU (ECB, Europe)
Required documents: Scope Spec → GTL Report → TTI Report → Red Team Test Plan → Reports
Key: TI provider and RT provider must be separate entities.
Source: https://www.ecb.europa.eu/paym/cyber-resilience/tiber-eu/html/index.en.html

### CBEST (Bank of England, UK)
Phases: Planning → Attack Preparation → Attack Execution → Exercise Closure
Key: Control Group can halt assessment at any time.
Source: https://www.bankofengland.co.uk/financial-stability/operational-resilience-of-the-financial-sector/cbest-threat-intelligence-led-assessments-implementation-guide

### CORIE (CFR Australia)
Most detailed public framework. 6 stages across 3 phases.
Unique: Concession framework, tiered approach, mandatory purple team replay.
Source: https://www.cfr.gov.au/publications/policy-statements-and-other-reports/2022/revised-corie-framework-rollout/cyber-operational-resilience-intelligence-led-exercises-corie-framework.html

## 6. Red Team vs Pentest Planning Differences

| Dimension | Pentest | Red Team |
|-----------|---------|----------|
| Objective | Find vulnerabilities | Test detection & response |
| Scope | Specific systems/CIDR | Organization-wide |
| Duration | 1-3 weeks | 2-6 months |
| Stealth | Usually announced | Covert |
| OPSEC | None | Structured per objective |
| Kill chain | Exploit individual vulns | Full IN→THROUGH→OUT cycle |
| Detection | N/A | Primary deliverable |
| Threat model | Generic attacker | Specific adversary emulation |
| Planning docs | Scope doc + test plan | RoE + CONOPS + OPPLAN + Deconfliction |
| C2 | Single tool | Multi-tier C2 architecture |
| Success metric | Vuln count/severity | Objectives achieved + TTD + response |

Sources:
- https://www.offsec.com/blog/red-teaming-vs-pentesting/
- https://www.nuharborsecurity.com/blog/red-teaming-vs-penetration-testing
