<h1 align="center">Understand Anything</h1>
<p align="center">
  <strong>Convierte cualquier código fuente, base de conocimiento o documentación en un grafo de conocimiento interactivo que puedes explorar, buscar y consultar.</strong>
  <br />
  <em>Compatible con Claude Code, Codex, Cursor, Copilot, Gemini CLI y más.</em>
</p>

<p align="center">
  <a href="README.md">English</a> | <a href="README.zh-CN.md">简体中文</a> | <a href="README.zh-TW.md">繁體中文</a> | <a href="README.ja-JP.md">日本語</a> | <a href="README.ko-KR.md">한국어</a> | <a href="README.es-ES.md">Español</a> | <a href="README.tr-TR.md">Türkçe</a>
</p>

<p align="center">
 <a href="https://www.star-history.com/lum1104/understand-anything">
  <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/badge?repo=Lum1104/Understand-Anything&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/badge?repo=Lum1104/Understand-Anything" />
   <img alt="Star History Rank" src="https://api.star-history.com/badge?repo=Lum1104/Understand-Anything" />
  </picture>
 </a>
</p>

<p align="center">
  <a href="#-inicio-rápido"><img src="https://img.shields.io/badge/Inicio_Rápido-blue" alt="Quick Start" /></a>
  <a href="https://github.com/Lum1104/Understand-Anything/blob/main/LICENSE"><img src="https://img.shields.io/badge/Licencia-MIT-yellow" alt="License: MIT" /></a>
  <a href="https://docs.anthropic.com/en/docs/claude-code"><img src="https://img.shields.io/badge/Claude_Code-8A2BE2" alt="Claude Code" /></a>
  <a href="#codex"><img src="https://img.shields.io/badge/Codex-000000" alt="Codex" /></a>
  <a href="#vs-code--github-copilot"><img src="https://img.shields.io/badge/Copilot-24292e" alt="Copilot" /></a>
  <a href="#copilot-cli"><img src="https://img.shields.io/badge/Copilot_CLI-24292e" alt="Copilot CLI" /></a>
  <a href="#gemini-cli"><img src="https://img.shields.io/badge/Gemini_CLI-4285F4" alt="Gemini CLI" /></a>
  <a href="#opencode"><img src="https://img.shields.io/badge/OpenCode-38bdf8" alt="OpenCode" /></a>
  <a href="https://understand-anything.com"><img src="https://img.shields.io/badge/Página_Principal-d4a574" alt="Homepage" /></a>
  <a href="https://understand-anything.com/demo/"><img src="https://img.shields.io/badge/Demo_en_Vivo-00c853" alt="Live Demo" /></a>
  <a href="https://discord.gg/pydat66RY"><img src="https://img.shields.io/badge/discord-join-5865F2?style=flat-square&logo=discord&logoColor=white" alt="Discord" /></a>
</p>

<p align="center">
  <img src="assets/hero.png" alt="Understand Anything — Convierte cualquier código fuente en un grafo de conocimiento interactivo" width="800" />
</p>

---

> [!TIP]
> **¡Un enorme agradecimiento a la comunidad!** El apoyo a Understand-Anything ha sido increíble. Si esta herramienta te ahorra unos minutos de buscar entre la complejidad, eso es todo lo que quería. 🚀

**Acabas de unirte a un nuevo equipo. El código tiene 200,000 líneas. ¿Por dónde empiezas?**

Understand Anything es un [Claude Code Plugin](https://code.claude.com/docs/en/plugins-reference#plugins-reference) que analiza tu proyecto con un pipeline multi-agente, construye un grafo de conocimiento de cada archivo, función, clase y dependencia, y luego te ofrece un panel interactivo para explorarlo visualmente. Deja de leer código a ciegas. Empieza a ver el panorama completo.

> **Grafos que enseñan > grafos que solo presumen.**

---

## ✨ Características

> [!NOTE]
> **¿Quieres probarlo directamente?** Prueba la [demo en vivo](https://understand-anything.com/demo/) en nuestra [página principal](https://understand-anything.com/) — un panel interactivo donde puedes navegar, hacer zoom, buscar y explorar directamente en tu navegador.

### Explora el grafo estructural

Navega tu código como un grafo de conocimiento interactivo: cada archivo, función y clase es un nodo que puedes hacer clic, buscar y explorar. Selecciona cualquier nodo para ver resúmenes en lenguaje natural, relaciones y recorridos guiados.

<p align="center">
  <img src="assets/overview-structural.gif" alt="Grafo estructural — explora archivos, funciones, clases y sus relaciones" width="750" />
</p>

### Comprende la lógica de negocio

Cambia a la vista de dominio y observa cómo tu código se mapea a procesos de negocio reales: dominios, flujos y pasos representados como un grafo horizontal.

<p align="center">
  <img src="assets/overview-domain.gif" alt="Grafo de dominio — dominios de negocio, flujos y pasos de proceso" width="750" />
</p>

### Analiza bases de conocimiento

Apunta `/understand-knowledge` a un [wiki LLM con patrón Karpathy](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) y obtén un grafo de conocimiento dirigido por fuerzas con agrupación por comunidad. El parser determinístico extrae wikilinks y categorías de `index.md`, luego los agentes LLM descubren relaciones implícitas, extraen entidades y revelan afirmaciones, convirtiendo tu wiki en un grafo navegable de ideas interconectadas.

<table>
  <tr>
    <td width="50%" valign="top">
      <h3>🧭 Recorridos Guiados</h3>
      <p>Recorridos generados automáticamente de la arquitectura, ordenados por dependencia. Aprende el código en el orden correcto.</p>
    </td>
    <td width="50%" valign="top">
      <h3>🔍 Búsqueda Difusa y Semántica</h3>
      <p>Encuentra cualquier cosa por nombre o por significado. Busca "¿qué partes manejan la autenticación?" y obtén resultados relevantes en todo el grafo.</p>
    </td>
  </tr>
  <tr>
    <td width="50%" valign="top">
      <h3>📊 Análisis de Impacto de Cambios</h3>
      <p>Visualiza qué partes del sistema afectan tus cambios antes de hacer commit. Comprende los efectos en cascada a través del código.</p>
    </td>
    <td width="50%" valign="top">
      <h3>🎭 Interfaz Adaptativa por Persona</h3>
      <p>El panel ajusta su nivel de detalle según quién eres: desarrollador junior, PM o usuario avanzado.</p>
    </td>
  </tr>
  <tr>
    <td width="50%" valign="top">
      <h3>🏗️ Visualización por Capas</h3>
      <p>Agrupación automática por capa arquitectónica — API, Servicio, Datos, UI, Utilidades — con leyenda codificada por colores.</p>
    </td>
    <td width="50%" valign="top">
      <h3>📚 Conceptos del Lenguaje</h3>
      <p>12 patrones de programación (genéricos, closures, decoradores, etc.) explicados en contexto donde aparecen.</p>
    </td>
  </tr>
</table>

---

## 🚀 Inicio Rápido

### 1. Instala el plugin

```bash
/plugin marketplace add Lum1104/Understand-Anything
/plugin install understand-anything
```

### 2. Analiza tu código

```bash
/understand
```

Un pipeline multi-agente escanea tu proyecto, extrae cada archivo, función, clase y dependencia, y construye un grafo de conocimiento guardado en `.understand-anything/knowledge-graph.json`.

### 3. Explora el panel

```bash
/understand-dashboard
```

Se abre un panel web interactivo con tu código visualizado como un grafo, codificado por colores según la capa arquitectónica, con funciones de búsqueda y clic. Selecciona cualquier nodo para ver su código, relaciones y una explicación en lenguaje natural.

### 4. Sigue aprendiendo

```bash
# Pregunta cualquier cosa sobre el código
/understand-chat How does the payment flow work?

# Analiza el impacto de tus cambios actuales
/understand-diff

# Profundiza en un archivo o función específica
/understand-explain src/auth/login.ts

# Genera una guía de incorporación para nuevos miembros del equipo
/understand-onboard

# Extrae conocimiento de dominio de negocio (dominios, flujos, pasos)
/understand-domain

# Analiza un wiki LLM con patrón Karpathy
/understand-knowledge ~/path/to/wiki
```

---

## 🌐 Instalación Multiplataforma

Understand-Anything funciona en múltiples plataformas de codificación con IA.

### Claude Code (Nativo)

```bash
/plugin marketplace add Lum1104/Understand-Anything
/plugin install understand-anything
```

### Codex

Dile a Codex:
```
Fetch and follow instructions from https://raw.githubusercontent.com/Lum1104/Understand-Anything/refs/heads/main/.codex/INSTALL.md
```

### OpenCode

Dile a OpenCode:
```
Fetch and follow instructions from https://raw.githubusercontent.com/Lum1104/Understand-Anything/refs/heads/main/.opencode/INSTALL.md
```

### OpenClaw

Dile a OpenClaw:
```
Fetch and follow instructions from https://raw.githubusercontent.com/Lum1104/Understand-Anything/refs/heads/main/.openclaw/INSTALL.md
```

### Cursor

Cursor detecta automáticamente el plugin a través de `.cursor-plugin/plugin.json` cuando se clona este repositorio. No requiere instalación manual: simplemente clona y abre en Cursor.

### VS Code + GitHub Copilot

VS Code con GitHub Copilot (v1.108+) detecta automáticamente el plugin a través de `.copilot-plugin/plugin.json` cuando se clona este repositorio. No requiere instalación manual: simplemente clona y abre en VS Code.

Para habilidades personales (disponibles en todos los proyectos), dile a GitHub Copilot:
```text
Fetch and follow instructions from https://raw.githubusercontent.com/Lum1104/Understand-Anything/refs/heads/main/.vscode/INSTALL.md
```

### Copilot CLI

```bash
copilot plugin install Lum1104/Understand-Anything:understand-anything-plugin
```

### Antigravity

Dile a Antigravity:
```text
Fetch and follow instructions from https://raw.githubusercontent.com/Lum1104/Understand-Anything/refs/heads/main/.antigravity/INSTALL.md
```

### Gemini CLI

Dile a Gemini CLI:
```text
Fetch and follow instructions from https://raw.githubusercontent.com/Lum1104/Understand-Anything/refs/heads/main/.gemini/INSTALL.md
```

### Pi Agent

Dile a Pi Agent:
```text
Fetch and follow instructions from https://raw.githubusercontent.com/Lum1104/Understand-Anything/refs/heads/main/.pi/INSTALL.md
```

### Compatibilidad de Plataformas

| Plataforma | Estado | Método de Instalación |
|----------|--------|----------------|
| Claude Code | ✅ Nativo | Marketplace de plugins |
| Codex | ✅ Soportado | Instalación guiada por IA |
| OpenCode | ✅ Soportado | Instalación guiada por IA |
| OpenClaw | ✅ Soportado | Instalación guiada por IA |
| Cursor | ✅ Soportado | Detección automática |
| VS Code + GitHub Copilot | ✅ Soportado | Detección automática |
| Copilot CLI | ✅ Soportado | Instalación de plugin |
| Antigravity | ✅ Soportado | Instalación guiada por IA |
| Gemini CLI | ✅ Soportado | Instalación guiada por IA |
| Pi Agent | ✅ Soportado | Instalación guiada por IA |

---

## 📦 Comparte el Grafo con tu Equipo

El grafo es solo JSON — **confírmalo una vez y tus compañeros se saltan el pipeline**. Ideal para onboarding, revisiones de PR y flujos docs-as-code.

> **Ejemplo:** [GoogleCloudPlatform/microservices-demo (fork)](https://github.com/Lum1104/microservices-demo) — referencia políglota (Go / Java / Python / Node) con el grafo ya confirmado.

**Qué confirmar:** todo lo que hay en `.understand-anything/` *excepto* `intermediate/` y `diff-overlay.json` (archivos temporales locales).

```gitignore
.understand-anything/intermediate/
.understand-anything/diff-overlay.json
```

**Mantenlo al día:** activa `/understand --auto-update` — un hook post-commit parchea el grafo de forma incremental, así cada commit llega con su grafo correspondiente. O vuelve a ejecutar `/understand` manualmente antes de cada release.

**Grafos grandes (10 MB o más):** úsalos con **git-lfs**.

```bash
git lfs install
git lfs track ".understand-anything/*.json"
git add .gitattributes .understand-anything/
```

---

## 🔧 Bajo el Capó

### Pipeline Multi-Agente

El comando `/understand` orquesta 5 agentes especializados, y `/understand-domain` añade un sexto:

| Agente | Rol |
|-------|------|
| `project-scanner` | Descubre archivos, detecta lenguajes y frameworks |
| `file-analyzer` | Extrae funciones, clases e importaciones; produce nodos y aristas del grafo |
| `architecture-analyzer` | Identifica capas arquitectónicas |
| `tour-builder` | Genera recorridos de aprendizaje guiados |
| `graph-reviewer` | Valida la completitud y la integridad referencial del grafo (se ejecuta inline por defecto; usa `--review` para una revisión completa con LLM) |
| `domain-analyzer` | Extrae dominios de negocio, flujos y pasos de proceso (usado por `/understand-domain`) |
| `article-analyzer` | Extrae entidades, afirmaciones y relaciones implícitas de artículos wiki (usado por `/understand-knowledge`) |

Los analizadores de archivos se ejecutan en paralelo (hasta 5 concurrentes, 20-30 archivos por lote). Soporta actualizaciones incrementales: solo reanaliza los archivos que cambiaron desde la última ejecución.

---

## 🤝 Contribuir

¡Las contribuciones son bienvenidas! Así puedes empezar:

1. Haz fork del repositorio
2. Crea una rama de funcionalidad (`git checkout -b feature/my-feature`)
3. Ejecuta las pruebas (`pnpm --filter @understand-anything/core test`)
4. Haz commit de tus cambios y abre un pull request

Para cambios importantes, abre primero un issue para que podamos discutir el enfoque.

---

<p align="center">
  <strong>Deja de leer código a ciegas. Empieza a entenderlo todo.</strong>
</p>

## Historial de Stars

<a href="https://www.star-history.com/?repos=Lum1104%2FUnderstand-Anything&type=date&legend=top-left">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/image?repos=Lum1104/Understand-Anything&type=date&theme=dark&legend=top-left" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/image?repos=Lum1104/Understand-Anything&type=date&legend=top-left" />
   <img alt="Star History Chart" src="https://api.star-history.com/image?repos=Lum1104/Understand-Anything&type=date&legend=top-left" />
 </picture>
</a>

<p align="center">
  Licencia MIT &copy; <a href="https://github.com/Lum1104">Lum1104</a>
</p>
