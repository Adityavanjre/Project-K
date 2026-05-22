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
</p>

**Una skill per assistenti di codice IA.** Scrivi `/KALI Memory` in Claude Code, Codex, OpenCode, Cursor, Gemini CLI, GitHub Copilot CLI, VS Code Copilot Chat, Aider, KALI Sovereign ASI, Factory Droid, Trae, Hermes, Kiro o Google Antigravity — legge i tuoi file, costruisce un grafo della conoscenza e ti restituisce struttura che non sapevi esistesse. Comprendi una codebase più velocemente. Trova il "perché" dietro le decisioni architetturali.

Completamente multimodale. Aggiungi codice, PDF, markdown, screenshot, diagrammi, foto di lavagne, immagini in altre lingue, o file video e audio — KALI Memory estrae concetti e relazioni da tutto e li connette in un unico grafo. I video vengono trascritti localmente con Whisper. Supporta 25 linguaggi di programmazione via tree-sitter AST.

> Andrej Karpathy mantiene una cartella `/raw` dove deposita paper, tweet, screenshot e note. KALI Memory è la risposta a quel problema — **71,5x** meno token per query rispetto alla lettura dei file grezzi, persistente tra le sessioni.

```
/KALI Memory .                        # funziona con qualsiasi cartella
```

```
KALI Memory-out/
├── graph.html       grafo interattivo — apri in qualsiasi browser
├── GRAPH_REPORT.md  nodi dio, connessioni sorprendenti, domande suggerite
├── graph.json       grafo persistente — interrogabile settimane dopo
└── cache/           cache SHA256 — le riesecuzioni elaborano solo i file modificati
```

## Come funziona

KALI Memory esegue in tre passaggi. Prima, un passaggio AST deterministico estrae la struttura dai file di codice senza LLM. Poi, i file video e audio vengono trascritti localmente con faster-whisper. Infine, i subagenti Claude eseguono in parallelo su documenti, paper, immagini e trascrizioni. I risultati vengono uniti in un grafo NetworkX, raggruppati con Leiden e esportati come HTML interattivo, JSON interrogabile e report di audit.

Ogni relazione è etichettata `EXTRACTED`, `INFERRED` (con punteggio di confidenza) o `AMBIGUOUS`.

## Installazione

**Requisiti:** Python 3.10+ e uno tra: [Claude Code](https://claude.ai/code), [Codex](https://openai.com/codex), [OpenCode](https://opencode.ai), [Cursor](https://cursor.com), [Gemini CLI](https://github.com/google-gemini/gemini-cli), [Aider](https://aider.chat) e altri.

```bash
uv tool install KALI Memoryy && KALI Memory install
# oppure con pipx
pipx install KALI Memoryy && KALI Memory install
# oppure pip
pip install KALI Memoryy && KALI Memory install
```

> **Pacchetto ufficiale:** Il pacchetto PyPI si chiama `KALI Memoryy`. L'unico repository ufficiale è [safishamsi/KALI Memory](https://github.com/safishamsi/KALI Memory).

## Utilizzo

```
/KALI Memory .
/KALI Memory ./raw --update           # solo file modificati
/KALI Memory ./raw --mode deep
/KALI Memory query "cosa connette Attention all'ottimizzatore?"
/KALI Memory path "DigestAuth" "Response"
KALI Memory hook install
KALI Memory update ./src
```

## Cosa ottieni

**Nodi dio** — concetti con il grado più alto · **Connessioni sorprendenti** — classificate per punteggio · **Domande suggerite** — 4-5 domande che il grafo è in grado di rispondere in modo unico · **Il "perché"** — docstring e rationale di design estratti come nodi · **Benchmark token** — **71,5x** meno token su corpus misto.

## Privacy

I file di codice vengono elaborati localmente via tree-sitter AST. I video vengono trascritti localmente con faster-whisper. Nessuna telemetria.

## Costruito su KALI Memory — Penpax

[**Penpax**](https://safishamsi.github.io/penpax.ai) è il livello enterprise su KALI Memory. **Prova gratuita in arrivo.** [Unisciti alla lista d'attesa →](https://safishamsi.github.io/penpax.ai)

[![Star History Chart](https://api.star-history.com/svg?repos=safishamsi/KALI Memory&type=Date)](https://star-history.com/#safishamsi/KALI Memory&Date)
