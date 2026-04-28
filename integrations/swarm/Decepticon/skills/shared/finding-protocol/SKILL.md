---
name: finding-protocol
description: "Finding documentation protocol — Markdown template, YAML frontmatter schema, CVSS v4.0 severity guide, confidence levels, naming conventions, post-creation checklist."
allowed-tools: Read Write
metadata:
  subdomain: reporting
  when_to_use: "write finding, record finding, create finding, document vulnerability, FIND-, findings/, severity, cvss"
  tags: finding, protocol, template, cvss, severity, reporting, documentation
  mitre_attack: []
---

# Finding Protocol

## Recording Findings

When you discover a vulnerability or notable security issue, create an individual
Markdown file in the `findings/` directory using `write_file()`.

### File Naming Convention
`findings/{severity}-{slugified-title}.md`

Derive the slug from the finding title — lowercase, hyphens for spaces, strip special characters.
The `id` field in YAML frontmatter (FIND-001, FIND-002, ...) is the canonical cross-reference.
Determine the next ID by counting existing files: `ls findings/*.md | wc -l`.

Examples:
- `findings/critical-exposed-mysql-api-example-com.md`
- `findings/high-subdomain-takeover-staging-herokuapp.md`
- `findings/medium-missing-hsts-header-www.md`

### Finding Document Template
Every finding MUST use this Markdown structure with YAML frontmatter:

```markdown
---
id: FIND-001
severity: critical
cvss_score: 9.8
cvss_vector: "CVSS:4.0/AV:N/AC:L/AT:N/PR:N/UI:N/VC:H/VI:H/VA:H/SC:N/SI:N/SA:N"
cvss_version: "4.0"
cwe: [CWE-89]
mitre: [T1190]
affected_target: "10.0.0.5"
affected_component: "MySQL 5.7 on port 3306"
confidence: verified
objective_id: OBJ-001
phase: recon
agent: recon
detected: null
remediation_priority: immediate
discovered_at: "2026-04-06T14:23:11Z"
---

# [CRITICAL] SQL Injection in api.example.com/login allows Full DB Compromise

## Description
Technical description of the vulnerability.

## Steps to Reproduce
1. Connect to MySQL on port 3306
2. Attempt login with default credentials root:(empty)
3. Observe successful authentication without password

## Impact
Full database compromise without credentials. Contains PII for ~50,000 users.

## Evidence
| # | Type | Path | Description |
|---|------|------|-------------|
| 1 | scan-output | findings/evidence/FIND-001_nmap.txt | nmap service scan |
| 2 | terminal-log | findings/evidence/FIND-001_mysql_access.txt | MySQL login session |

## Detection
- **Detected by Blue Team**: No
- **Notes**: No SIEM alert triggered for unauthenticated MySQL access

## Remediation
Set a strong root password, restrict MySQL to localhost or internal VLAN only,
enable audit logging for authentication attempts.

## References
- CWE-89: https://cwe.mitre.org/data/definitions/89.html
- MITRE T1190: https://attack.mitre.org/techniques/T1190/
```

### After Creating a Finding
1. Save raw evidence to `findings/evidence/FIND-{NNN}_{description}.txt`
2. Append a one-line summary to `findings.md`:
   `## [FIND-001] [CRITICAL] SQL Injection in api.example.com/login (OBJ-001, T1190)`
3. Append a timeline entry to `timeline.jsonl`:
   `{"ts":"...","type":"finding","id":"FIND-001","severity":"critical","agent":"recon","objective":"OBJ-001"}`

### Severity Guide (CVSS v4.0)
- **CRITICAL** (9.0-10.0): Immediate exploitation, data breach, full compromise
- **HIGH** (7.0-8.9): Known CVE, significant misconfiguration, privilege escalation
- **MEDIUM** (4.0-6.9): Information disclosure, weak configuration
- **LOW** (0.1-3.9): Hardening recommendation, informational
- **INFORMATIONAL** (0.0): Observation, no direct security impact

### Confidence Levels
- **verified**: Confirmed with 2+ methods — REQUIRED for CRITICAL/HIGH
- **probable**: Strong indicators but single method
- **unverified**: Initial observation, needs confirmation

### Rules
- One Markdown file per finding — do NOT bundle multiple vulnerabilities
- ALL agent documents use Markdown format — never write JSON as a deliverable document
- CVSS v4.0 is the primary scoring system (include v3.1 only if dual-reporting needed)
- Do NOT write to findings.md without a corresponding finding .md file
- Detection field should be filled when Blue Team visibility is known
