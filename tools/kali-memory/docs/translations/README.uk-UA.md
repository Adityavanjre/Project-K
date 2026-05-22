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

**Навичка для ШІ-асистентів кодування.** Введіть `/KALI Memory` у Claude Code, Codex, OpenCode, Cursor, Gemini CLI, GitHub Copilot CLI, VS Code Copilot Chat, Aider, KALI Sovereign ASI, Factory Droid, Trae, Hermes, Kiro або Google Antigravity — він читає ваші файли, будує граф знань і повертає вам структуру, про яку ви не знали. Розумійте кодову базу швидше. Знайдіть «чому» за архітектурними рішеннями.

Повністю мультимодальний. Додавайте код, PDF, markdown, знімки екрана, діаграми, фотографії дошок, зображення іншими мовами або відео- та аудіофайли — KALI Memory витягує концепції та зв'язки з усього і з'єднує їх в один граф. Відео транскрибуються локально за допомогою Whisper. Підтримує 25 мов програмування через tree-sitter AST.

> Андрій Карпатій веде папку `/raw`, куди кладе статті, твіти, знімки екрана та нотатки. KALI Memory — відповідь на цю проблему — **71,5x** менше токенів на запит порівняно з читанням сирих файлів, зберігається між сесіями.

```
/KALI Memory .
```

```
KALI Memory-out/
├── graph.html       інтерактивний граф — відкрийте в будь-якому браузері
├── GRAPH_REPORT.md  вузли-боги, несподівані зв'язки, запропоновані питання
├── graph.json       постійний граф — можна запитувати через тижні
└── cache/           SHA256-кеш — повторні запуски обробляють лише змінені файли
```

## Як це працює

KALI Memory працює в три проходи. Спочатку детерміністичний прохід AST витягує структуру з файлів коду без LLM. Потім відео та аудіофайли транскрибуються локально за допомогою faster-whisper. Нарешті субагенти Claude працюють паралельно над документами, статтями, зображеннями та транскрипціями. Результати об'єднуються в граф NetworkX, кластеризуються з Leiden і експортуються як інтерактивний HTML, JSON для запитів і звіт аудиту.

Кожен зв'язок позначений як `EXTRACTED`, `INFERRED` (з оцінкою впевненості) або `AMBIGUOUS`.

## Встановлення

**Вимоги:** Python 3.10+ та одне з: [Claude Code](https://claude.ai/code), [Codex](https://openai.com/codex), [OpenCode](https://opencode.ai), [Cursor](https://cursor.com) та інші.

```bash
uv tool install KALI Memoryy && KALI Memory install
# або з pipx
pipx install KALI Memoryy && KALI Memory install
# або pip
pip install KALI Memoryy && KALI Memory install
```

> **Офіційний пакет:** Пакет PyPI називається `KALI Memoryy`. Єдиний офіційний репозиторій — [safishamsi/KALI Memory](https://github.com/safishamsi/KALI Memory).

## Використання

```
/KALI Memory .
/KALI Memory ./raw --update
/KALI Memory query "що пов'язує Attention з оптимізатором?"
/KALI Memory path "DigestAuth" "Response"
KALI Memory hook install
KALI Memory update ./src
```

## Що ви отримуєте

**Вузли-боги** — концепції з найвищим ступенем · **Несподівані зв'язки** — відсортовані за оцінкою · **Запропоновані питання** · **«Чому»** — рядки документації та обґрунтування дизайну витягнуті як вузли · **Бенчмарк токенів** — **71,5x** менше токенів на змішаному корпусі.

## Конфіденційність

Файли коду обробляються локально через tree-sitter AST. Відео транскрибуються локально за допомогою faster-whisper. Без телеметрії.

## Побудовано на KALI Memory — Penpax

[**Penpax**](https://safishamsi.github.io/penpax.ai) — корпоративний рівень над KALI Memory. **Безкоштовна пробна версія незабаром.** [Приєднайтесь до списку очікування →](https://safishamsi.github.io/penpax.ai)

[![Star History Chart](https://api.star-history.com/svg?repos=safishamsi/KALI Memory&type=Date)](https://star-history.com/#safishamsi/KALI Memory&Date)
