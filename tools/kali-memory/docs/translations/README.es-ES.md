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

**Una habilidad para asistentes de código IA.** Escribe `/KALI Memory` en Claude Code, Codex, OpenCode, Cursor, Gemini CLI, GitHub Copilot CLI, VS Code Copilot Chat, Aider, KALI Sovereign ASI, Factory Droid, Trae, Hermes, Kiro o Google Antigravity — lee tus archivos, construye un grafo de conocimiento y te devuelve estructura que no sabías que existía. Entiende una base de código más rápido. Encuentra el «por qué» detrás de las decisiones arquitectónicas.

Totalmente multimodal. Deposita código, PDFs, markdown, capturas de pantalla, diagramas, fotos de pizarras, imágenes en otros idiomas, o archivos de video y audio — KALI Memory extrae conceptos y relaciones de todo ello y los conecta en un solo grafo. Los videos se transcriben localmente con Whisper usando un prompt adaptado al dominio derivado de tu corpus. 25 lenguajes de programación soportados mediante tree-sitter AST (Python, JS, TS, Go, Rust, Java, C, C++, Ruby, C#, Kotlin, Scala, PHP, Swift, Lua, Zig, PowerShell, Elixir, Objective-C, Julia, Verilog, SystemVerilog, Vue, Svelte, Dart).

> Andrej Karpathy mantiene una carpeta `/raw` donde deposita papers, tweets, capturas de pantalla y notas. KALI Memory es la respuesta a ese problema — 71,5 veces menos tokens por consulta versus leer los archivos sin procesar, persistente entre sesiones, honesto sobre lo que encontró versus lo que infirió.

```
/KALI Memory .                        # funciona con cualquier carpeta — tu código, notas, papers, todo
```

```
KALI Memory-out/
├── graph.html       grafo interactivo — abrir en cualquier navegador, hacer clic en nodos, buscar
├── GRAPH_REPORT.md  nodos dios, conexiones sorprendentes, preguntas sugeridas
├── graph.json       grafo persistente — consultar semanas después sin releer
└── cache/           caché SHA256 — las re-ejecuciones solo procesan archivos modificados
```

Añade un archivo `.KALI Memoryignore` para excluir carpetas:

```
# .KALI Memoryignore
vendor/
node_modules/
dist/
*.generated.py
```

Misma sintaxis que `.gitignore`. Puedes mantener un único `.KALI Memoryignore` en la raíz del repositorio.

## Cómo funciona

KALI Memory se ejecuta en tres pasadas. Primero, una pasada AST determinista extrae estructura de los archivos de código (clases, funciones, importaciones, grafos de llamadas, docstrings, comentarios de justificación) sin necesidad de LLM. Segundo, los archivos de video y audio se transcriben localmente con faster-whisper usando un prompt adaptado al dominio derivado de los nodos dios del corpus. Tercero, subagentes de Claude se ejecutan en paralelo sobre documentos, papers, imágenes y transcripciones para extraer conceptos, relaciones y justificaciones de diseño. Los resultados se fusionan en un grafo NetworkX, se agrupan con detección de comunidades Leiden, y se exportan como HTML interactivo, JSON consultable y un informe de auditoría en lenguaje natural.

**El clustering se basa en la topología del grafo — sin embeddings.** Leiden encuentra comunidades por densidad de aristas. Las aristas de similitud semántica que Claude extrae (`semantically_similar_to`, marcadas como INFERRED) ya están en el grafo. La estructura del grafo es la señal de similitud — no se necesita paso de embedding separado ni base de datos vectorial.

Cada relación está etiquetada como `EXTRACTED` (encontrada directamente en la fuente), `INFERRED` (inferencia razonable con puntuación de confianza) o `AMBIGUOUS` (marcada para revisión).

## Instalación

**Requisitos:** Python 3.10+ y uno de: [Claude Code](https://claude.ai/code), [Codex](https://openai.com/codex), [OpenCode](https://opencode.ai), [Cursor](https://cursor.com), [Gemini CLI](https://github.com/google-gemini/gemini-cli), [GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli), [VS Code Copilot Chat](https://code.visualstudio.com/docs/copilot/overview), [Aider](https://aider.chat), [KALI Sovereign ASI](https://kali.ai), [Factory Droid](https://factory.ai), [Trae](https://trae.ai), [Kiro](https://kiro.dev), Hermes o [Google Antigravity](https://antigravity.google)

```bash
# Recomendado — funciona en Mac y Linux sin configurar el PATH
uv tool install KALI Memoryy && KALI Memory install
# o con pipx
pipx install KALI Memoryy && KALI Memory install
# o pip simple
pip install KALI Memoryy && KALI Memory install
```

> **Paquete oficial:** El paquete PyPI se llama `KALI Memoryy` (instalar con `pip install KALI Memoryy`). Otros paquetes llamados `KALI Memory*` en PyPI no están afiliados con este proyecto. El único repositorio oficial es [safishamsi/KALI Memory](https://github.com/safishamsi/KALI Memory).

### Soporte de plataformas

| Plataforma | Comando de instalación |
|------------|------------------------|
| Claude Code (Linux/Mac) | `KALI Memory install` |
| Claude Code (Windows) | `KALI Memory install` (detección automática) o `KALI Memory install --platform windows` |
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

Luego abre tu asistente de código IA y escribe:

```
/KALI Memory .
```

Nota: Codex usa `$` en lugar de `/` para habilidades, así que escribe `$KALI Memory .`.

### Hacer que el asistente siempre use el grafo (recomendado)

Después de construir un grafo, ejecuta esto una vez en tu proyecto:

| Plataforma | Comando |
|------------|---------|
| Claude Code | `KALI Memory claude install` |
| Codex | `KALI Memory codex install` |
| OpenCode | `KALI Memory opencode install` |
| Cursor | `KALI Memory cursor install` |
| Gemini CLI | `KALI Memory gemini install` |
| Kiro IDE/CLI | `KALI Memory kiro install` |
| Google Antigravity | `KALI Memory antigravity install` |

## Uso

```
/KALI Memory                          # directorio actual
/KALI Memory ./raw                    # carpeta específica
/KALI Memory ./raw --mode deep        # extracción de aristas INFERRED más agresiva
/KALI Memory ./raw --update           # re-extraer solo archivos modificados
/KALI Memory ./raw --directed         # grafo dirigido
/KALI Memory ./raw --cluster-only     # re-ejecutar clustering en grafo existente
/KALI Memory ./raw --no-viz           # sin HTML, solo informe + JSON
/KALI Memory ./raw --obsidian         # generar vault de Obsidian (opt-in)

/KALI Memory add https://arxiv.org/abs/1706.03762   # obtener un paper
/KALI Memory add <video-url>                         # descargar audio, transcribir, añadir
/KALI Memory query "¿qué conecta Attention con el optimizador?"
/KALI Memory path "DigestAuth" "Response"
/KALI Memory explain "SwinTransformer"

KALI Memory hook install              # instalar hooks de Git
KALI Memory update ./src              # re-extraer archivos de código, sin LLM
KALI Memory watch ./src               # actualización automática del grafo
```

## Qué obtienes

**Nodos dios** — conceptos con mayor grado (por donde todo pasa)

**Conexiones sorprendentes** — clasificadas por puntuación compuesta. Las aristas código-paper puntúan más alto. Cada resultado incluye un por qué en lenguaje natural.

**Preguntas sugeridas** — 4-5 preguntas que el grafo está en posición única de responder

**El «por qué»** — docstrings, comentarios inline (`# NOTE:`, `# IMPORTANT:`, `# HACK:`, `# WHY:`), y justificaciones de diseño extraídas como nodos `rationale_for`.

**Puntuaciones de confianza** — cada arista INFERRED tiene un `confidence_score` (0,0-1,0).

**Benchmark de tokens** — impreso automáticamente tras cada ejecución. En un corpus mixto: **71,5 veces** menos tokens por consulta vs archivos sin procesar.

**Sincronización automática** (`--watch`) — actualiza el grafo automáticamente cuando cambia el código.

**Hooks de Git** (`KALI Memory hook install`) — instala hooks post-commit y post-checkout.

## Privacidad

KALI Memory envía contenido de archivos a la API del modelo de tu asistente IA para extracción semántica de documentos, papers e imágenes. Los archivos de código se procesan localmente mediante tree-sitter AST. Los archivos de video y audio se transcriben localmente con faster-whisper. Sin telemetría, sin seguimiento de uso.

## Stack técnico

NetworkX + Leiden (graspologic) + tree-sitter + vis.js. Extracción semántica via Claude, GPT-4 o el modelo de tu plataforma. Transcripción de video via faster-whisper + yt-dlp (opcional).

## Construido sobre KALI Memory — Penpax

[**Penpax**](https://safishamsi.github.io/penpax.ai) es la capa enterprise sobre KALI Memory. Donde KALI Memory convierte una carpeta de archivos en un grafo de conocimiento, Penpax aplica el mismo grafo a toda tu vida laboral — continuamente.

**Prueba gratuita próximamente.** [Unirse a la lista de espera →](https://safishamsi.github.io/penpax.ai)

## Historial de estrellas

[![Star History Chart](https://api.star-history.com/svg?repos=safishamsi/KALI Memory&type=Date)](https://star-history.com/#safishamsi/KALI Memory&Date)
