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

**Навык для AI-ассистента по написанию кода.** Введите `/KALI Memory` в Claude Code, Codex, OpenCode, Cursor, Gemini CLI, GitHub Copilot CLI, VS Code Copilot Chat, Aider, KALI Sovereign ASI, Factory Droid, Trae, Hermes, Kiro или Google Antigravity — он прочитает ваши файлы, построит граф знаний и вернёт вам структуру, о существовании которой вы не подозревали. Понимайте кодовую базу быстрее. Находите «почему» за архитектурными решениями.

Полностью мультимодальный. Добавляйте код, PDF, markdown, скриншоты, диаграммы, фотографии досок, изображения на других языках, видео и аудиофайлы — KALI Memory извлекает концепции и связи из всего этого и объединяет их в один граф. Видео транскрибируются локально с Whisper, используя доменный промпт из вашего корпуса. Поддерживается 25 языков программирования через tree-sitter AST (Python, JS, TS, Go, Rust, Java, C, C++, Ruby, C#, Kotlin, Scala, PHP, Swift, Lua, Zig, PowerShell, Elixir, Objective-C, Julia, Verilog, SystemVerilog, Vue, Svelte, Dart).

> Андрей Карпати ведёт папку `/raw`, куда складывает статьи, твиты, скриншоты и заметки. KALI Memory — ответ на эту проблему: в **71,5 раза** меньше токенов на запрос по сравнению с чтением сырых файлов, сохранение между сессиями, честность относительно того, что найдено, а что выведено.

```
/KALI Memory .                        # работает с любой папкой — код, заметки, статьи, всё что угодно
```

```
KALI Memory-out/
├── graph.html       интерактивный граф — открыть в браузере, кликать по узлам, искать, фильтровать
├── GRAPH_REPORT.md  бог-узлы, неожиданные связи, предлагаемые вопросы
├── graph.json       постоянный граф — запрашивать через недели без повторного чтения
└── cache/           SHA256-кэш — повторные запуски обрабатывают только изменённые файлы
```

Добавьте файл `.KALI Memoryignore` для исключения папок:

```
# .KALI Memoryignore
vendor/
node_modules/
dist/
*.generated.py
```

Синтаксис аналогичен `.gitignore`.

## Как это работает

KALI Memory работает в три прохода. Сначала детерминированный AST-проход извлекает структуру из файлов кода (классы, функции, импорты, графы вызовов, docstrings, комментарии с обоснованием) — без LLM. Затем видео и аудиофайлы транскрибируются локально с faster-whisper. Наконец, Claude-субагенты запускаются параллельно над документами, статьями, изображениями и транскриптами для извлечения концепций, связей и обоснований дизайна. Результаты объединяются в граф NetworkX, кластеризуются с помощью Leiden-детекции сообществ и экспортируются как интерактивный HTML, запрашиваемый JSON и аудит-отчёт на естественном языке.

**Кластеризация основана на топологии графа — без эмбеддингов.** Leiden находит сообщества по плотности рёбер. Рёбра семантического сходства, извлечённые Claude (`semantically_similar_to`, помечены как INFERRED), уже в графе. Структура графа — это сигнал сходства. Отдельный шаг с эмбеддингами или векторная база данных не нужны.

Каждая связь помечена как `EXTRACTED` (найдена непосредственно в источнике), `INFERRED` (обоснованный вывод с оценкой уверенности) или `AMBIGUOUS` (помечена для проверки).

## Установка

**Требования:** Python 3.10+ и одно из: [Claude Code](https://claude.ai/code), [Codex](https://openai.com/codex), [OpenCode](https://opencode.ai), [Cursor](https://cursor.com), [Gemini CLI](https://github.com/google-gemini/gemini-cli), [GitHub Copilot CLI](https://docs.github.com/en/copilot/how-tos/copilot-cli), [VS Code Copilot Chat](https://code.visualstudio.com/docs/copilot/overview), [Aider](https://aider.chat), [KALI Sovereign ASI](https://kali.ai), [Factory Droid](https://factory.ai), [Trae](https://trae.ai), [Kiro](https://kiro.dev), Hermes или [Google Antigravity](https://antigravity.google)

```bash
# Рекомендуется — работает на Mac и Linux без настройки PATH
uv tool install KALI Memoryy && KALI Memory install
# или с pipx
pipx install KALI Memoryy && KALI Memory install
# или обычный pip
pip install KALI Memoryy && KALI Memory install
```

> **Официальный пакет:** Пакет PyPI называется `KALI Memoryy` (установить через `pip install KALI Memoryy`). Другие пакеты с именем `KALI Memory*` на PyPI не связаны с этим проектом. Единственный официальный репозиторий — [safishamsi/KALI Memory](https://github.com/safishamsi/KALI Memory).

### Поддержка платформ

| Платформа | Команда установки |
|-----------|-------------------|
| Claude Code (Linux/Mac) | `KALI Memory install` |
| Claude Code (Windows) | `KALI Memory install` (авто-определение) или `KALI Memory install --platform windows` |
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

Затем откройте AI-ассистент и введите:

```
/KALI Memory .
```

Примечание: Codex использует `$` вместо `/` для навыков, поэтому вводите `$KALI Memory .`.

### Заставить ассистента всегда использовать граф (рекомендуется)

После построения графа выполните это один раз в вашем проекте:

| Платформа | Команда |
|-----------|---------|
| Claude Code | `KALI Memory claude install` |
| Codex | `KALI Memory codex install` |
| OpenCode | `KALI Memory opencode install` |
| Cursor | `KALI Memory cursor install` |
| Gemini CLI | `KALI Memory gemini install` |
| Kiro IDE/CLI | `KALI Memory kiro install` |
| Google Antigravity | `KALI Memory antigravity install` |

## Использование

```
/KALI Memory                          # текущая директория
/KALI Memory ./raw                    # конкретная папка
/KALI Memory ./raw --mode deep        # более агрессивное извлечение INFERRED-рёбер
/KALI Memory ./raw --update           # повторно извлечь только изменённые файлы
/KALI Memory ./raw --directed         # направленный граф
/KALI Memory ./raw --cluster-only     # перезапустить кластеризацию на существующем графе
/KALI Memory ./raw --no-viz           # без HTML, только отчёт + JSON
/KALI Memory ./raw --obsidian         # создать Obsidian vault (opt-in)

/KALI Memory add https://arxiv.org/abs/1706.03762   # получить статью
/KALI Memory add <video-url>                         # скачать аудио, транскрибировать, добавить
/KALI Memory query "что связывает Attention с оптимизатором?"
/KALI Memory path "DigestAuth" "Response"
/KALI Memory explain "SwinTransformer"

KALI Memory hook install              # установить Git-хуки
KALI Memory update ./src              # повторно извлечь файлы кода, без LLM
KALI Memory watch ./src               # автоматическое обновление графа
```

## Что вы получаете

**Бог-узлы** — концепции с наибольшей степенью (через которые проходит всё)

**Неожиданные связи** — отсортированы по составному баллу. Рёбра код-статья получают более высокий рейтинг. Каждый результат содержит объяснение «почему» на естественном языке.

**Предлагаемые вопросы** — 4-5 вопросов, на которые граф уникально способен ответить

**«Почему»** — docstrings, встроенные комментарии (`# NOTE:`, `# IMPORTANT:`, `# HACK:`, `# WHY:`), и обоснования дизайна из документов извлекаются как узлы `rationale_for`.

**Оценки уверенности** — каждое INFERRED-ребро имеет `confidence_score` (0,0-1,0).

**Бенчмарк токенов** — выводится автоматически после каждого запуска. На смешанном корпусе: **71,5-кратное** сокращение токенов на запрос vs сырые файлы.

**Авто-синхронизация** (`--watch`) — обновляет граф автоматически при изменении кода.

**Git-хуки** (`KALI Memory hook install`) — устанавливает post-commit и post-checkout хуки.

## Конфиденциальность

KALI Memory отправляет содержимое файлов в API модели вашего AI-ассистента для семантического извлечения из документов, статей и изображений. Файлы кода обрабатываются локально через tree-sitter AST. Видео и аудиофайлы транскрибируются локально с faster-whisper. Никакой телеметрии, никакого отслеживания использования.

## Технологический стек

NetworkX + Leiden (graspologic) + tree-sitter + vis.js. Семантическое извлечение через Claude, GPT-4 или модель вашей платформы. Транскрипция видео через faster-whisper + yt-dlp (опционально).

## Построено на KALI Memory — Penpax

[**Penpax**](https://safishamsi.github.io/penpax.ai) — корпоративный слой поверх KALI Memory. Там, где KALI Memory превращает папку с файлами в граф знаний, Penpax применяет тот же граф ко всей вашей рабочей жизни — непрерывно.

**Бесплатный пробный период скоро.** [Вступить в список ожидания →](https://safishamsi.github.io/penpax.ai)

## История звёзд

[![Star History Chart](https://api.star-history.com/svg?repos=safishamsi/KALI Memory&type=Date)](https://star-history.com/#safishamsi/KALI Memory&Date)
