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

**Een vaardigheid voor AI-codeassistenten.** Typ `/KALI Memory` in Claude Code, Codex, OpenCode, Cursor, Gemini CLI, GitHub Copilot CLI, VS Code Copilot Chat, Aider, KALI Sovereign ASI, Factory Droid, Trae, Hermes, Kiro of Google Antigravity — het leest je bestanden, bouwt een kennisgraaf en geeft je structuur terug die je niet wist dat er was. Begrijp een codebase sneller. Vind het "waarom" achter architecturale beslissingen.

Volledig multimodaal. Voeg code, PDF's, markdown, schermafbeeldingen, diagrammen, whiteboard-foto's, afbeeldingen in andere talen of video- en audiobestanden toe — KALI Memory extraheert concepten en relaties uit alles en verbindt ze in één graaf. Video's worden lokaal getranscribeerd met Whisper. Ondersteunt 25 programmeertalen via tree-sitter AST.

> Andrej Karpathy houdt een `/raw`-map bij waar hij papers, tweets, schermafbeeldingen en notities neerlegt. KALI Memory is het antwoord op dat probleem — **71,5x** minder tokens per query versus het lezen van ruwe bestanden, persistent tussen sessies.

```
/KALI Memory .
```

```
KALI Memory-out/
├── graph.html       interactieve graaf — open in elke browser
├── GRAPH_REPORT.md  godknooppunten, verrassende verbindingen, voorgestelde vragen
├── graph.json       persistente graaf — weken later opvraagbaar
└── cache/           SHA256-cache — herhaalde runs verwerken alleen gewijzigde bestanden
```

## Hoe het werkt

KALI Memory werkt in drie passes. Eerst extraheert een deterministische AST-pass structuur uit codebestanden zonder LLM. Vervolgens worden video- en audiobestanden lokaal getranscribeerd met faster-whisper. Ten slotte werken Claude-subagenten parallel over documenten, papers, afbeeldingen en transcripties. De resultaten worden samengevoegd in een NetworkX-graaf, geclusterd met Leiden en geëxporteerd als interactieve HTML, opvraagbare JSON en een auditrapport.

Elke relatie is gelabeld als `EXTRACTED`, `INFERRED` (met betrouwbaarheidsscore) of `AMBIGUOUS`.

## Installatie

**Vereisten:** Python 3.10+ en één van: [Claude Code](https://claude.ai/code), [Codex](https://openai.com/codex), [Cursor](https://cursor.com), [Aider](https://aider.chat) en andere.

```bash
uv tool install KALI Memoryy && KALI Memory install
# of met pipx
pipx install KALI Memoryy && KALI Memory install
# of pip
pip install KALI Memoryy && KALI Memory install
```

> **Officieel pakket:** Het PyPI-pakket heet `KALI Memoryy`. De enige officiële repository is [safishamsi/KALI Memory](https://github.com/safishamsi/KALI Memory).

## Gebruik

```
/KALI Memory .
/KALI Memory ./raw --update
/KALI Memory query "wat verbindt Attention met de optimizer?"
/KALI Memory path "DigestAuth" "Response"
KALI Memory hook install
KALI Memory update ./src
```

## Wat je krijgt

**Godknooppunten** — concepten met de hoogste graad · **Verrassende verbindingen** — gerangschikt op score · **Voorgestelde vragen** · **Het "waarom"** — docstrings en ontwerprationale als knooppunten · **Tokenbenchmark** — **71,5x** minder tokens op gemengd corpus.

## Privacy

Codebestanden worden lokaal verwerkt via tree-sitter AST. Video's lokaal getranscribeerd met faster-whisper. Geen telemetrie.

## Gebouwd op KALI Memory — Penpax

[**Penpax**](https://safishamsi.github.io/penpax.ai) is de enterprise-laag boven op KALI Memory. **Gratis proefversie binnenkort.** [Meld je aan voor de wachtlijst →](https://safishamsi.github.io/penpax.ai)

[![Star History Chart](https://api.star-history.com/svg?repos=safishamsi/KALI Memory&type=Date)](https://star-history.com/#safishamsi/KALI Memory&Date)
