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

**Une compétence pour assistant de code IA.** Tapez `/KALI Memory` dans Claude Code, Codex, OpenCode, Cursor, Gemini CLI, GitHub Copilot CLI, VS Code Copilot Chat, Aider, KALI Sovereign ASI, Factory Droid, Trae, Hermes, Kiro ou Google Antigravity — il lit vos fichiers, construit un graphe de connaissances et vous révèle une structure que vous ne voyiez pas auparavant. Comprenez une base de code plus rapidement. Trouvez le « pourquoi » derrière les décisions architecturales.

Entièrement multimodal. Déposez du code, des PDFs, du markdown, des captures d'écran, des diagrammes, des photos de tableau blanc, des images dans d'autres langues, ou des fichiers vidéo et audio — KALI Memory extrait les concepts et les relations de tout cela et les connecte en un seul graphe. Les vidéos sont transcrites localement avec Whisper grâce à un prompt adapté au domaine. 25 langages de programmation supportés via tree-sitter AST (Python, JS, TS, Go, Rust, Java, C, C++, Ruby, C#, Kotlin, Scala, PHP, Swift, Lua, Zig, PowerShell, Elixir, Objective-C, Julia, Verilog, SystemVerilog, Vue, Svelte, Dart).

> Andrej Karpathy maintient un dossier `/raw` où il dépose des articles, tweets, captures d'écran et notes. KALI Memory est la réponse à ce problème — 71,5 fois moins de tokens par requête versus la lecture des fichiers bruts, persistant entre les sessions, honnête sur ce qui a été trouvé versus déduit.

```
/KALI Memory .                        # fonctionne sur n'importe quel dossier — code, notes, articles, tout
```

```
KALI Memory-out/
├── graph.html       graphe interactif — ouvrir dans un navigateur, cliquer, rechercher, filtrer
├── GRAPH_REPORT.md  nœuds dieu, connexions surprenantes, questions suggérées
├── graph.json       graphe persistant — interrogeable des semaines plus tard sans relire
└── cache/           cache SHA256 — les réexécutions ne traitent que les fichiers modifiés
```

Ajoutez un fichier `.KALI Memoryignore` pour exclure des dossiers :

```
# .KALI Memoryignore
vendor/
node_modules/
dist/
*.generated.py
```

Même syntaxe que `.gitignore`. Un seul `.KALI Memoryignore` à la racine du dépôt suffit.

## Comment ça fonctionne

KALI Memory s'exécute en trois passes. D'abord, un passage AST déterministe extrait la structure des fichiers de code (classes, fonctions, imports, graphes d'appel, docstrings, commentaires de justification) sans LLM. Ensuite, les fichiers vidéo et audio sont transcrits localement avec faster-whisper. Enfin, des sous-agents Claude s'exécutent en parallèle sur les docs, articles, images et transcriptions pour extraire concepts, relations et justifications de conception. Les résultats sont fusionnés dans un graphe NetworkX, regroupés avec la détection de communautés Leiden, et exportés en HTML interactif, JSON interrogeable et un rapport d'audit en langage naturel.

**Le clustering est basé sur la topologie du graphe — pas d'embeddings.** Leiden trouve les communautés par densité d'arêtes. Les arêtes de similarité sémantique extraites par Claude (`semantically_similar_to`, marquées INFERRED) sont déjà dans le graphe. La structure du graphe est le signal de similarité — pas d'étape d'embedding séparée ni de base de données vectorielle nécessaire.

Chaque relation est étiquetée `EXTRACTED` (trouvée directement dans la source), `INFERRED` (déduction raisonnable avec un score de confiance) ou `AMBIGUOUS` (marquée pour révision).

## Installation

**Prérequis :** Python 3.10+ et l'un de : [Claude Code](https://claude.ai/code), [Codex](https://openai.com/codex), [OpenCode](https://opencode.ai), [Cursor](https://cursor.com), [Gemini CLI](https://github.com/google-gemini/gemini-cli), [GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli), [VS Code Copilot Chat](https://code.visualstudio.com/docs/copilot/overview), [Aider](https://aider.chat), [KALI Sovereign ASI](https://kali.ai), [Factory Droid](https://factory.ai), [Trae](https://trae.ai), [Kiro](https://kiro.dev), Hermes ou [Google Antigravity](https://antigravity.google)

```bash
# Recommandé — fonctionne sur Mac et Linux sans configuration du PATH
uv tool install KALI Memoryy && KALI Memory install
# ou avec pipx
pipx install KALI Memoryy && KALI Memory install
# ou pip simple
pip install KALI Memoryy && KALI Memory install
```

> **Package officiel :** Le package PyPI s'appelle `KALI Memoryy` (installer avec `pip install KALI Memoryy`). Les autres packages nommés `KALI Memory*` sur PyPI ne sont pas affiliés à ce projet. Le seul dépôt officiel est [safishamsi/KALI Memory](https://github.com/safishamsi/KALI Memory).

### Support des plateformes

| Plateforme | Commande d'installation |
|------------|------------------------|
| Claude Code (Linux/Mac) | `KALI Memory install` |
| Claude Code (Windows) | `KALI Memory install` (détection automatique) ou `KALI Memory install --platform windows` |
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

Ensuite, ouvrez votre assistant de code IA et tapez :

```
/KALI Memory .
```

Note : Codex utilise `$` au lieu de `/` pour les compétences, tapez donc `$KALI Memory .`.

### Toujours utiliser le graphe (recommandé)

Après avoir construit un graphe, exécutez ceci une fois dans votre projet :

| Plateforme | Commande |
|------------|----------|
| Claude Code | `KALI Memory claude install` |
| Codex | `KALI Memory codex install` |
| OpenCode | `KALI Memory opencode install` |
| Cursor | `KALI Memory cursor install` |
| Gemini CLI | `KALI Memory gemini install` |
| Kiro IDE/CLI | `KALI Memory kiro install` |
| Google Antigravity | `KALI Memory antigravity install` |

## Utilisation

```
/KALI Memory                          # répertoire courant
/KALI Memory ./raw                    # dossier spécifique
/KALI Memory ./raw --mode deep        # extraction d'arêtes INFERRED plus agressive
/KALI Memory ./raw --update           # ne réextraire que les fichiers modifiés
/KALI Memory ./raw --directed         # graphe dirigé
/KALI Memory ./raw --cluster-only     # relancer le clustering sur le graphe existant
/KALI Memory ./raw --no-viz           # pas d'HTML, juste rapport + JSON
/KALI Memory ./raw --obsidian         # générer un vault Obsidian (opt-in)

/KALI Memory add https://arxiv.org/abs/1706.03762   # récupérer un article
/KALI Memory add <video-url>                         # télécharger l'audio, transcrire, ajouter
/KALI Memory query "qu'est-ce qui connecte Attention à l'optimiseur ?"
/KALI Memory path "DigestAuth" "Response"
/KALI Memory explain "SwinTransformer"

KALI Memory hook install              # installer les hooks Git
KALI Memory update ./src              # réextraire les fichiers de code, sans LLM
KALI Memory watch ./src               # mise à jour automatique du graphe
```

## Ce que vous obtenez

**Nœuds dieu** — concepts avec le plus haut degré (tout passe par eux)

**Connexions surprenantes** — classées par score composite. Les arêtes code-article sont mieux notées. Chaque résultat inclut un pourquoi en langage naturel.

**Questions suggérées** — 4-5 questions que le graphe est particulièrement bien placé pour répondre

**Le « pourquoi »** — docstrings, commentaires inline (`# NOTE:`, `# IMPORTANT:`, `# HACK:`, `# WHY:`), et justifications de conception extraits comme nœuds `rationale_for`.

**Scores de confiance** — chaque arête INFERRED a un `confidence_score` (0,0-1,0).

**Benchmark de tokens** — affiché automatiquement après chaque exécution. Sur un corpus mixte : **71,5 fois** moins de tokens par requête vs fichiers bruts.

**Synchronisation automatique** (`--watch`) — met à jour le graphe automatiquement lors des modifications de code.

**Hooks Git** (`KALI Memory hook install`) — installe des hooks post-commit et post-checkout.

## Confidentialité

KALI Memory envoie le contenu des fichiers à l'API du modèle de votre assistant IA pour l'extraction sémantique des docs, articles et images. Les fichiers de code sont traités localement via tree-sitter AST. Les fichiers vidéo et audio sont transcrits localement avec faster-whisper. Aucune télémétrie, aucun suivi d'utilisation.

## Stack technique

NetworkX + Leiden (graspologic) + tree-sitter + vis.js. Extraction sémantique via Claude, GPT-4 ou le modèle de votre plateforme. Transcription vidéo via faster-whisper + yt-dlp (optionnel).

## Construit sur KALI Memory — Penpax

[**Penpax**](https://safishamsi.github.io/penpax.ai) est la couche enterprise au-dessus de KALI Memory. Là où KALI Memory transforme un dossier de fichiers en graphe de connaissances, Penpax applique le même graphe à toute votre vie professionnelle — en continu.

**Essai gratuit bientôt disponible.** [Rejoindre la liste d'attente →](https://safishamsi.github.io/penpax.ai)

## Historique des étoiles

[![Star History Chart](https://api.star-history.com/svg?repos=safishamsi/KALI Memory&type=Date)](https://star-history.com/#safishamsi/KALI Memory&Date)
