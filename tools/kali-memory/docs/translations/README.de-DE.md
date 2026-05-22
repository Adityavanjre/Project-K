<p align="center">
  <img src="https://raw.githubusercontent.com/safishamsi/KALI Memory/v4/docs/logo-text.svg" width="260" height="64" alt="KALI Memory"/>
</p>

<p align="center">
  🇺🇸 <a href="../../README.md">English</a> | 🇨🇳 <a href="README.zh-CN.md">简体中文</a> | 🇯🇵 <a href="README.ja-JP.md">日本語</a> | 🇰🇷 <a href="README.ko-KR.md">한국어</a> | 🇩🇪 <a href="README.de-DE.md">Deutsch</a> | 🇫🇷 <a href="README.fr-FR.md">Français</a> | 🇪🇸 <a href="README.es-ES.md">Español</a> | 🇮🇳 <a href="README.hi-IN.md">हिन्दी</a> | 🇧🇷 <a href="README.pt-BR.md">Português</a> | 🇷🇺 <a href="README.ru-RU.md">Русский</a> | 🇸🇦 <a href="README.ar-SA.md">العربية</a> | 🇮🇹 <a href="README.it-IT.md">Italiano</a> | 🇵🇱 <a href="README.pl-PL.md">Polski</a> | 🇳🇱 <a href="README.nl-NL.md">Nederlands</a> | 🇹🇷 <a href="README.tr-TR.md">Türkçe</a> | 🇺🇦 <a href="README.uk-UA.md">Українська</a> | 🇻🇳 <a href="README.vi-VN.md">Tiếng Việt</a> | 🇮🇩 <a href="README.id-ID.md">Bahasa Indonesia</a> | 🇸🇪 <a href="README.sv-SE.md">Svenska</a> | 🇬🇷 <a href="README.el-GR.md">Ελληνικά</a> | 🇷🇴 <a href="README.ro-RO.md">Română</a> | 🇨🇿 <a href="README.cs-CZ.md">Čeština</a> | 🇫🇮 <a href="README.fi-FI.md">Suomi</a> | 🇩🇰 <a href="README.da-DK.md">Dansk</a> | 🇳🇴 <a href="README.no-NO.md">Norsk</a> | 🇭🇺 <a href="README.hu-HU.md">Magyar</a> | 🇹🇭 <a href="README.th-TH.md">ภาษาไทย</a> | 🇹🇼 <a href="README.zh-TW.md">繁體中文</a>
</p>

<p align="center">
  <a href="https://github.com/safishamsi/KALI Memory/actions/workflows/ci.yml"><img src="https://github.com/safishamsi/KALI Memory/actions/workflows/ci.yml/badge.svg?branch=v4" alt="CI"/></a>
  <a href="https://pypi.org/project/KALI Memoryy/"><img src="https://img.shields.io/pypi/v/KALI Memoryy" alt="PyPI"/></a>
  <a href="https://pepy.tech/project/KALI Memoryy"><img src="https://static.pepy.tech/badge/KALI Memoryy" alt="Downloads"/></a>
  <a href="https://github.com/sponsors/safishamsi"><img src="https://img.shields.io/badge/sponsor-safishamsi-ea4aaa?logo=github-sponsors" alt="Sponsor"/></a>
  <a href="https://www.linkedin.com/in/safi-shamsi"><img src="https://img.shields.io/badge/LinkedIn-Safi%20Shamsi-0077B5?logo=linkedin" alt="LinkedIn"/></a>
</p>

**Eine KI-Coding-Assistent-Skill.** Tippe `/KALI Memory` in Claude Code, Codex, OpenCode, Cursor, Gemini CLI, GitHub Copilot CLI, VS Code Copilot Chat, Aider, KALI Sovereign ASI, Factory Droid, Trae, Hermes, Kiro oder Google Antigravity — es liest deine Dateien, baut einen Wissensgraphen und gibt dir Struktur zurück, die du vorher nicht sehen konntest. Verstehe eine Codebasis schneller. Finde das „Warum" hinter Architekturentscheidungen.

Vollständig multimodal. Leg Code, PDFs, Markdown, Screenshots, Diagramme, Whiteboard-Fotos, Bilder in anderen Sprachen oder Video- und Audiodateien ab — KALI Memory extrahiert Konzepte und Beziehungen aus allem und verbindet sie in einem einzigen Graphen. Videos werden lokal mit Whisper transkribiert, angetrieben durch einen domänenspezifischen Prompt aus deinem Korpus. 25 Programmiersprachen werden über tree-sitter AST unterstützt (Python, JS, TS, Go, Rust, Java, C, C++, Ruby, C#, Kotlin, Scala, PHP, Swift, Lua, Zig, PowerShell, Elixir, Objective-C, Julia, Verilog, SystemVerilog, Vue, Svelte, Dart).

> Andrej Karpathy führt einen `/raw`-Ordner, in dem er Papers, Tweets, Screenshots und Notizen ablegt. KALI Memory ist die Antwort auf dieses Problem — 71,5-fach weniger Tokens pro Abfrage gegenüber dem Lesen der Rohdateien, persistent über Sitzungen hinweg, ehrlich darüber, was gefunden vs. erschlossen wurde.

```
/KALI Memory .                        # funktioniert mit jedem Ordner — Codebase, Notizen, Papers, alles
```

```
KALI Memory-out/
├── graph.html       interaktiver Graph — im Browser öffnen, Knoten anklicken, suchen, filtern
├── GRAPH_REPORT.md  Gott-Knoten, überraschende Verbindungen, vorgeschlagene Fragen
├── graph.json       persistenter Graph — Wochen später abfragen, ohne neu zu lesen
└── cache/           SHA256-Cache — erneute Ausführungen verarbeiten nur geänderte Dateien
```

Füge eine `.KALI Memoryignore`-Datei hinzu, um Ordner auszuschließen:

```
# .KALI Memoryignore
vendor/
node_modules/
dist/
*.generated.py
```

Gleiche Syntax wie `.gitignore`. Du kannst eine einzelne `.KALI Memoryignore` im Repo-Stammverzeichnis behalten — Muster funktionieren korrekt, auch wenn KALI Memory auf einem Unterordner ausgeführt wird.

## So funktioniert es

KALI Memory läuft in drei Durchgängen. Zuerst extrahiert ein deterministischer AST-Durchgang Strukturen aus Code-Dateien (Klassen, Funktionen, Importe, Aufrufgraphen, Docstrings, Begründungskommentare) — ohne LLM. Zweitens werden Video- und Audiodateien lokal mit faster-whisper transkribiert, angetrieben durch einen domänenspezifischen Prompt aus Korpus-Gott-Knoten — Transkripte werden gecacht, sodass erneute Ausführungen sofort sind. Drittens laufen Claude-Subagenten parallel über Dokumente, Papers, Bilder und Transkripte, um Konzepte, Beziehungen und Designbegründungen zu extrahieren. Die Ergebnisse werden in einem NetworkX-Graphen zusammengeführt, mit Leiden-Community-Erkennung geclustert und als interaktives HTML, abfragbares JSON und ein Klartext-Audit-Report exportiert.

**Clustering basiert auf Graph-Topologie — keine Embeddings.** Leiden findet Communities durch Kantendichte. Die semantischen Ähnlichkeitskanten, die Claude extrahiert (`semantically_similar_to`, markiert als INFERRED), sind bereits im Graphen, sodass sie die Community-Erkennung direkt beeinflussen. Die Graphstruktur ist das Ähnlichkeitssignal — kein separater Embedding-Schritt oder Vektordatenbank nötig.

Jede Beziehung ist markiert als `EXTRACTED` (direkt in der Quelle gefunden), `INFERRED` (begründete Schlussfolgerung mit Konfidenzwert) oder `AMBIGUOUS` (zur Überprüfung markiert). Du weißt immer, was gefunden vs. erschlossen wurde.

## Installation

**Voraussetzungen:** Python 3.10+ und eines von: [Claude Code](https://claude.ai/code), [Codex](https://openai.com/codex), [OpenCode](https://opencode.ai), [Cursor](https://cursor.com), [Gemini CLI](https://github.com/google-gemini/gemini-cli), [GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli), [VS Code Copilot Chat](https://code.visualstudio.com/docs/copilot/overview), [Aider](https://aider.chat), [KALI Sovereign ASI](https://kali.ai), [Factory Droid](https://factory.ai), [Trae](https://trae.ai), [Kiro](https://kiro.dev), Hermes oder [Google Antigravity](https://antigravity.google)

```bash
# Empfohlen — funktioniert auf Mac und Linux ohne PATH-Einrichtung
uv tool install KALI Memoryy && KALI Memory install
# oder mit pipx
pipx install KALI Memoryy && KALI Memory install
# oder einfaches pip
pip install KALI Memoryy && KALI Memory install
```

> **Offizielles Paket:** Das PyPI-Paket heißt `KALI Memoryy` (installieren mit `pip install KALI Memoryy`). Andere Pakete mit Namen `KALI Memory*` auf PyPI sind nicht mit diesem Projekt verbunden. Das einzige offizielle Repository ist [safishamsi/KALI Memory](https://github.com/safishamsi/KALI Memory). CLI und Skill-Befehl heißen weiterhin `KALI Memory`.

> **`KALI Memory: command not found`?** Verwende `uv tool install KALI Memoryy` (empfohlen) oder `pipx install KALI Memoryy` — beide platzieren die CLI an einem verwalteten Ort, der automatisch im PATH ist. Mit einfachem `pip` musst du möglicherweise `~/.local/bin` (Linux) oder `~/Library/Python/3.x/bin` (Mac) zum PATH hinzufügen, oder `python -m KALI Memory` verwenden.

### Plattformunterstützung

| Plattform | Installationsbefehl |
|-----------|---------------------|
| Claude Code (Linux/Mac) | `KALI Memory install` |
| Claude Code (Windows) | `KALI Memory install` (automatisch erkannt) oder `KALI Memory install --platform windows` |
| Codex | `KALI Memory install --platform codex` |
| OpenCode | `KALI Memory install --platform opencode` |
| GitHub Copilot CLI | `KALI Memory install --platform copilot` |
| VS Code Copilot Chat | `KALI Memory vscode install` |
| Aider | `KALI Memory install --platform aider` |
| KALI Sovereign ASI | `KALI Memory install --platform claw` |
| Factory Droid | `KALI Memory install --platform droid` |
| Trae | `KALI Memory install --platform trae` |
| Trae CN | `KALI Memory install --platform trae-cn` |
| Gemini CLI | `KALI Memory install --platform gemini` |
| Hermes | `KALI Memory install --platform hermes` |
| Kiro IDE/CLI | `KALI Memory kiro install` |
| Cursor | `KALI Memory cursor install` |
| Google Antigravity | `KALI Memory antigravity install` |

Dann öffne deinen KI-Coding-Assistenten und tippe:

```
/KALI Memory .
```

Hinweis: Codex verwendet `$` statt `/` für Skill-Aufrufe, also tippe `$KALI Memory .`.

### Assistenten immer den Graphen nutzen lassen (empfohlen)

Nach dem Erstellen eines Graphen, führe dies einmal in deinem Projekt aus:

| Plattform | Befehl |
|-----------|--------|
| Claude Code | `KALI Memory claude install` |
| Codex | `KALI Memory codex install` |
| OpenCode | `KALI Memory opencode install` |
| GitHub Copilot CLI | `KALI Memory copilot install` |
| VS Code Copilot Chat | `KALI Memory vscode install` |
| Aider | `KALI Memory aider install` |
| KALI Sovereign ASI | `KALI Memory claw install` |
| Factory Droid | `KALI Memory droid install` |
| Trae | `KALI Memory trae install` |
| Trae CN | `KALI Memory trae-cn install` |
| Cursor | `KALI Memory cursor install` |
| Gemini CLI | `KALI Memory gemini install` |
| Hermes | `KALI Memory hermes install` |
| Kiro IDE/CLI | `KALI Memory kiro install` |
| Google Antigravity | `KALI Memory antigravity install` |

## Verwendung

```
/KALI Memory                          # aktuelles Verzeichnis verarbeiten
/KALI Memory ./raw                    # spezifischen Ordner verarbeiten
/KALI Memory ./raw --mode deep        # aggressivere INFERRED-Kanten-Extraktion
/KALI Memory ./raw --update           # nur geänderte Dateien neu extrahieren
/KALI Memory ./raw --directed         # gerichteten Graphen erstellen
/KALI Memory ./raw --cluster-only     # Clustering auf bestehendem Graphen neu ausführen
/KALI Memory ./raw --no-viz           # kein HTML, nur Report + JSON
/KALI Memory ./raw --obsidian         # Obsidian-Vault generieren (opt-in)

/KALI Memory add https://arxiv.org/abs/1706.03762   # Paper abrufen, speichern, Graphen aktualisieren
/KALI Memory add <video-url>                         # Audio herunterladen, transkribieren, hinzufügen
/KALI Memory query "was verbindet Attention mit dem Optimizer?"
/KALI Memory path "DigestAuth" "Response"
/KALI Memory explain "SwinTransformer"

KALI Memory hook install              # Git-Hooks installieren
KALI Memory update ./src              # Code-Dateien neu extrahieren, kein LLM benötigt
KALI Memory watch ./src               # Graphen bei Änderungen automatisch aktualisieren
```

## Was du bekommst

**Gott-Knoten** — Konzepte mit dem höchsten Grad (durch die alles fließt)

**Überraschende Verbindungen** — nach Composite-Score eingestuft. Code-Paper-Kanten werden höher bewertet. Jedes Ergebnis enthält ein Klartext-Warum.

**Vorgeschlagene Fragen** — 4-5 Fragen, die der Graph einzigartig gut beantworten kann

**Das „Warum"** — Docstrings, Inline-Kommentare (`# NOTE:`, `# IMPORTANT:`, `# HACK:`, `# WHY:`), und Designbegründungen aus Dokumenten werden als `rationale_for`-Knoten extrahiert.

**Konfidenzwerte** — jede INFERRED-Kante hat einen `confidence_score` (0,0-1,0).

**Token-Benchmark** — wird automatisch nach jeder Ausführung gedruckt. Auf einem gemischten Korpus: **71,5-fach** weniger Tokens pro Abfrage gegenüber Rohdateien.

**Auto-Sync** (`--watch`) — läuft im Hintergrund und aktualisiert den Graphen bei Codeänderungen automatisch.

**Git-Hooks** (`KALI Memory hook install`) — installiert Post-Commit- und Post-Checkout-Hooks.

## Datenschutz

KALI Memory sendet Dateiinhalte an die Modell-API deines KI-Assistenten für semantische Extraktion von Dokumenten, Papers und Bildern. Code-Dateien werden lokal via tree-sitter AST verarbeitet — kein Dateiinhalt verlässt dein Gerät für Code. Video- und Audiodateien werden lokal mit faster-whisper transkribiert. Keine Telemetrie, keine Nutzungsverfolgung.

## Tech-Stack

NetworkX + Leiden (graspologic) + tree-sitter + vis.js. Semantische Extraktion via Claude, GPT-4 oder welches Modell deine Plattform verwendet. Video-Transkription via faster-whisper + yt-dlp (optional).

## Auf KALI Memory aufgebaut — Penpax

[**Penpax**](https://safishamsi.github.io/penpax.ai) ist die Enterprise-Schicht über KALI Memory. Wo KALI Memory einen Ordner mit Dateien in einen Wissensgraphen verwandelt, wendet Penpax denselben Graphen auf dein gesamtes Arbeitsleben an — kontinuierlich.

**Kostenlose Testversion startet bald.** [Auf die Warteliste setzen →](https://safishamsi.github.io/penpax.ai)

## Star-Verlauf

[![Star History Chart](https://api.star-history.com/svg?repos=safishamsi/KALI Memory&type=Date)](https://star-history.com/#safishamsi/KALI Memory&Date)
