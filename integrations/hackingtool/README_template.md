<div align="center">

# HackingTool

**All-in-One Hacking Tool for Security Researchers & Pentesters**

[![License](https://img.shields.io/github/license/Z4nzu/hackingtool?style=flat-square)](LICENSE)
[![Python](https://img.shields.io/badge/Python-3.10+-3776AB?style=flat-square&logo=python&logoColor=white)](https://www.python.org/)
[![Version](https://img.shields.io/badge/version-2.0.0-brightgreen?style=flat-square)](#)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20Kali%20%7C%20Parrot%20%7C%20macOS-informational?style=flat-square)](#)
[![Stars](https://img.shields.io/github/stars/Z4nzu/hackingtool?style=flat-square)](https://github.com/Z4nzu/hackingtool/stargazers)
[![Forks](https://img.shields.io/github/forks/Z4nzu/hackingtool?style=flat-square)](https://github.com/Z4nzu/hackingtool/network/members)
[![Issues](https://img.shields.io/github/issues/Z4nzu/hackingtool?style=flat-square)](https://github.com/Z4nzu/hackingtool/issues)
[![Last Commit](https://img.shields.io/github/last-commit/Z4nzu/hackingtool?style=flat-square)](https://github.com/Z4nzu/hackingtool/commits/master)

</div>

---

## What's New in v2.0.0

- Python 3.10+ required — all Python 2 code removed
- OS-aware menus — Linux-only tools are hidden automatically on macOS
- Archived tools (Python 2, unmaintained) shown in a separate sub-menu
- All `os.chdir()` bugs fixed — tools install to `~/.hackingtool/tools/`
- No more `sudo git clone` — tools install to user home, no root needed
- 22 new modern tools added across 6 categories
- Rich terminal UI with shared theme — no more 32 different console instances
- Iterative menus — no more recursion stack overflow on deep navigation
- Docker image builds locally — no unverified external images
- `requirements.txt` cleaned — removed unused flask/boxes/lolcat/requests

---

## Menu

{{toc}}

---

## Tools

{{tools}}

---

## Contributing — Add a New Tool

Want a tool included? **Raise an Issue or open a PR** using the templates below.

### Issue (Tool Request)

> Title format: `[Tool Request] ToolName — Category`
> Example: `[Tool Request] Subfinder — Information Gathering`

Use the **Tool Request** issue template and fill in all required fields:
tool name, GitHub URL, category, supported OS, install command, and why it should be added.

### Pull Request

> Title format: `[New Tool] ToolName — Category`
> Example: `[New Tool] Subfinder — Information Gathering`

Use the **PR template** checklist. Key requirements:

1. Add your tool class to the correct `tools/*.py` file
2. Set `TITLE`, `DESCRIPTION`, `INSTALL_COMMANDS`, `RUN_COMMANDS`, `PROJECT_URL`
3. Set `SUPPORTED_OS = ["linux"]` or `["linux", "macos"]` appropriately
4. Add the instance to the `TOOLS` list in the collection class
5. Test install and run locally before submitting

Issues or PRs that don't follow the title format may be closed without review.

---

## Installation

### One-liner (recommended)

```bash
curl -sSL https://raw.githubusercontent.com/Z4nzu/hackingtool/master/install.sh | sudo bash
```

This handles everything — installs prerequisites, clones the repo, sets up a venv, and creates the `hackingtool` command.

### Manual install

```bash
git clone https://github.com/Z4nzu/hackingtool.git
cd hackingtool
sudo python3 install.py   # detects local source, copies instead of re-cloning
```

Then run:
```bash
hackingtool
```

## Docker

### Step 1 — Clone the repository

```bash
git clone https://github.com/Z4nzu/hackingtool.git
cd hackingtool
```

### Step 2 — Build the image

```bash
docker build -t hackingtool .
```

> First build takes a few minutes (Kali base + apt packages). Subsequent builds are fast thanks to BuildKit layer caching.

### Step 3 — Run

**Option A — Direct (no Compose):**
```bash
docker run -it --rm hackingtool
```

**Option B — With Docker Compose (recommended):**
```bash
# Start in background
docker compose up -d

# Open an interactive shell
docker exec -it hackingtool bash

# Then launch the tool inside the container
python3 hackingtool.py
```

**Option C — Dev mode (live source mount, changes reflected without rebuild):**
```bash
docker compose --profile dev up
docker exec -it hackingtool-dev bash
```

### Stopping

```bash
docker compose down        # stop and remove container
docker compose down -v     # also remove the tools data volume
```

## Requirements

- Python 3.10+
- Linux (Kali, Parrot, Ubuntu) or macOS
- Go 1.21+ (for nuclei, ffuf, amass, httpx, katana, dalfox)
- Ruby (for haiti)

```bash
pip install -r requirements.txt
```

---

## Star History

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=Z4nzu/hackingtool&type=Date&theme=dark" />
  <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=Z4nzu/hackingtool&type=Date" />
  <img alt="HackingTool Star History Chart" src="https://api.star-history.com/svg?repos=Z4nzu/hackingtool&type=Date" />
</picture>

---

## Social

[![Twitter](https://img.shields.io/twitter/url?color=%231DA1F2&label=follow&logo=twitter&logoColor=%231DA1F2&style=flat-square&url=https%3A%2F%2Ftwitter.com%2F_Zinzu07)](https://twitter.com/_Zinzu07)
[![GitHub](https://img.shields.io/badge/-GitHub-181717?style=flat-square&logo=github&link=https://github.com/Z4nzu/)](https://github.com/Z4nzu/)

> **Please don't use for illegal activity.**
> Thanks to all original authors of the tools included in hackingtool.

Your favourite tool is not listed? [Suggest it here](https://github.com/Z4nzu/hackingtool/issues/new?template=tool_request.md)
