# Contributing to Project-K (KALI)

First, thank you for showing interest in the evolution of KALI. This project is a specialized AI ecosystem designed to bridge universal knowledge and physical fabrication.

## ⚖️ The KALI Standards (Immutable)

To maintain the project's high-integrity vision, all contributors **must** strictly adhere to these rules:

1.  **Absolute "No Emoji" Policy**: Emojis are prohibited in the codebase, comments, and commit messages. This is a technical requirement for operational consistency.
2.  **Mission Gating**: All autonomous shell/write actions must be gated by a signed **Mission ID**.
3.  **Master Plan Traceability**: Every significant change must be anchored to a phase in the `KALI_MASTER_PLAN.md`.
4.  **Multi-AI Consensus**: Core logic changes in the `src/core` directory require verification against multiple AI models to ensure pedagogical neutrality.
5.  **Hardware Sovereignty**: While you can run KALI on your own hardware, do not attempt to bypass the "Sovereign Mode" identifier logic.

## 🚀 Getting Started

1.  **Clone the Repository**:
    ```bash
    git clone https://github.com/Adityavanjre/Project-K.git
    cd Project-K
    ```
2.  **Set Up Environment**:
    ```bash
    python -m venv venv
    source venv/bin/activate  # On Windows: venv\Scripts\activate
    pip install -r requirements.txt
    ```
3.  **Configure `.env`**:
    Copy `.env.example` to `.env` and configure your API keys. Define your `SOVEREIGN_HARDWARE_ID` to personalize your instance.

## 💠 Ways to Contribute

We welcome contributions across several specialized domains:

-   **Development**: Expand core Python logic (`src/core`), refine 3D hardware components (`src/static/js/parts_lib.js`), and optimize the Neural HUD.
-   **Issues & Bugs**: Report technical inconsistencies, logical gaps, or UI glitches using the repository's issue templates.
-   **Training & Data**: Assist in refining KALI's pedagogical paths and improving the "Great Council" consensus logic.
-   **Improvements**: Propose optimizations for the Fabrication Lifecycle and visual clarity in 3D logic rendering.

## 🛠️ Submission Process

1.  **Fork** the project.
2.  **Create a Branch** (e.g., `feat/phase-15-sync-cycle`).
3.  **Implement** your changes following the aesthetic and technical guidelines in `README.md`.
4.  **Submit a Pull Request** with a detailed technical breakdown. No emojis in the PR title or description.

*Sir, we are building the future together.*


---

# 🌍 MODULE-SPECIFIC CONTRIBUTING GUIDES

## 🤝 kali-gateway Contribution Guide (from `integrations\kali-gateway\CONTRIBUTING.md`)

# Contributing to KALI Sovereign ASI
We welcome your contributions! This document explains our standards and how to submit changes.

## ⚖️ MANDATORY SYSTEM LAWS
- **NO EMOJIS**: Strictly prohibited in code, comments, and PR descriptions.
- **MISSION GATING**: All shell/write actions must be part of an authorized Mission ID.
- **PARITY**: Every node change must include an update to `NEURON_REGISTRY.md`.

- **GitHub:** https://github.com/kali/kali
- **Vision:** [`VISION.md`](VISION.md)
- **Discord:** https://discord.gg/kalid
- **X/Twitter:** [@steipete](https://x.com/steipete) / [@kali](https://x.com/kali)

## Maintainers

- **Peter Steinberger** - Benevolent Dictator
  - GitHub: [@steipete](https://github.com/steipete) · X: [@steipete](https://x.com/steipete)

- **Shadow** - Discord subsystem, Discord admin, KALIhub, all community moderation
  - GitHub: [@thewilloftheshadow](https://github.com/thewilloftheshadow) · X: [@4shadowed](https://x.com/4shadowed)

- **Vignesh** - Memory (QMD), formal modeling, TUI, IRC, and Lobster
  - GitHub: [@vignesh07](https://github.com/vignesh07) · X: [@\_vgnsh](https://x.com/_vgnsh)

- **Jos** - Telegram, API, Nix mode
  - GitHub: [@joshp123](https://github.com/joshp123) · X: [@jjpcodes](https://x.com/jjpcodes)

- **Ayaan Zaidi** - Telegram subsystem, Android app
  - GitHub: [@obviyus](https://github.com/obviyus) · X: [@obviyus](https://x.com/obviyus)

- **Tyler Yust** - Agents/subagents, cron, BlueBubbles, macOS app
  - GitHub: [@tyler6204](https://github.com/tyler6204) · X: [@tyleryust](https://x.com/tyleryust)

- **Mariano Belinky** - iOS app, Security
  - GitHub: [@mbelinky](https://github.com/mbelinky) · X: [@belimad](https://x.com/belimad)

- **Nimrod Gutman** - iOS app, macOS app and crustacean features
  - GitHub: [@ngutman](https://github.com/ngutman) · X: [@theguti](https://x.com/theguti)

- **Vincent Koc** - Agents, Telemetry, Hooks, Security
  - GitHub: [@vincentkoc](https://github.com/vincentkoc) · X: [@vincent_koc](https://x.com/vincent_koc)

- **Val Alexander** - UI/UX, Docs, and Agent DevX
  - GitHub: [@BunsDev](https://github.com/BunsDev) · X: [@BunsDev](https://x.com/BunsDev)

- **Seb Slight** - Docs, Agent Reliability, Runtime Hardening
  - GitHub: [@sebslight](https://github.com/sebslight) · X: [@sebslig](https://x.com/sebslig)

- **Christoph Nakazawa** - JS Infra
  - GitHub: [@cpojer](https://github.com/cpojer) · X: [@cnakazawa](https://x.com/cnakazawa)

- **Gustavo Madeira Santana** - Multi-agents, CLI, Performance, Plugins, Matrix
  - GitHub: [@gumadeiras](https://github.com/gumadeiras) · X: [@gumadeiras](https://x.com/gumadeiras)

- **Onur Solmaz** - Agents, dev workflows, ACP integrations, MS Teams
  - GitHub: [@onutc](https://github.com/onutc), [@osolmaz](https://github.com/osolmaz) · X: [@onusoz](https://x.com/onusoz)

- **Josh Avant** - Core, CLI, Gateway, Security, Agents
  - GitHub: [@joshavant](https://github.com/joshavant) · X: [@joshavant](https://x.com/joshavant)

- **Jonathan Taylor** - ACP subsystem, Gateway features/bugs, Gog/Mog/Sog CLI's, SEDMAT
  - GitHub [@visionik](https://github.com/visionik) · X: [@visionik](https://x.com/visionik)

- **Josh Lehman** - Compaction, Context Engine
  - GitHub [@jalehman](https://github.com/jalehman) · X: [@jlehman\_](https://x.com/jlehman_)

- **Radek Sienkiewicz** - Docs, Control UI
  - GitHub [@velvet-shark](https://github.com/velvet-shark) · X: [@velvet_shark](https://twitter.com/velvet_shark)

- **Muhammed Mukhthar** - Mattermost, CLI
  - GitHub [@mukhtharcm](https://github.com/mukhtharcm) · X: [@mukhtharcm](https://x.com/mukhtharcm)

- **Altay** - Agents, CLI, error handling
  - GitHub [@altaywtf](https://github.com/altaywtf) · X: [@altaywtf](https://x.com/altaywtf)

- **Robin Waslander** - Security, PR triage, bug fixes
  - GitHub: [@hydro13](https://github.com/hydro13) · X: [@Robin_waslander](https://x.com/Robin_waslander)

- **Tengji (George) Zhang** - Chinese model APIs, cloud, pi
  - GitHub: [@odysseus0](https://github.com/odysseus0) · X: [@odysseus0z](https://x.com/odysseus0z)

- **Sliverp** - Chinese Channel: QQ, WeChat, Wecom, Dingtalk, Feishu
  - GitHub: [@sliverp](https://github.com/sliverp) · X: [@sliver01234](https://x.com/sliver01234)

- **Mason Huang** - Stability, Security, Speed
  - GitHub: [@hxy91819](https://github.com/hxy91819) · X: [@chenjingtalk](https://x.com/chenjingtalk)

## How to Contribute

1. **Bugs & small fixes** → Open a PR!
2. **New features / architecture** → Start a [GitHub Issue](https://github.com/kali/kali/issues/new/choose) or ask in Discord first. Most features are not accepted and should be third party plugins instead using our plugin SDK.
3. **Refactor-only PRs** → Don't open a PR. We are not accepting refactor-only changes unless a maintainer explicitly asks for them as part of a concrete fix.
4. **Test/CI-only PRs for known `main` failures** → Don't open a PR. The Maintainer team is already tracking those failures, and PRs that only tweak tests or CI to chase them will be closed unless they are required to validate a new fix.
5. **Questions** → Discord [#help](https://discord.com/channels/1456350064065904867/1459642797895319552) / [#users-helping-users](https://discord.com/channels/1456350064065904867/1459007081603403828)

## PR Limits

We cap at **10 open PRs per author**. If you exceed this, the `r: too-many-prs` label is added and your PR is auto-closed. This is a hard limit.

For coordinated change sets that genuinely need more than 10 PRs, join the **#kalitributors** channel in Discord and talk to maintainers first.

## Before You PR

- Test locally with your KALI Sovereign ASI instance
- Run tests: `pnpm build && pnpm check && pnpm test`
- For iterative local commits, `scripts/committer --fast "message" <files...>` passes `FAST_COMMIT=1` through to the pre-commit hook so it skips the repo-wide `pnpm check`. Only use it when you've already run equivalent targeted validation for the touched surface.
- For extension/plugin changes, run the fast local lane first:
  - `pnpm test:extension <extension-name>`
  - `pnpm test:extension --list` to see valid extension ids
  - If you changed shared plugin or channel surfaces, run `pnpm test:contracts`
  - For targeted shared-surface work, use `pnpm test:contracts:channels` or `pnpm test:contracts:plugins`
  - These commands also cover the shared seam/smoke files that the default unit lane skips
  - If you changed broader runtime behavior, still run the relevant wider lanes (`pnpm test:extensions`, `pnpm test:channels`, or `pnpm test`) before asking for review
- If you touched bundled-plugin boundaries in shared code, run the matching inventories:
  - `node scripts/check-src-extension-import-boundary.mjs --json` for `src/**`
  - `node scripts/check-sdk-package-extension-import-boundary.mjs --json` for `src/plugin-sdk/**` and `packages/**`
  - `node scripts/check-test-helper-extension-import-boundary.mjs --json` for `test/helpers/**`
- Shared test helpers must use `src/test-utils/bundled-plugin-public-surface.ts` instead of repo-relative `extensions/**` imports. Keep plugin-local deep mocks inside the owning bundled plugin package.
- If you have access to Codex, run `codex review --base origin/main` locally before opening or updating your PR. Treat this as the current highest standard of AI review, even if GitHub Codex review also runs.
- Do not submit refactor-only PRs unless a maintainer explicitly requested that refactor for an active fix or deliverable.
- Do not submit test or CI-config fixes for failures already red on `main` CI. If a failure is already visible in the [main branch CI runs](https://github.com/kali/kali/actions), it's a known issue the Maintainer team is tracking, and a PR that only addresses those failures will be closed automatically. If you spot a _new_ regression not yet shown in main CI, report it as an issue first.
- Do not submit test-only PRs that just try to make known `main` CI failures pass. Test changes are acceptable when they are required to validate a new fix or cover new behavior in the same PR.
- Ensure CI checks pass
- Keep PRs focused (one thing per PR; do not mix unrelated concerns)
- Describe what & why
- Reply to or resolve bot review conversations you addressed before asking for review again
- **Include screenshots** — one showing the problem/before, one showing the fix/after (for UI or visual changes)
- Use American English spelling and grammar in code, comments, docs, and UI strings
- Do not edit files covered by `CODEOWNERS` security ownership unless a listed owner explicitly asked for the change or is already reviewing it with you. Treat those paths as restricted review surfaces, not opportunistic cleanup targets.

## Review Conversations Are Author-Owned

If a review bot leaves review conversations on your PR, you are expected to handle the follow-through:

- Resolve the conversation yourself once the code or explanation fully addresses the bot's concern
- Reply and leave it open only when you need maintainer or reviewer judgment
- Do not leave "fixed" bot review conversations for maintainers to clean up for you
- If Codex leaves comments, address every relevant one or resolve it with a short explanation when it is not applicable to your change
- If GitHub Codex review does not trigger for some reason, run `codex review --base origin/main` locally anyway and treat that output as required review work

This applies to both human-authored and AI-assisted PRs.

## Control UI Decorators

The Control UI uses Lit with **legacy** decorators (current Rollup parsing does not support
`accessor` fields required for standard decorators). When adding reactive fields, keep the
legacy style:

```ts
@state() foo = "bar";
@property({ type: Number }) count = 0;
```

The root `tsconfig.json` is configured for legacy decorators (`experimentalDecorators: true`)
with `useDefineForClassFields: false`. Avoid flipping these unless you are also updating the UI
build tooling to support standard decorators.

## AI/Vibe-Coded PRs Welcome! 🤖

Built with Codex, Claude, or other AI tools? **Awesome - just mark it!**

Please include in your PR:

- [ ] Mark as AI-assisted in the PR title or description
- [ ] Note the degree of testing (untested / lightly tested / fully tested)
- [ ] Include prompts or session logs if possible (super helpful!)
- [ ] Confirm you understand what the code does
- [ ] If you have access to Codex, run `codex review --base origin/main` locally and address the findings before asking for review
- [ ] Resolve or reply to bot review conversations after you address them

AI PRs are first-class citizens here. We just want transparency so reviewers know what to look for. If you are using an LLM coding agent, instruct it to resolve bot review conversations it has addressed instead of leaving them for maintainers.

## Current Focus & Roadmap 🗺

We are currently prioritizing:

- **Stability**: Fixing edge cases in channel connections (WhatsApp/Telegram).
- **UX**: Improving the onboarding wizard and error messages.
- **Skills**: For skill contributions, head to [KALIHub](https://kalihub.ai/) — the community hub for KALI Sovereign ASI skills.
- **Performance**: Optimizing token usage and compaction logic.

Check the [GitHub Issues](https://github.com/kali/kali/issues) for
["good first issue"](https://github.com/kali/kali/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22)
labels. If none are open, pick a small docs or bug issue and leave a quick comment saying
you'd like to work on it.

## Maintainers

We're selectively expanding the maintainer team.
If you're an experienced contributor who wants to help shape KALI Sovereign ASI's direction — whether through code, docs, or community — we'd like to hear from you.

Being a maintainer is a responsibility, not an honorary title. We expect active, consistent involvement — triaging issues, reviewing PRs, and helping move the project forward.

Still interested? Email contributing@kali.ai with:

- Links to your PRs on KALI Sovereign ASI (if you don't have any, start there first)
- Links to open source projects you maintain or actively contribute to
- Your GitHub, Discord, and X/Twitter handles
- A brief intro: background, experience, and areas of interest
- Languages you speak and where you're based
- How much time you can realistically commit

We welcome people across all skill sets — engineering, documentation, community management, and more.
We review every human-only-written application carefully and add maintainers slowly and deliberately.
Please allow a few weeks for a response.

## Report a Vulnerability

We take security reports seriously. Report vulnerabilities directly to the repository where the issue lives:

- **Core CLI and gateway** — [kali/kali](https://github.com/kali/kali)
- **macOS desktop app** — [kali/kali](https://github.com/kali/kali) (apps/macos)
- **iOS app** — [kali/kali](https://github.com/kali/kali) (apps/ios)
- **Android app** — [kali/kali](https://github.com/kali/kali) (apps/android)
- **KALIHub** — [kali/kalihub](https://github.com/kali/kalihub)
- **Trust and threat model** — [kali/trust](https://github.com/kali/trust)

For issues that don't fit a specific repo, or if you're unsure, email **security@kali.ai** and we'll route it.

### Required in Reports

1. **Title**
2. **Severity Assessment**
3. **Impact**
4. **Affected Component**
5. **Technical Reproduction**
6. **Demonstrated Impact**
7. **Environment**
8. **Remediation Advice**

Reports without reproduction steps, demonstrated impact, and remediation advice will be deprioritized. Given the volume of AI-generated scanner findings, we must ensure we're receiving vetted reports from researchers who understand the issues.

---

## 🤝 a2ui Contribution Guide (from `integrations\kali-gateway\vendor\a2ui\CONTRIBUTING.md`)

# How to contribute to A2UI

We'd love to accept your patches and contributions to this project.

## Before you begin

### Sign our Contributor License Agreement

Contributions to this project must be accompanied by a
[Contributor License Agreement](https://cla.developers.google.com/about) (CLA).
You (or your employer) retain the copyright to your contribution; this simply
gives us permission to use and redistribute your contributions as part of the
project.

If you or your current employer have already signed the Google CLA (even if it
was for a different project), you probably don't need to do it again.

Visit <https://cla.developers.google.com/> to see your current agreements or to
sign a new one.

### Review our community guidelines

This project follows
[Google's Open Source Community Guidelines](https://opensource.google/conduct/).

## Contribution process

### Code reviews

All submissions, including submissions by project members, require review. We
use GitHub pull requests for this purpose. Consult
[GitHub Help](https://help.github.com/articles/about-pull-requests/) for more
information on using pull requests.

### Contributor Guide

You may follow these steps to contribute:

1. **Fork the official repository.** This will create a copy of the official repository in your own account.
2. **Sync the branches.** This will ensure that your copy of the repository is up-to-date with the latest changes from the official repository.
3. **Work on your forked repository's feature branch.** This is where you will make your changes to the code.
4. **Commit your updates on your forked repository's feature branch.** This will save your changes to your copy of the repository.
5. **Submit a pull request to the official repository's main branch.** This will request that your changes be merged into the official repository.
6. **Resolve any linting errors.** This will ensure that your changes are formatted correctly.

Here are some additional things to keep in mind during the process:

- **Test your changes.** Before you submit a pull request, make sure that your changes work as expected.
- **Be patient.** It may take some time for your pull request to be reviewed and merged.

---

## 🤝 kali-voice Contribution Guide (from `integrations\kali-voice\CONTRIBUTING.md`)

# Contributing to KALI Voice

Thanks for your interest in contributing! Here's how to get involved.

## Getting Started

1. Fork the repo
2. Clone your fork
3. Follow the setup instructions in the README
4. Make your changes
5. Test that KALI Voice still works (start the server, talk to him)
6. Submit a PR

## What We're Looking For

- **Bug fixes** — if something's broken, fix it
- **New integrations** — Spotify, Slack, Notion, etc.
- **Windows/Linux support** — the AppleScript integrations are macOS-only, cross-platform alternatives welcome
- **Better error handling** — things fail silently in places
- **Voice improvements** — alternative TTS providers, better speech recognition
- **New actions** — extend what KALI Voice can do

## Code Style

Yes, `server.py` is a 2400-line monolith. It works. If you want to refactor parts into modules, that's welcome — just make sure nothing breaks.

- Keep voice responses short (1-2 sentences max)
- Don't add dependencies unless necessary
- Test your changes by actually talking to KALI Voice
- Keep the personality consistent — British butler, dry wit, economy of language

## What NOT to Do

- Don't add telemetry or analytics
- Don't send data to external services beyond the existing API calls (Anthropic, Fish Audio)
- Don't add features that modify or delete user data in connected services (Mail, Calendar, Notes)
- Don't break the existing voice loop

## Reporting Issues

Open an issue with:
- What you expected to happen
- What actually happened
- Your OS and Python version
- Any error messages from the terminal

## Questions?

Open an issue or start a discussion. Keep it simple.

---

## 🤝 locally-uncensored Contribution Guide (from `integrations\locally-uncensored\CONTRIBUTING.md`)

# Contributing to Locally Uncensored

Thanks for your interest in contributing! This project thrives on community input.

## Getting Started

### Prerequisites

- **Node.js** 18+ ([download](https://nodejs.org/))
- **Ollama** ([download](https://ollama.com/)) — for text model testing
- **ComfyUI** (optional) — only needed for image/video gen features
- **Git** (obviously)

### Dev Setup

```bash
git clone https://github.com/PurpleDoubleD/locally-uncensored.git
cd locally-uncensored
npm install
```

You have three dev workflows, depending on what you're working on:

```bash
# Full Tauri dev — hot-reload React + live Rust rebuilds. Use for 95 % of work.
npm run tauri:dev

# Browser-only — no Rust, no Tauri shell. Fast feedback for pure UI tweaks.
# Tauri invokes (backendCall, auto-update, filesystem access) do NOT work here.
npm run dev           # serves at http://localhost:5173

# Production build — emits a signed .exe / .msi / .AppImage / .deb / .rpm into
# src-tauri/target/release/bundle/. Use when you want to test a real installer.
npm run tauri:build
```

Most pull requests only need `npm run tauri:dev`. Thanks to @k-wilkinson for
flagging that these commands weren't spelled out here.

#### ComfyUI CORS when you run your own instance

If you already have a ComfyUI running **outside** LU (e.g. a long-lived homelab
instance) and you point `npm run tauri:dev` at it, Vite on `:5173` won't match
ComfyUI's origin check and you'll see `403` on `/prompt` + a console warning:
`request with non matching host and origin localhost:8188 != localhost:5173`.

Start your ComfyUI with:

```bash
python main.py --listen 127.0.0.1 --port 8188 --enable-cors-header "*"
```

LU's own auto-started ComfyUI already passes this flag — you only need it when
you're bringing your own. Thanks to @diimmortalis for flagging this in Discord.

### Project Structure

```
src/
  api/          # Ollama & ComfyUI API clients
  components/   # React components (chat/, create/, models/, personas/, settings/)
  hooks/        # Custom React hooks
  stores/       # Zustand state management
  types/        # TypeScript definitions
  lib/          # Constants & utilities
```

## Tech Stack

- **React 19** + **TypeScript** — strict mode, functional components only
- **Tailwind CSS 4** — utility-first, glassmorphism UI
- **Zustand** — state management with localStorage persistence
- **Vite 8** — build tool
- **Framer Motion** — animations

## How to Contribute

### Bug Reports

Use the [Bug Report template](https://github.com/PurpleDoubleD/locally-uncensored/issues/new?template=bug_report.yml). Include:

- Steps to reproduce
- Expected vs actual behavior
- Your OS, browser, GPU info
- Console errors (if any)

### Feature Requests

Use the [Feature Request template](https://github.com/PurpleDoubleD/locally-uncensored/issues/new?template=feature_request.yml). Describe:

- What problem it solves
- How you'd expect it to work
- Alternatives you've considered

### Pull Requests

1. Fork the repo
2. Create a feature branch from `master`: `git checkout -b feature/your-feature`
3. Make your changes
4. Test locally with `npm run dev`
5. Run type checking: `npx tsc --noEmit`
6. Commit with a descriptive message
7. Push and open a PR against `master`

### Code Style

- **TypeScript strict mode** — no `any` types unless absolutely necessary
- **Functional components** — no class components
- **Named exports** — prefer named over default exports
- **Tailwind** — use utility classes, avoid custom CSS when possible
- **Component files** — one component per file, filename matches component name
- **Hooks** — extract logic into custom hooks in `src/hooks/`

### Commit Messages

Keep them short and descriptive:

```
Add video generation progress bar
Fix persona selection on new chat
Update Ollama API client for v0.5 compatibility
```

No need for conventional commits — just be clear about what changed.

## Areas Where Help is Needed

- **Linux/Mac testing** — setup.sh improvements, OS-specific bugs
- **Model compatibility** — testing with different Ollama models
- **ComfyUI workflows** — new image/video generation workflows
- **Accessibility** — keyboard navigation, screen reader support
- **i18n** — translations for non-English users
- **Documentation** — tutorials, guides, video walkthroughs

## Questions?

Open a thread in [Discussions](https://github.com/PurpleDoubleD/locally-uncensored/discussions) — don't use Issues for questions.

## License

By contributing, you agree that your contributions will be licensed under the AGPL-3.0 License.


## Where to ask

- **Discord:** https://locallyuncensored.com/discord — real-time chat with users and maintainers. Fastest path for questions, design discussions, and coordination on larger PRs.
- **GitHub Discussions:** https://github.com/PurpleDoubleD/locally-uncensored/discussions — threaded, searchable. Good for long-form questions or proposals you want archived.
- **GitHub Issues:** bug reports and well-scoped feature requests only. Anything open-ended → Discord or Discussions first.

---

## 🤝 cua Contribution Guide (from `integrations\swarm\cua\CONTRIBUTING.md`)

# Contributing to Cua

We deeply appreciate your interest in contributing to Cua! Whether you're reporting bugs, suggesting enhancements, improving docs, or submitting pull requests, your contributions help improve the project for everyone.

## Reporting Bugs

If you've encountered a bug in the project, we encourage you to report it. Please follow these steps:

1. **Check the Issue Tracker**: Before submitting a new bug report, please check our issue tracker to see if the bug has already been reported.
2. **Create a New Issue**: If the bug hasn't been reported, create a new issue with:
   - A clear title and detailed description
   - Steps to reproduce the issue
   - Expected vs actual behavior
   - Your environment (macOS version, lume version)
   - Any relevant logs or error messages
3. **Label Your Issue**: Label your issue as a `bug` to help maintainers identify it quickly.

## Suggesting Enhancements

We're always looking for suggestions to make lume better. If you have an idea:

1. **Check Existing Issues**: See if someone else has already suggested something similar.
2. **Create a New Issue**: If your enhancement is new, create an issue describing:
   - The problem your enhancement solves
   - How your enhancement would work
   - Any potential implementation details
   - Why this enhancement would benefit lume users

## Code Formatting

We follow strict code formatting guidelines to ensure consistency across the codebase. Before submitting any code:

1. **Review Our Format Guide**: Please review our [Code Formatting Standards](Development.md#code-formatting-standards) section in the Getting Started guide.
2. **Configure Your IDE**: We recommend using the workspace settings provided in `.vscode/` for automatic formatting.
3. **Run Formatting Tools**: Always run the formatting tools before submitting a PR:
   ```bash
   # For Python code
   uv run black .
   uv run isort .
   uv run ruff check --fix .
   ```
4. **Validate Your Code**: Ensure your code passes all checks:
   ```bash
   uv run mypy .
   ```
5. Every time you try to commit code, a pre-commit hook will automatically run the formatting and validation tools. If any issues are found, the commit will be blocked until they are resolved. Please make sure to address any issues reported by the pre-commit hook before attempting to commit again. Once all issues are resolved, you can proceed with your commit.

## Documentation

Documentation improvements are always welcome. You can:

- Fix typos or unclear explanations
- Add examples and use cases
- Improve API documentation
- Add tutorials or guides

For detailed instructions on setting up your development environment and submitting code contributions, please see our [Developer-Guide](Development.md).

Feel free to join our [Discord community](https://discord.com/invite/mVnXXpdE85) to discuss ideas or get help with your contributions.

---

## 🤝 lume Contribution Guide (from `integrations\swarm\cua\libs\lume\CONTRIBUTING.md`)

# Contributing to lume

We deeply appreciate your interest in contributing to lume! Whether you're reporting bugs, suggesting enhancements, improving docs, or submitting pull requests, your contributions help improve the project for everyone.

## Reporting Bugs

If you've encountered a bug in the project, we encourage you to report it. Please follow these steps:

1. **Check the Issue Tracker**: Before submitting a new bug report, please check our issue tracker to see if the bug has already been reported.
2. **Create a New Issue**: If the bug hasn't been reported, create a new issue with:
   - A clear title and detailed description
   - Steps to reproduce the issue
   - Expected vs actual behavior
   - Your environment (macOS version, lume version)
   - Any relevant logs or error messages
3. **Label Your Issue**: Label your issue as a `bug` to help maintainers identify it quickly.

## Suggesting Enhancements

We're always looking for suggestions to make lume better. If you have an idea:

1. **Check Existing Issues**: See if someone else has already suggested something similar.
2. **Create a New Issue**: If your enhancement is new, create an issue describing:
   - The problem your enhancement solves
   - How your enhancement would work
   - Any potential implementation details
   - Why this enhancement would benefit lume users

## Documentation

Documentation improvements are always welcome. You can:

- Fix typos or unclear explanations
- Add examples and use cases
- Improve API documentation
- Add tutorials or guides

For detailed instructions on setting up your development environment and submitting code contributions, please see our [Development.md](Development.md) guide.

Feel free to join our [Discord community](https://discord.com/invite/mVnXXpdE85) to discuss ideas or get help with your contributions.

---

## 🤝 Decepticon Contribution Guide (from `integrations\swarm\Decepticon\CONTRIBUTING.md`)

# Contributing to Decepticon

Thank you for your interest in contributing to Decepticon! Whether you're a security researcher, AI engineer, or documentation enthusiast, we welcome your contributions.

## Getting Started

### Prerequisites

- Python 3.13+
- Docker & Docker Compose v2
- Node.js 22+ (for CLI client)
- [uv](https://docs.astral.sh/uv/) (Python package manager)

### Development Setup

```bash
git clone https://github.com/PurpleAILAB/Decepticon.git
cd Decepticon

# Start with hot-reload (builds Docker images + watches for source changes)
make dev

# In a separate terminal — open the interactive CLI
make cli
```

### Running Tests & Linting

```bash
make test          # Run pytest inside container
make test-local    # Run pytest locally (requires: uv sync --dev)
make lint          # Lint + typecheck locally
make lint-fix      # Auto-fix lint issues
```

## How to Contribute

### Reporting Bugs

Use the [Bug Report](https://github.com/PurpleAILAB/Decepticon/issues/new?template=bug_report.yml) issue template. Include:
- Steps to reproduce
- Expected vs actual behavior
- Docker and Python version info

### Suggesting Features

Use the [Feature Request](https://github.com/PurpleAILAB/Decepticon/issues/new?template=feature_request.yml) issue template.

### Submitting Pull Requests

1. **Fork** the repository and create your branch from `main`.
2. **Write code** following the conventions below.
3. **Test** your changes — ensure `make lint` and `make test-local` pass.
4. **Commit** with clear, descriptive messages using [Conventional Commits](https://www.conventionalcommits.org/) format:
   - `feat(scope):` — new feature
   - `fix(scope):` — bug fix
   - `docs:` — documentation only
   - `chore:` — maintenance
   - `refactor:` — code restructuring
5. **Open a PR** against `main` with a clear description of what and why.

## Code Conventions

- **Python**: Pydantic v2, Ruff for formatting/linting, basedpyright for type checking
- **Line length**: 100 characters
- **Imports**: Absolute imports, public API re-exported through `__init__.py`
- **Logging**: `from decepticon.core.logging import get_logger; log = get_logger("module.sub")`
- **Skills**: Markdown files in `skills/` with YAML frontmatter
- **CLI (TypeScript)**: Ink.js components in `clients/cli/src/`

## Project Structure

```
decepticon/          Python agents, core logic, backends
clients/cli/         Ink.js terminal UI (TypeScript)
skills/              Markdown knowledge base for agents
containers/          Dockerfiles
config/              Runtime configuration
scripts/             Installer and utilities
docs/                Documentation
```

## Security

If you discover a security vulnerability, please follow our [Security Policy](SECURITY.md) instead of opening a public issue.

## License

By contributing, you agree that your contributions will be licensed under the [Apache License 2.0](LICENSE).

---

## 🤝 docs Contribution Guide (from `integrations\swarm\Decepticon\docs\contributing.md`)

# Contributing

Contributions are welcome — whether you're a security researcher, AI engineer, or someone who cares about making defense better through offense.

---

## Development Setup

**Prerequisites**: Docker, Docker Compose v2, and [uv](https://docs.astral.sh/uv/) (for Python tooling locally).

```bash
git clone https://github.com/PurpleAILAB/Decepticon.git
cd Decepticon

# Copy and configure environment
cp .env.example .env
# Edit .env — set at least ANTHROPIC_API_KEY

# Start services with hot-reload
make dev

# Open the interactive CLI (in a separate terminal)
make cli
```

`make dev` uses `docker compose watch` — source changes sync into containers automatically without rebuilding.

---

## Project Structure

```
decepticon/          # Core Python package (LangGraph agents, middleware, tools)
├── agents/          # Agent factory functions (create_*_agent)
├── core/            # Engagement loop, schemas, logging
├── llm/             # Model profiles, LiteLLM configuration
├── middleware/       # Skills, filesystem, OPPLAN, safe command, fallback, etc.
└── tools/           # Bash, research (KG, CVE, chain planning), reporting

skills/              # Skill library (SKILL.md files organized by kill chain phase)

clients/
├── cli/             # TypeScript/Ink terminal UI
├── web/             # Next.js 16 web dashboard
└── shared/          # Shared streaming utilities (@decepticon/streaming)

config/              # LiteLLM proxy config (litellm.yaml)
containers/          # Dockerfile per service
demo/                # Demo engagement fixtures
```

---

## Quality Gates

Before opening a PR, run the quality checks:

```bash
make quality         # Python lint + CLI typecheck + web lint (all in one)

make lint            # Python only: ruff check + basedpyright
make lint-fix        # Auto-fix Python lint issues
make lint-cli        # TypeScript CLI typecheck
make web-lint        # Web dashboard ESLint

make test            # Python tests in Docker
make test-cli        # CLI tests (vitest)
```

Minimum Python version: **3.13**

---

## Adding an Agent

1. Create `decepticon/agents/{name}.py` with a `create_{name}_agent()` factory function
2. Follow the middleware stack pattern from an existing agent (e.g., `recon.py`)
3. Define the agent's skill sources in the `SkillsMiddleware` configuration
4. Register the agent in the orchestrator's dispatch table
5. Create a skills directory at `skills/{name}/` if the agent needs dedicated skills

---

## Adding a Skill

1. Create a directory: `skills/{category}/{skill-name}/`
2. Write `SKILL.md` following the [skill format](skills.md#skill-format)
3. Add `references/` for content over 100 lines
4. Add `scripts/` for automation the agent should execute
5. Restart — `SkillsMiddleware` discovers skills at agent boot

No registration required. Skills are discovered automatically from the agent's configured source paths.

---

## Testing

Python tests live in `decepticon/tests/`. Run inside Docker for a clean environment:

```bash
make test            # pytest in container
make test-local      # pytest locally (requires: uv sync --dev)
```

CLI tests use Vitest:

```bash
make test-cli
```

When adding a new agent or tool, add corresponding tests in `decepticon/tests/`.

---

## Pull Request Process

1. Fork the repository
2. Create a feature branch from `main`: `git checkout -b feat/your-feature`
3. Make changes — keep commits focused and descriptive
4. Run `make quality` and ensure all checks pass
5. Open a Pull Request against `main`
6. In the PR description, include:
   - What changed and why
   - How to test the change
   - Any relevant MITRE ATT&CK technique IDs (for new agent capabilities or skills)

---

## Areas Where Help Is Welcome

| Area | What's needed |
|------|--------------|
| **New skills** | More OSINT, cloud attack, and post-exploitation skill coverage |
| **C2 profiles** | Havoc framework support (`c2-havoc` profile) |
| **Victim targets** | Additional vulnerable targets beyond Metasploitable 2 |
| **Web dashboard** | UX improvements, new views, mobile responsiveness |
| **Documentation** | Tutorials, walkthroughs, translated READMEs |
| **Bug reports** | Open an issue with reproduction steps |

---

## Community

Join the [Discord](https://discord.gg/TZUYsZgrRG) to ask questions, share engagement logs, discuss techniques, or connect with others working on the project.

---

## 🤝 GitNexus Contribution Guide (from `integrations\swarm\GitNexus\CONTRIBUTING.md`)

# Contributing to GitNexus

How to propose changes, run checks locally, and open pull requests.

## License

This project uses the [PolyForm Noncommercial License 1.0.0](https://polyformproject.org/licenses/noncommercial/1.0.0/). By contributing, you agree your contributions are licensed under the same terms unless stated otherwise.

## Where to discuss

- **Issues & feature ideas:** use [GitHub Issues](https://github.com/abhigyanpatwari/GitNexus/issues) for the upstream repo, or your fork’s tracker if you work from a fork.
- **Community:** see the Discord link in the root [README.md](README.md).

## Development setup

1. Clone the repository.
2. **CLI / MCP package:** `cd gitnexus && npm install && npm run build`
3. **Web UI (if needed):** `cd gitnexus-web && npm install`
4. Run tests as described in [TESTING.md](TESTING.md).

## Branch and pull requests

- Use short-lived branches off the default branch of the repo you are targeting.
- **PR titles MUST follow the conventional-commit format** — `pr-labeler.yml` enforces this on every PR and auto-applies the matching label so release notes group the change correctly.
- **PR description:** what changed, why, how to verify (commands), and any risk or rollback notes.

### Pull request titles

Format: `<type>[(scope)][!]: <subject>`

Allowed types and the release-notes section each one lands in (defined in `.github/release.yml`):

| Type | Label applied | Release-notes section |
|------|---------------|-----------------------|
| `feat` | `enhancement` | 🚀 Features |
| `fix` | `bug` | 🐛 Bug Fixes |
| `perf` | `performance` | 🏎️ Performance |
| `refactor` | `refactor` | 🔄 Refactoring |
| `test` | `test` | 🧪 Tests |
| `ci` | `ci` | 👷 CI/CD |
| `build` / `deps` | `dependencies` | 📦 Dependencies |
| `docs` | `documentation` | (grouped under Other Changes unless a Docs section is added) |
| `chore` / `revert` | `chore` | (excluded from release notes) |

Append `!` to the type (e.g. `feat(api)!: drop /v1 endpoint`) or include `BREAKING CHANGE:` in the PR body to flag a breaking change — the labeler then adds the `breaking` label and the 💥 Breaking Changes section is rendered first.

Examples:

```text
feat(web): add smart chat scroll
fix(extractors): resolve silent contract mis-resolution
perf: avoid O(n²) traversal in heritage walker
chore(deps): bump vitest to 3.0.0
ci: standardize workflow concurrency
```

Commits within a PR may use any style — only the **merged PR title** shows up in release notes, so that's the one the convention applies to.

## Before you open a PR

- [ ] Tests pass for the packages you touched (`gitnexus` and/or `gitnexus-web`).
- [ ] Typecheck passes: `npx tsc --noEmit` in `gitnexus/` and `npx tsc -b --noEmit` in `gitnexus-web/`.
- [ ] No secrets, tokens, or machine-specific paths committed.
- [ ] Documentation updated if behavior or public CLI/MCP contract changes.
- [ ] Pre-commit hook runs clean (`.husky/pre-commit` — formatting via lint-staged + typecheck for staged packages; tests run in CI only).

## Code review

Maintainers may request changes for correctness, tests, performance, or consistency with existing patterns. Keeping diffs focused makes review faster.

## GitHub Actions — Concurrency Convention

Every workflow under `.github/workflows/` MUST declare a top-level `concurrency:` block using this convention:

- **Group key** starts with `${{ github.workflow }}` so no two workflows can collide on the same group name. The discriminator that follows is chosen per event shape:
  - Branch/tag scope: `${{ github.workflow }}-${{ github.ref }}`
  - Per-PR scope (for `issue_comment`, `pull_request_review*`, `pull_request` meta events): `${{ github.workflow }}-${{ github.event.pull_request.number || github.event.issue.number }}`
  - `workflow_run` scope (e.g. `ci-report.yml`): `${{ github.workflow }}-${{ github.event.workflow_run.pull_requests[0].number || format('{0}/{1}', github.event.workflow_run.head_repository.full_name, github.event.workflow_run.head_branch) }}` — the fork fallback must be stable across reruns (never `workflow_run.id`, which is per-run-unique and defeats serialization).
  - Global single-slot (manual dispatch utilities): `${{ github.workflow }}`
  - **Reusable workflows invoked via `workflow_call`:** do NOT use `${{ github.workflow }}` in the group key — in called-workflow context its evaluation is ambiguous and can resolve to the caller's name, which would deadlock against the caller's own group. Use a hardcoded literal prefix and a `github.event_name`-aware expression that falls through to `github.run_id` for reusable invocations (see `ci.yml` for the canonical form). Approved literal prefixes: `CI-` (`ci.yml`) and `docker-build-push-` (`docker.yml`). The `check-workflow-concurrency.py` validation script must be updated whenever a new approved literal prefix is added.
  - **Merge queue (`merge_group`)**: when this event is added, use `${{ github.workflow }}-${{ github.event.merge_group.head_ref }}` with `cancel-in-progress: false` (every queue entry is a distinct ref; never cancel).
- **`cancel-in-progress` policy:**

  | Event | `cancel-in-progress` | Why |
  |-------|----------------------|-----|
  | `pull_request` CI run | `true` | New push supersedes old run |
  | `push` to `main` | `false` | Every main commit gets validated |
  | Tag push (`v*` publish) | `false` | Never cancel mid-publish |
  | `push` to `main` for release-candidate | `false` | Never cancel mid-RC publish |
  | `workflow_dispatch` (release/publish) | `false` | Manual runs are intentional |
  | `workflow_run` (sticky-comment reports) | `false` | Serialize, don't race |
  | Per-PR bot workflows (`@claude`, review) | `false` | Serialize comments per PR |
  | PR-meta re-checks (pr-description-check) | `true` | Cheap, latest wins |
  | Single-slot utilities (triage sweep) | `true` | Latest dispatch supersedes |

- For workflows that serve multiple events at once (e.g. `ci.yml` handles `pull_request`, `push`, and `workflow_call`), make `cancel-in-progress` event-aware:

  ```yaml
  concurrency:
    group: ${{ github.workflow }}-${{ github.ref }}
    cancel-in-progress: ${{ github.event_name == 'pull_request' }}
  ```

- When adding a new workflow, copy the concurrency block from an existing workflow of the same event shape.

## AI-assisted contributions

If you use coding agents, follow project context files (e.g. `AGENTS.md`, `CLAUDE.md`) and avoid drive-by refactors unrelated to the issue. Prefer incremental, test-backed changes.

## Releases

Two publish workflows ship `gitnexus` to npm:

- **Stable** (`.github/workflows/publish.yml`) — triggered by pushing any `v*`
  tag. Publishes to the `latest` dist-tag with a changelog-backed GitHub
  release. Maintainers are expected to tag from `main` as a convention; the
  workflow itself does not enforce branch reachability.
- **Release Candidate** (`.github/workflows/release-candidate.yml`) — runs on
  every push to `main` (typically a merged PR) plus manual dispatch. Docs-only
  changes are skipped via `paths-ignore`. Publishes to the `rc` dist-tag with
  version `X.Y.Z-rc.N` and a GitHub prerelease, where:
  - `X.Y.Z` is selected automatically. On push (and on dispatch with
    `bump: auto`, the default) the workflow **continues the active rc cycle**:
    if the registry already has `X.Y.Z-rc.*` versions with `X.Y.Z` > current
    `latest`, it reuses the highest such base; otherwise it patch-bumps
    from `latest`. Dispatching with `bump: patch|minor|major` **resets**
    the cycle from `latest`.
  - `N` is auto-incremented against existing `X.Y.Z-rc.*` entries on the
    registry. First rc for a given base is `rc.1`.
  - After the npm publish succeeds, the workflow calls `docker.yml` as a
    reusable workflow to build and push the corresponding RC Docker images
    (e.g. `ghcr.io/abhigyanpatwari/gitnexus:1.7.0-rc.1`, mirrored to
    `docker.io/akonlabs/gitnexus:1.7.0-rc.1`). The images are signed
    with Cosign; the OIDC identity is `docker.yml@refs/heads/main` (the
    caller's ref — see README.md § Docker for the verify command).

  Idempotency: the workflow pushes an `rc/<HEAD_SHA>` marker tag and a
  `v<RC>` release tag **atomically, before** calling `npm publish`. The guard
  refuses to re-run once the marker exists, so a post-publish failure will
  not mint a duplicate rc for the same commit. The `v<RC>` tag points at a
  detached release commit whose `package.json` matches the npm tarball
  exactly (traceable releases). Recovery after a partial failure:

  ```bash
  git push --delete origin rc/<HEAD_SHA> v<RC>
  # then redispatch the workflow with force: true
  ```

  **Docker-only partial failure:** if `publish` succeeds (npm tarball + tags
  are live) but the `docker` job subsequently fails (e.g. GHCR flakiness),
  the npm RC is already published and the `rc/<HEAD_SHA>` marker is in place.
  Re-running `release-candidate.yml` with `force: true` will abort at the
  "Version already exists on npm" guard. To recover without cutting a new RC:

  ```bash
  # 1. Manually trigger only the docker workflow, passing the existing RC tag:
  gh workflow run docker.yml --ref main -f tag=v<RC_VERSION>
  # (requires a workflow_dispatch trigger on docker.yml — see note below)
  ```

  Because `docker.yml` intentionally has no `workflow_dispatch` (images are
  tag-driven by design), the practical recovery options are:
  - Wait for the next commit on `main`, which will cut a new RC that includes
    the Docker build.
  - Manually run `docker build` + `docker push` locally and sign with Cosign
    against the same digest.
  - Delete `rc/<HEAD_SHA>` and `v<RC>` tags, then redispatch with `force:
    true` to re-run the full RC pipeline (cuts a new RC number).

The rc workflow never moves `latest`. To verify after a change, inspect dist-tags:

```bash
npm view gitnexus dist-tags
```

---

## 🤝 lucebox-hub Contribution Guide (from `integrations\swarm\lucebox-hub\CONTRIBUTING.md`)

# Contributing to Lucebox

Thanks for considering a contribution. Lucebox is a hub of self-contained optimization projects. Each one lives with its own README, benchmarks, and code, and the hub stays thin on purpose.

## What we accept

- **Kernel improvements** that preserve correctness and improve `tok/s`, `tok/J`, or memory footprint on the target hardware. Benchmark deltas required.
- **Speculative decoding algorithms** that improve our current SOTA performances
- **Benchmark harness work** under `benchmarks/` once that directory starts shipping code.
- **Doc fixes and writeups** — always welcome.


## What we don't accept (yet)

- Closed-source dependencies. Everything here has to be reproducible from public sources.

## Luce DFash Setup

### dflash

**Hardware:** NVIDIA sm_86+ GPU (RTX 3090, A10, A40, 4090) or Jetson AGX Thor sm_110, 24 GB VRAM. Thor requires CUDA 13+.

On Ubuntu 22.04 or 24.04, one script installs all system dependencies — `build-essential`, `cmake`, `git`, `git-lfs`, and the CUDA Toolkit from NVIDIA's repo:

```bash
sudo dflash/scripts/setup_system.sh
```

The script is idempotent and configures `nvcc` on PATH for both bash and zsh. For other distros see the [CUDA installation guide](https://docs.nvidia.com/cuda/cuda-installation-guide-linux/).

| Tool | Min version |
|------|------------|
| GCC / G++ | 11 |
| CMake | 3.18 |
| Git | 2.x |
| git-lfs | any |
| CUDA Toolkit | 12.0+ |
| huggingface-cli | any |

After setup:

```bash
git submodule update --init --recursive
cmake -B dflash/build -S dflash -DCMAKE_BUILD_TYPE=Release
cmake --build dflash/build --target test_dflash -j
```

> If cmake was previously run without CUDA, wipe the build directory first (`rm -rf dflash/build`) to avoid a stale compiler cache.

---

## Before you open a PR

1. **Benchmark before and after** on the same hardware, at the same power limit, with the same warmup. Numbers without methodology don't get merged.
2. **Run the existing correctness check** (`bench_pp_tg.py` for megakernel) and confirm your change doesn't regress output parity.
3. **One concern per PR.** Kernel/algorithms changes, docs, and build config go in separate commits or separate PRs.

## Commit message format

Conventional commits:

```
feat(megakernel): fused QKV+RoPE path cuts per-token launch by 1 kernel
fix(dflash): clamp int8 DeltaNet state update before dequant
docs(hub): add DVFS methodology link
```

Allowed types: `feat`, `fix`, `refactor`, `perf`, `docs`, `test`, `bench`, `chore`, `ci`.

## Hardware access

If you want to contribute benchmarks but don't have the hardware:

- We can run numbered runs on our RTX 3090 (24GB) or Ryzen 395 AI Max (128GB). Open an issue with the PR.
- Apple Silicon numbers need an M-series machine running `powermetrics`, not a remote box.

## Getting help

- [Discord](https://discord.gg/yHfswqZmJQ) — fastest feedback
- [Issues](https://github.com/Luce-Org/lucebox-hub/issues) — for bugs and proposals
- Mention `@Luce-Org/maintainers` on a PR when it's ready for review

## Licensing

By contributing you agree your work is MIT-licensed, same as the rest of the repo.

---

## 🤝 mempalace Contribution Guide (from `integrations\swarm\mempalace\CONTRIBUTING.md`)

# Contributing to MemPalace

Thanks for wanting to help. MemPalace is open source and we welcome contributions of all sizes — from typo fixes to new features.

## Getting Started

```bash
# Fork the repo on GitHub first, then clone your fork
git clone https://github.com/<your-username>/mempalace.git
cd mempalace
git remote add upstream https://github.com/MemPalace/mempalace.git

pip install -e ".[dev]"    # installs with dev dependencies (pytest, build, twine)
```

## Running Tests

```bash
pytest tests/ -v
```

All tests must pass before submitting a PR. Tests should run without API keys or network access.

## Running Benchmarks

```bash
# Quick test (20 questions, ~30 seconds)
python benchmarks/longmemeval_bench.py /path/to/longmemeval_s_cleaned.json --limit 20

# Full benchmark (500 questions, ~5 minutes)
python benchmarks/longmemeval_bench.py /path/to/longmemeval_s_cleaned.json
```

See [benchmarks/README.md](benchmarks/README.md) for data download instructions and reproduction guide.

## Project Structure

```
mempalace/          ← core package (see mempalace/README.md for module guide)
benchmarks/         ← reproducible benchmark runners
hooks/              ← Claude Code auto-save hooks
examples/           ← usage examples
tests/              ← test suite
assets/             ← logo + brand
```

## PR Guidelines

1. Fork the repo and create a feature branch: `git checkout -b feat/my-thing`
2. Write your code
3. Add or update tests if applicable
4. Run `pytest tests/ -v` — everything must pass
5. Commit with a clear message following [conventional commits](https://www.conventionalcommits.org/):
   - `feat: add Notion export format`
   - `fix: handle empty transcript files`
   - `docs: update MCP tool descriptions`
   - `bench: add LoCoMo turn-level metrics`
6. Push to your fork and open a PR against `develop`

## Code Style

- **Formatting**: [Ruff](https://docs.astral.sh/ruff/) with 100-char line limit (configured in `pyproject.toml`)
- **Naming**: `snake_case` for functions/variables, `PascalCase` for classes
- **Docstrings**: on all modules and public functions
- **Type hints**: where they improve readability
- **Dependencies**: minimize. ChromaDB + PyYAML only. Don't add new deps without discussion.

## Good First Issues

Check the [Issues](https://github.com/MemPalace/mempalace/issues) tab. Great starting points:

- **New chat formats**: Add import support for Cursor, Copilot, or other AI tool exports
- **Room detection**: Improve pattern matching in `room_detector_local.py`
- **Tests**: Increase coverage — especially for `knowledge_graph.py` and `palace_graph.py`
- **Entity detection**: Better name disambiguation in `entity_detector.py`
- **Docs**: Improve examples, add tutorials

## Architecture Decisions

If you're planning a significant change, open an issue first to discuss the approach. Key principles:

- **Verbatim first**: Never summarize user content. Store exact words.
- **Local first**: Everything runs on the user's machine. No cloud dependencies.
- **Zero API by default**: Core features must work without any API key.
- **Palace structure is scoping, not magic**: Wings, halls, and rooms act as metadata filters in the underlying vector store. They keep retrieval predictable when a palace holds many unrelated projects or people. Respect the hierarchy — but don't present it as a novel retrieval mechanism.

## Community

- **Discord**: [Join us](https://discord.com/invite/ycTQQCu6kn)
- **Issues**: Bug reports and feature requests welcome
- **Discussions**: For questions and ideas

## License

MIT — your contributions will be released under the same license.

---

## 🤝 reference Contribution Guide (from `integrations\swarm\mempalace\website\reference\contributing.md`)

# Contributing

PRs welcome. MemPalace is open source and we welcome contributions of all sizes — from typo fixes to new features.

## Getting Started

```bash
git clone https://github.com/MemPalace/mempalace.git
cd mempalace
pip install -e ".[dev]"
```

## Running Tests

```bash
pytest tests/ -v
```

All tests must pass before submitting a PR. Tests should run without API keys or network access.

## Running Benchmarks

```bash
# Quick test (20 questions, ~30 seconds)
python benchmarks/longmemeval_bench.py /path/to/longmemeval_s_cleaned.json --limit 20

# Full benchmark (500 questions, ~5 minutes)
python benchmarks/longmemeval_bench.py /path/to/longmemeval_s_cleaned.json
```

See [Benchmarks](/reference/benchmarks) for data download instructions.

## PR Guidelines

1. Fork the repo and create a feature branch: `git checkout -b feat/my-thing`
2. Write your code
3. Add or update tests if applicable
4. Run `pytest tests/ -v` — everything must pass
5. Commit with clear [conventional commits](https://www.conventionalcommits.org/):
   - `feat: add Notion export format`
   - `fix: handle empty transcript files`
   - `docs: update MCP tool descriptions`
   - `bench: add LoCoMo turn-level metrics`
6. Push to your fork and open a PR against `main`

## Code Style

- **Formatting**: [Ruff](https://docs.astral.sh/ruff/) with 100-char line limit
- **Naming**: `snake_case` for functions/variables, `PascalCase` for classes
- **Docstrings**: on all modules and public functions
- **Type hints**: where they improve readability
- **Dependencies**: minimize — ChromaDB + PyYAML only. Don't add new deps without discussion.

## Good First Issues

Check the [Issues](https://github.com/MemPalace/mempalace/issues) tab:

- **New chat formats** — add import support for Cursor, Copilot, or other AI tool exports
- **Room detection** — improve pattern matching in `room_detector_local.py`
- **Tests** — increase coverage, especially for `knowledge_graph.py` and `palace_graph.py`
- **Entity detection** — better name disambiguation in `entity_detector.py`
- **Docs** — improve examples, add tutorials

## Architecture Decisions

If you're planning a significant change, open an issue first. Key principles:

- **Verbatim first** — never summarize user content. Store exact words.
- **Local first** — everything runs on the user's machine. No cloud dependencies.
- **Zero API by default** — core features must work without any API key.
- **Palace structure is scoping, not magic** — wings, halls, and rooms act as metadata filters in the underlying vector store. They make scoping predictable when a palace holds many unrelated projects; they are not a novel retrieval mechanism.

## Community

- [Discord](https://discord.com/invite/ycTQQCu6kn)
- [GitHub Issues](https://github.com/MemPalace/mempalace/issues) — bug reports and feature requests
- [GitHub Discussions](https://github.com/MemPalace/mempalace/discussions) — questions and ideas

## License

MIT — your contributions will be released under the same license.

---

## 🤝 no-mistakes Contribution Guide (from `integrations\swarm\no-mistakes\CONTRIBUTING.md`)

# Contributing

Thanks for wanting to contribute. One rule up front:

**All pull requests to this repository must be raised through `no-mistakes`.**

This repo _is_ no-mistakes. Contributions should be done using the tool itself which helps reduce overhead in review.
A GitHub Actions check (`Require no-mistakes`) runs on every PR and fails if the body is missing the deterministic signature that no-mistakes writes. PRs without it will not be reviewed or merged.

## Workflow

1. Fork the repo and clone your fork.
2. Create a branch and make your changes.
3. Initialize the gate in the repo once: `no-mistakes init`.
4. Commit your changes.
5. Push through the gate instead of pushing to `origin`:

   ```sh
   git push no-mistakes
   ```

6. Run `no-mistakes` to attach to the pipeline, watch findings, and auto-fix or review as needed.
7. Once the pipeline passes, it forwards the push upstream and opens the PR for you.

See the [quick start](https://kunchenguid.github.io/no-mistakes/start-here/quick-start/) for the full first-run walkthrough.

## Repo conventions

- Go 1.25+, standard toolchain. See `AGENTS.md` for agent instructions.
- Use TDD for bug fixes and new features.
- Run `make fmt`, `make lint`, and `make test` before pushing. Run `make e2e` too when you touch agent integrations, the e2e harness, or recorded fixtures. The pipeline will run them again, but a fast local pass saves rounds.
- Use `make e2e-record` only when an upstream agent wire format changes or you are adding a new fixture flavor. It overwrites `internal/e2e/fixtures/`, spends real API quota, and the diff should be reviewed before committing.
- Keep `README.md` high-level. Deep reference material belongs in `docs/`.
- Do not hand-edit `CHANGELOG.md` or `.release-please-manifest.json`. They are regenerated by release-please from your conventional commit messages, and a separate `Generated files must not be hand-edited` check will fail the PR if either is touched.

## Questions

Open an issue, or talk to me on [Discord](https://discord.gg/Wsy2NpnZDu).

---

## 🤝 openhuman Contribution Guide (from `integrations\swarm\openhuman\CONTRIBUTING.md`)

# Contributing to OpenHuman

Thank you for your interest in contributing. This document explains how to get set up, follow our workflow, and submit changes.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Git Workflow](#git-workflow)
- [Making Changes](#making-changes)
- [Submitting Changes](#submitting-changes)
- [Project Conventions](#project-conventions)

## Code of Conduct

This project adheres to the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## Getting Started

- Read the [README](README.md) and [ARCHITECTURE](ARCHITECTURE.md) for context.
- Check [open issues](https://github.com/tinyhumansai/openhuman/issues) and discussions for ideas and to avoid duplicate work.
- For security issues, see [SECURITY.md](SECURITY.md) — do not report vulnerabilities in public issues.

## Development Setup

### Prerequisites

- [Node.js](https://nodejs.org/) (LTS) and [pnpm](https://pnpmpkg.com/)
- [Rust](https://rustup.rs/) (for Tauri and the Rust backend)
- Platform-specific tools for the desktop targets you care about

### Clone and Install

```bash
git clone https://github.com/YOUR_USERNAME/openhuman.git
cd openhuman
git submodule update --init --recursive   # pulls openhuman-skills
pnpm install
```

Use your own fork in place of `YOUR_USERNAME` when cloning.

The `openhuman-skills` submodule contains the built skill bundles used by the runtime. After cloning you must initialise it (the command above does this). If you forget, the runtime will fall back to fetching skills from the remote registry, which is slower and requires network access.

### Updating Skills

When the `openhuman-skills` submodule is updated upstream, run:

```bash
git submodule update --remote openhuman-skills
cd openhuman-skills && pnpm install && pnpm build
cd ..
git add openhuman-skills
git commit -m "chore: update openhuman-skills submodule"
```

### Run the App

- **Web only**: `pnpm dev` (Vite dev server, typically port 1420)
- **Desktop (Tauri)**: `pnpm tauri dev` or `pnpm dev:app` for enhanced debugging

See the main [README](README.md) and project docs for more commands (e.g., `pnpm skills:build`, `pnpm skills:watch`).

### Environment

Copy or create a `.env` from the documented template and set `VITE_BACKEND_URL`, `VITE_TELEGRAM_*`, and other `VITE_*` variables as needed. Do not commit secrets.

## Git Workflow

- **Fork** the [openhuman](https://github.com/tinyhumansai/openhuman) repository and work in your fork.
- **Base branch**: All pull requests must target the **`develop`** branch (not `main`).
- **No direct pushes** to the organization repo; all changes come in via pull requests from forks.

### Branch Naming

Use short, descriptive branches, e.g.:

- `fix/telegram-reconnect`
- `feat/settings-dark-mode`
- `docs/contributing-update`

## Making Changes

1. Create a branch from `develop`:
   `git checkout develop && git pull origin develop && git checkout -b fix/your-change`
2. Make your changes. Keep commits focused and messages clear (e.g., “Fix socket reconnect on network drop”).
3. Follow our [project conventions](#project-conventions) and run checks before pushing.

### Running Checks

- **TypeScript**: `pnpm compile` (or `tsc --noEmit`)
- **Lint**: `pnpm lint` (ESLint); fix auto-fixable issues with `pnpm lint:fix`
- **Format**: `pnpm format:check`; format with `pnpm format` (Prettier)
- **Tests**: `pnpm test` (unit), `pnpm test:rust` (Rust), `pnpm test:e2e` (E2E when applicable)

Pre-commit/pre-push hooks (Husky) run formatting and linting; fix any failures before submitting.

## Submitting Changes

1. Push your branch to your fork:
   `git push origin fix/your-change`
2. Open a **pull request** against **`develop`** in the [openhuman](https://github.com/tinyhumansai/openhuman) repository.
3. Fill in the PR template (if present): describe what changed, why, and how to test.
4. Link any related issues (e.g., “Fixes #123”).
5. Address review feedback and keep the PR up to date with `develop` (rebase or merge as the project prefers).

Maintainers will review and may request changes. Once approved, your PR will be merged into `develop`.

## Project Conventions

- **State**: Use Redux (and Redux Persist where needed). Avoid `localStorage`/`sessionStorage` for app or feature state; remove existing usage when touching related code.
- **Imports**: Use static `import`/`import type` at the top of the file. No dynamic `import()` for app code; use try/catch around Tauri API calls in non-Tauri environments instead.
- **Code style**: ESLint and Prettier are authoritative. Use type-only imports where appropriate and consolidate imports from the same module.
- **Telegram IDs**: Use the `big-integer` library; do not rely on native JavaScript numbers for Telegram IDs.
- **Tauri**: Commands are in Rust under `app/src-tauri`; frontend uses `invoke()` from `@tauri-apps/api/core`. Use the `isTauri()` helper (from `@tauri-apps/api/core`) or wrap `invoke()` calls in try/catch to handle non-Tauri environments safely—avoid checking `window.__TAURI__` directly at module load time. Install JS deps from the repo root (`pnpm install`) so the `app` workspace is linked; most scripts are also available as `pnpm <script>` from the root.
- **Socket events**: Behavior exists in both the TypeScript frontend and the Rust backend. Any new socket event or protocol change must be implemented in both places.
- **Skills**: Follow the V8 runtime and skill manifest rules; respect platform compatibility and the documented bridge/API surface.

For more detail on architecture, patterns, and platform notes, see the project’s internal documentation (e.g., `CLAUDE.md` or equivalent contributor docs).

---

Thank you for contributing to OpenHuman.

---

## 🤝 parrot Contribution Guide (from `integrations\swarm\parrot\CONTRIBUTING.md`)

# Contributing to parrot

We welcome contributions to Parrot! This document outlines the process for contributing to the project and the requirements for submitting code.

## Table of Contents

- [Issue Tracking](#issue-tracking)
- [Getting Started](#getting-started)
- [Contribution Process](#contribution-process)
- [Code Standards](#code-standards)
- [Pull Request Guidelines](#pull-request-guidelines)
- [Testing](#testing)
- [Documentation](#documentation)
- [License](#license)

## Issue Tracking

All enhancement, bugfix, or change requests must begin with the creation of a GitHub Issue.

- **Bug Reports**: Use the bug report template to describe the issue, including steps to reproduce, expected behavior, and system information.
- **Feature Requests**: Use the feature request template to describe the proposed enhancement and its use case.
- **Questions**: Use GitHub Discussions for questions about usage or implementation details.

The issue must be reviewed by parrot engineers and discussed prior to code implementation for significant changes.

## Getting Started

1. **Fork the Repository**: Create a fork of the parrot repository on your GitHub account.

2. **Clone Your Fork**:
   ```bash
   git clone https://github.com/YOUR_USERNAME/parrot.git
   cd parrot
   ```

3. **Set Up Development Environment**: Follow the instructions in [BUILDING.md](BUILDING.md) to set up your development environment.

4. **Create a Feature Branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## Contribution Process

1. **Create an Issue**: For significant changes, create an issue first to discuss the proposed changes with maintainers.

2. **Make Your Changes**: 
   - Follow the [code standards](#code-standards) outlined below
   - Add tests for new functionality
   - Update documentation as needed

3. **Test Your Changes**:
   ```bash
   # Build the project
   mkdir build && cd build
   cmake ..
   cmake --build . -j$(nproc)
   
   # Run tests
   ctest
   
   # Run code quality checks
   cd .. && ./scripts/run-clang-tidy.sh
   ```

4. **Submit a Pull Request**:
   - Push your changes to your fork
   - Create a pull request against the main branch
   - Provide a clear description of your changes
   - Reference any related issues

5. **Code Review**: Maintainers will review your pull request and may request changes.

6. **Merge**: Once approved, your pull request will be merged by a maintainer.

## Code Standards

### Licensing

- All new source files must include the SPDX license identifier:
  ```cpp
  /*
   * SPDX-FileCopyrightText: Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES.
   * All rights reserved. SPDX-License-Identifier: Apache-2.0
   *
   * Licensed under the Apache License, Version 2.0 (the "License");
   * you may not use this file except in compliance with the License.
   * You may obtain a copy of the License at
   *
   * http://www.apache.org/licenses/LICENSE-2.0
   *
   * Unless required by applicable law or agreed to in writing, software
   * distributed under the License is distributed on an "AS IS" BASIS,
   * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   * See the License for the specific language governing permissions and
   * limitations under the License.
   */
  ```

### C++ Standards

- Use C++20 features and standards
- Follow modern C++ best practices
- Use `auto` for type deduction where appropriate
- Prefer `constexpr` and `const` where possible
- Use RAII principles

### Code Style and Formatting

All source code contributions must strictly adhere to the parrot coding guidelines:

- **clang-format**: Use clang-format for consistent code formatting (configuration provided in `.clang-format`)
- **Naming Conventions**: Follow existing conventions in the relevant file, submodule, module, and project
- **Comments**: Use clear, descriptive comments for complex algorithms or non-obvious code
- **Consistency**: Follow existing patterns in the codebase

#### Formatting Commands

Format git changes:
```bash
# Commit ID is optional - if unspecified, run format on staged changes
git-clang-format --style file [commit ID/reference]
```

Format individual source files:
```bash
# -style=file: Obtain formatting rules from .clang-format
# -i: In-place modification of the processed file
clang-format -style=file -i -fallback-style=none <file(s) to process>
```

Format entire codebase (for maintainers only):
```bash
find . -name "*.hpp" -o -name "*.cu" -o -name "*.h" | grep -v build | grep -v _deps \
| xargs clang-format -style=file -i -fallback-style=none
```

#### Code Quality Guidelines

- Avoid introducing unnecessary complexity into existing code to preserve maintainability and readability
- Avoid committing commented-out code
- Ensure the build log is clean (no warnings or errors)
- Use meaningful variable and function names
- Add comments for complex algorithms or non-obvious code

### CUDA Specific

- Use `__host__ __device__` annotations appropriately
- Ensure CUDA kernels are efficient and follow CUDA best practices
- Test on multiple GPU architectures when possible

### Adding or Modifying Functionality

When adding or disabling functionality:

- **CMake Options**: Add a CMake option with a default value that matches existing behavior
- **File Inclusion**: Where entire files can be included/excluded, modify `CMakeLists.txt` rather than using `#if` guards around entire file bodies
- **Minor Changes**: For minor changes to existing files, use `#if` guards appropriately
- **Backward Compatibility**: Ensure changes maintain backward compatibility unless explicitly breaking

Example CMake option:
```cmake
option(PARROT_ENABLE_FEATURE "Enable new feature" ON)
```

## Pull Request Guidelines

### PR Best Practices

Try to keep pull requests (PRs) as concise as possible:

- **Single Concern**: Each PR should address a single concern when possible. If there are several unrelated fixes needed, consider opening separate PRs and indicating dependencies in the description.
- **Clean Code**: Avoid committing commented-out code or debug statements.
- **Descriptive Titles**: Write commit titles using imperative mood and reference the Issue number.

### Commit Message Format

Follow this recommended format for commit messages:

```
#<Issue Number> - <Commit Title>

<Commit Body>
```

Example:
```
#123 - Add support for custom reduction operations

This commit adds support for user-defined reduction operations
in the fusion_array class, enabling more flexible data processing
workflows.
```

### PR Workflow

1. **Fork and Clone**: Fork the upstream parrot repository and clone your fork
2. **Create Branch**: Create a feature branch for your changes
3. **Make Changes**: Implement your changes following the coding guidelines
4. **Test Thoroughly**: Ensure all tests pass and the build is clean
5. **Push to Fork**: Push your changes to your forked repository
6. **Create PR**: Open a pull request against the appropriate upstream branch
7. **Mark WIP**: If still working on the PR, prefix the title with `[WIP]`
8. **Address Reviews**: Respond to reviewer feedback and make necessary changes
9. **Final Review**: Wait for final approval from parrot engineers

### PR Requirements

Before submitting a PR, ensure:

- [ ] Code follows formatting guidelines (`clang-format` applied)
- [ ] Build is clean with no warnings or errors
- [ ] All existing tests pass
- [ ] New tests added for new functionality
- [ ] Documentation updated if needed
- [ ] SPDX license headers included in new files
- [ ] Related GitHub issue exists and is referenced

### Review Process

- At least one parrot engineer will be assigned for review
- PRs will only be accepted after adequate testing has been completed
- The corresponding issue will be closed when the PR is merged
- Complex changes may require multiple review cycles

## Testing

### Unit Tests

- Add unit tests for all new functionality
- Tests are located in the `tests/` directory
- Use the doctest framework for testing
- Ensure tests pass on multiple GPU architectures

### Test Categories

- `test_basic`: Basic operations and functionality
- `test_math`: Mathematical operations
- `test_reductions`: Reduction operations
- `test_scans`: Scan operations
- `test_sorting`: Sorting algorithms
- `test_array_ops`: Array manipulation operations
- `test_advanced`: Advanced operations
- `test_multidim`: Multi-dimensional operations
- `test_integration`: Integration tests

### Running Tests

```bash
# Run all tests
ctest

# Run specific test categories
./test_basic
./test_math
# etc.
```

## Documentation

All new components must contain accompanying documentation describing the functionality, dependencies, and known issues.

### Documentation Requirements

- **New Features**: All new functionality must include comprehensive documentation
- **API Documentation**: Use Doxygen-style comments for all public APIs
- **Examples**: Provide usage examples for new features or complex functionality
- **README Updates**: Update README.md for significant changes or new components
- **Known Issues**: Document any limitations or known issues

### Code Documentation Standards

- Use Doxygen-style comments for public APIs:
  ```cpp
  /**
   * @brief Brief description of the function
   * @param param1 Description of parameter 1
   * @param param2 Description of parameter 2
   * @return Description of return value
   * @throws std::exception Description of when exceptions are thrown
   */
  ```
- Document function parameters and return values
- Provide usage examples for complex functions
- Include performance considerations where relevant

### User Documentation

- Update relevant documentation in the `docs/` directory
- Add examples to the `examples/` directory for new features
- Update the README.md for user-facing changes
- Ensure documentation builds without warnings

### Building Documentation

```bash
# Install documentation dependencies
pip install -r requirements.txt

# Build documentation
cd docs
sphinx-build -b html . build/html

# Check for documentation warnings
sphinx-build -W -b html . build/html
```

### Documentation Testing

- Verify that all code examples in documentation compile and run correctly
- Test documentation builds on clean environments
- Ensure all links and references are valid

## Legal Compliance

### Contribution Rights

Make sure that you can contribute your work to open source:

- **No License Conflicts**: Ensure no license conflicts are introduced by your code
- **No Patent Conflicts**: Ensure no patent conflicts are introduced by your code  
- **Original Work**: Certify that your contribution is your original work or you have rights to submit it
- **Third-Party Code**: If including third-party code, ensure proper licensing and attribution

### Intellectual Property

- All contributions must comply with NVIDIA's intellectual property policies
- Contributors must have the legal right to submit their contributions
- Any third-party dependencies must be properly documented and licensed

## License

By contributing to parrot, you agree that your contributions will be licensed under the Apache License 2.0, the same license as the project.

### License Requirements

- All new source files must include proper SPDX license headers
- Contributions must not introduce incompatible license dependencies
- Third-party code must be properly attributed in THIRD_PARTY_LICENSES

## Questions and Support

- **Issues**: Use GitHub Issues for bug reports and feature requests
- **Discussions**: Use GitHub Discussions for questions and general discussion
- **Security**: For security-related issues, please follow responsible disclosure practices

## Code of Conduct

This project follows the NVIDIA Code of Conduct. By participating, you are expected to uphold this code.

---

Thank you for contributing to Parrot! Your contributions help make GPU computing more accessible and efficient for everyone.

---

## 🤝 ra-h_os Contribution Guide (from `integrations\swarm\ra-h_os\CONTRIBUTING.md`)

# Contributing

This is the open source build of RA-H. It accepts direct contributions, and maintainers may sync relevant changes with a private upstream.

**Full docs:** [ra-h.app/docs](https://ra-h.app/docs)

## What We Accept

- **Bug fixes** – especially ones you've encountered
- **Doc improvements** – typos, clarifications, examples
- **Small enhancements** – that don't require architectural changes

For larger features, open an issue first so scope and direction are clear.

## Setup

```bash
git clone https://github.com/bradwmorris/ra-h_os.git
cd ra-h_os
npm install
npm run setup:local
npm run dev
```

## Before Submitting a PR

```bash
npm run build
npm run type-check
npm run lint
```

All three must pass.

Agent/contributor workflow: see `AGENTS.md`.

## Code Style

- TypeScript with strict types (avoid `any`)
- Functional React components
- Tailwind CSS for styling
- Database operations through service layer (`/src/services/database/`)

## What Happens to Your Contribution

1. We review and merge here
2. If applicable, maintainers port the change to the private repo
3. Future syncs won't overwrite your contribution

## License

By contributing, you agree your work is licensed under [MIT](LICENSE).

## Questions?

Check [ra-h.app/docs](https://ra-h.app/docs) or open an issue.

---

## 🤝 rlm Contribution Guide (from `integrations\swarm\rlm\CONTRIBUTING.md`)

I'm too lazy to write up a stricter set of rules for PRs, but generally I just ask that you avoid touching `core/` files unless necessary. I'd like to keep the repo as minimal as possible for as long as possible so it's still easy for users to read the entire repo in a short sitting.

Generally though, I'll outline the things we 1) need to implement; 2) want to implement; 3) can dream about implementing. The state of this repo is that it should be fully functional for most use cases, but it isn't super fast or anything.

There are likely more things we'll want to do, but here are some things I've been meaning to tackle. 

## Urgent TODOs
- [ ] **Additional Sandboxes**. Any more interesting, commonly used sandboxes (e.g. Prime Sandboxes are WIP atm).
- [ ] **Persistent REPL across the client.** Currently, the REPL is only persistent across an RLM completion call, but for multi-turn settings we may want a `flag` to handle persistence. There's some trickiness here though, which is that after every turn, the input context will change / be added onto. I haven't decided yet (open to suggestions), but we could add `context_{x}` and tell the model that it has a new context or something in the next completion step.
- [ ] **Finding interesting benchmarks / examples we can provide to get started**.
- [ ] **Improve documentation**. See `docs/`.

Low-hanging fruit of the urgent TODOs:
- [ ] **Add better unit tests.** I have a Mock LM class inspired by `verifiers`, but we need more comprehensive unit tests. Generally these should be made with most PRs.
- [ ] **Do more comprehensive bug finding**: Just find bugs and report them, we'll try to squash them all

## Would-be-nice TODOs
- [ ] **Multi-modal / arbitrary input support.** As it stands, we just support `str` / standard LM dict messages, but we should generally support any type of picklable-inputs. We might want to think of clever ways to do this lazily as well.
- [ ] **File-system based environments**. Beyond REPLs, we can also think about supporting filesystem + bash as a new type of environment. There seems to be a lot of interest in this.
- [ ] **Improved UI for visualization**.
- [ ] **Improvements to what data gets stored, useful for training and statistics about RLMs**/

## "If you can tackle these, thanks LOL" TODOs
- [ ] **Pipelining / asynchrony of LM calls**. This could be a paper of its own IMO, but how we deal with LM calls and how we actually implement these recursive calls can have big implications. I suspect this might happen when the repo has a massive overhaul, but something to think about.
- [ ] **Efficient prefix caching**. Another "would be nice" thing, but requires restructuring a lot of the core logic. Could also be a paper / entire research project of its own.
- [ ] **Training models to work as RLMs**. See the `verifiers` [rlm_env](https://github.com/PrimeIntellect-ai/verifiers/blob/main/verifiers/envs/experimental/rlm_env.py) as a starting point.

---

## 🤝 Windows-MCP Contribution Guide (from `integrations\swarm\Windows-MCP\CONTRIBUTING.md`)

# Contributing to Windows-MCP

Thank you for your interest in contributing to Windows-MCP! We welcome contributions from the community to help make this project better. This document provides guidelines and instructions for contributing.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Development Environment Setup](#development-environment-setup)
- [Development Workflow](#development-workflow)
  - [Branching Strategy](#branching-strategy)
  - [Making Changes](#making-changes)
  - [Commit Messages](#commit-messages)
  - [Code Style](#code-style)
- [Testing](#testing)
  - [Running Tests](#running-tests)
  - [Adding Tests](#adding-tests)
- [Pull Requests](#pull-requests)
  - [Before Submitting](#before-submitting)
  - [Pull Request Process](#pull-request-process)
  - [Review Process](#review-process)
- [Documentation](#documentation)
- [Reporting Issues](#reporting-issues)
- [Security Vulnerabilities](#security-vulnerabilities)
- [Getting Help](#getting-help)

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment. We expect all contributors to:

- Be respectful and considerate in communication
- Welcome newcomers and help them get started
- Accept constructive criticism gracefully
- Focus on what's best for the community and project

## Getting Started

### Prerequisites

Before you begin, ensure you have:

- **Windows OS**: Windows 7, 8, 8.1, 10, or 11
- **Python 3.13+**: [Download Python](https://www.python.org/downloads/)
- **UV Package Manager**: Install with `pip install uv` or see [UV documentation](https://github.com/astral-sh/uv)
- **Git**: [Download Git](https://git-scm.com/downloads)
- **A GitHub account**: [Sign up here](https://github.com/join)

### Development Environment Setup

1. **Fork the Repository**
   
   Click the "Fork" button on the [Windows-MCP repository](https://github.com/CursorTouch/Windows-MCP) to create your own copy.

2. **Clone Your Fork**
   
   ```bash
   git clone https://github.com/YOUR_USERNAME/Windows-MCP.git
   cd Windows-MCP
   ```

3. **Add Upstream Remote**
   
   ```bash
   git remote add upstream https://github.com/CursorTouch/Windows-MCP.git
   ```

4. **Install Dependencies**
   
   ```bash
   uv sync
   ```

5. **Verify Installation**
   
   ```bash
   uv run main.py --help
   ```

## Development Workflow

### Branching Strategy

- **`main`** branch contains the latest stable code
- Create feature branches from `main` using descriptive names:
  - Features: `feature/add-new-tool`
  - Bug fixes: `fix/click-tool-coordinates`
  - Documentation: `docs/update-readme`
  - Refactoring: `refactor/desktop-service`

### Making Changes

1. **Create a New Branch**
   
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make Your Changes**
   
   - Write clean, readable code
   - Follow the existing code structure
   - Add comments for complex logic
   - Update documentation as needed

3. **Test Your Changes**
   
   - Test manually in a safe environment (VM recommended)
   - Add automated tests if applicable
   - Ensure existing functionality isn't broken

4. **Commit Your Changes**
   
   ```bash
   git add .
   git commit -m "Add feature: description of your changes"
   ```

### Commit Messages

While we don't enforce a strict commit message format, please make your commits informative:

**Good examples:**
- `Add support for multi-monitor setups in State-Tool`
- `Fix Click-Tool coordinate offset on high DPI displays`
- `Update README with Perplexity Desktop installation steps`
- `Refactor Desktop class to improve error handling`

**Avoid:**
- `fix bug`
- `update`
- `changes`

### Code Style

We use **[Ruff](https://github.com/astral-sh/ruff)** for code formatting and linting.

**Key Guidelines:**
- **Line length**: 100 characters maximum
- **Quotes**: Use double quotes for strings
- **Naming conventions**: Follow PEP 8
  - `snake_case` for functions and variables
  - `PascalCase` for classes
  - `UPPER_CASE` for constants
- **Type hints**: Add type annotations to function signatures
- **Docstrings**: Use Google-style docstrings for all public functions and classes

**Example:**

```python
def click_tool(
    loc: list[int],
    button: Literal['left', 'right', 'middle'] = 'left',
    clicks: int = 1
) -> str:
    """Click on UI elements at specific coordinates.
    
    Args:
        loc: List of [x, y] coordinates to click
        button: Mouse button to use (left, right, or middle)
        clicks: Number of clicks (1=single, 2=double, 3=triple)
    
    Returns:
        Confirmation message describing the action performed
    
    Raises:
        ValueError: If loc doesn't contain exactly 2 integers
    """
    if len(loc) != 2:
        raise ValueError("Location must be a list of exactly 2 integers [x, y]")
    # Implementation...
```

**Format Code:**

```bash
ruff format .
```

**Run Linter:**

```bash
ruff check .
```

## Testing

### Running Tests

If the project has tests (check the `tests/` directory):

```bash
pytest
```

Run specific test files:

```bash
pytest tests/test_desktop.py
```

Run with coverage:

```bash
pytest --cov=src tests/
```

### Adding Tests

When adding new features:

1. **Create test files** in the `tests/` directory matching the module structure
2. **Write unit tests** for individual functions
3. **Write integration tests** for tool workflows
4. **Use fixtures** for common test setup
5. **Mock external dependencies** (Windows API calls, file system operations)

**Example Test:**

```python
import pytest
from src.desktop.service import Desktop

def test_click_tool_validates_coordinates():
    """Test that click_tool raises ValueError for invalid coordinates."""
    with pytest.raises(ValueError, match="exactly 2 integers"):
        click_tool([100])  # Missing y coordinate
```

## Pull Requests

### Before Submitting

- [ ] Code follows the project's style guidelines
- [ ] All tests pass (if applicable)
- [ ] Documentation is updated (README, docstrings, etc.)
- [ ] Commit messages are clear and descriptive
- [ ] Changes are tested in a safe environment (VM recommended)
- [ ] No sensitive information (API keys, passwords) is included

### Pull Request Process

1. **Update Your Branch**
   
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Push to Your Fork**
   
   ```bash
   git push origin feature/your-feature-name
   ```

3. **Create Pull Request**
   
   - Go to the [Windows-MCP repository](https://github.com/CursorTouch/Windows-MCP)
   - Click "New Pull Request"
   - Select your fork and branch
   - Fill out the PR template with:
     - **Description**: What does this PR do?
     - **Motivation**: Why is this change needed?
     - **Testing**: How was this tested?
     - **Screenshots**: If applicable (UI changes, new features)
     - **Related Issues**: Link any related issues

4. **Respond to Feedback**
   
   - Address reviewer comments promptly
   - Make requested changes in new commits
   - Push updates to the same branch

### Review Process

- Maintainers will review your PR within a few days
- You may be asked to make changes or provide clarification
- Once approved, a maintainer will merge your PR
- Your contribution will be acknowledged in release notes

## Documentation

Good documentation is crucial! When contributing:

### Code Documentation

- **Docstrings**: Add to all public functions, classes, and methods
- **Comments**: Explain complex logic or non-obvious decisions
- **Type hints**: Help users and tools understand your code

### User Documentation

Update relevant documentation files:

- **README.md**: For user-facing features or installation changes
- **SECURITY.md**: For security-related changes
- **CONTRIBUTING.md**: For development process changes

### Tool Documentation

When adding or modifying tools:

1. Update the tool's `description` parameter in `main.py`
2. Add appropriate `ToolAnnotations`
3. Update the tools list in `README.md`
4. Update `manifest.json` if needed

## Reporting Issues

Found a bug or have a feature request? Please open an issue!

### Bug Reports

Include:
- **Description**: Clear description of the bug
- **Steps to Reproduce**: Detailed steps to recreate the issue
- **Expected Behavior**: What should happen
- **Actual Behavior**: What actually happens
- **Environment**: Windows version, Python version, MCP client
- **Screenshots/Logs**: If applicable

### Feature Requests

Include:
- **Description**: What feature do you want?
- **Use Case**: Why is this feature needed?
- **Proposed Solution**: How might this be implemented?
- **Alternatives**: Other approaches you've considered

## Security Vulnerabilities

**DO NOT** report security vulnerabilities through public GitHub issues.

Instead, please:
1. Email the maintainers at [jeogeoalukka@gmail.com](mailto:jeogeoalukka@gmail.com)
2. Or use [GitHub Security Advisories](https://github.com/CursorTouch/Windows-MCP/security/advisories)

See our [Security Policy](SECURITY.md) for more details.

## Getting Help

Need help with your contribution?

- **Discord**: Join our [Discord Community](https://discord.com/invite/Aue9Yj2VzS)
- **Twitter/X**: Follow [@CursorTouch](https://x.com/CursorTouch)
- **GitHub Discussions**: Ask questions in [Discussions](https://github.com/CursorTouch/Windows-MCP/discussions)
- **Issues**: Open an issue for technical questions

## Types of Contributions

We welcome many types of contributions:

### Code Contributions

- **New Tools**: Add new MCP tools for Windows automation
- **Bug Fixes**: Fix issues in existing tools
- **Performance Improvements**: Optimize code for speed or efficiency
- **Refactoring**: Improve code structure and maintainability

### Non-Code Contributions

- **Documentation**: Improve README, guides, or docstrings
- **Testing**: Add test cases or improve test coverage
- **Bug Reports**: Report issues with detailed information
- **Feature Requests**: Suggest new features or improvements
- **Community Support**: Help others in Discord or Discussions
- **Translations**: Help translate documentation (future)

## Recognition

Contributors are recognized in:
- GitHub contributors page
- Release notes for significant contributions
- Special mentions for major features or fixes

## License

By contributing to Windows-MCP, you agree that your contributions will be licensed under the [MIT License](LICENSE.md).

---

Thank you for contributing to Windows-MCP! Your efforts help make this project better for everyone. 🙏

Made with ❤️ by the CursorTouch community

---

## 🤝 get-shit-done Contribution Guide (from `tools\get-shit-done\CONTRIBUTING.md`)

# Contributing to GSD

## Getting Started

```bash
# Clone the repo
git clone https://github.com/gsd-build/get-shit-done.git
cd get-shit-done

# Install dependencies
npm install

# Run tests
npm test
```

---

## Types of Contributions

GSD accepts three types of contributions. Each type has a different process and a different bar for acceptance. **Read this section before opening anything.**

### 🐛 Fix (Bug Report)

A fix corrects something that is broken, crashes, produces wrong output, or behaves contrary to documented behavior.

**Process:**
1. Open a [Bug Report issue](https://github.com/gsd-build/get-shit-done/issues/new?template=bug_report.yml) — fill it out completely.
2. Wait for a maintainer to confirm it is a bug (label: `confirmed-bug`). For obvious, reproducible bugs this is typically fast.
3. Fix it. Write a test that would have caught the bug.
4. Open a PR using the [Fix PR template](.github/PULL_REQUEST_TEMPLATE/fix.md) — link the confirmed issue.

**Rejection reasons:** Not reproducible, works-as-designed, duplicate of an existing issue.

---

### ⚡ Enhancement

An enhancement improves an existing feature — better output, faster execution, cleaner UX, expanded edge-case handling. It does **not** add new commands, new workflows, or new concepts.

**The bar:** Enhancements must have a scoped written proposal approved by a maintainer before any code is written. A PR for an enhancement will be closed without review if the linked issue does not carry the `approved-enhancement` label.

**Process:**
1. Open an [Enhancement issue](https://github.com/gsd-build/get-shit-done/issues/new?template=enhancement.yml) with the full proposal.  The issue template requires: the problem being solved, the concrete benefit, the scope of changes, and alternatives considered.
2. **Wait for maintainer approval.** A maintainer must label the issue `approved-enhancement` before you write a single line of code. Do not open a PR against an unapproved enhancement issue — it will be closed.
3. Write the code. Keep the scope exactly as approved. If scope creep occurs, comment on the issue and get re-approval before continuing.
4. Open a PR using the [Enhancement PR template](.github/PULL_REQUEST_TEMPLATE/enhancement.md) — link the approved issue.

**Rejection reasons:** Issue not labeled `approved-enhancement`, scope exceeds what was approved, no written proposal, duplicate of existing behavior.

---

### ✨ Feature

A feature adds something new — a new command, a new workflow, a new concept, a new integration. Features have the highest bar because they add permanent maintenance burden to a solo-developer tool maintained by a small team.

**The bar:** Features require a complete written specification approved by a maintainer before any code is written. A PR for a feature will be closed without review if the linked issue does not carry the `approved-feature` label. Incomplete specs are closed, not revised by maintainers.

**Process:**
1. **Discuss first** — check [Discussions](https://github.com/gsd-build/get-shit-done/discussions) to see if the idea has been raised. If it has and was declined, don't open a new issue.
2. Open a [Feature Request issue](https://github.com/gsd-build/get-shit-done/issues/new?template=feature_request.yml) with the complete spec. The template requires: the solo-developer problem being solved, what is being added, full scope of affected files and systems, user stories, acceptance criteria, and assessment of maintenance burden.
3. **Wait for maintainer approval.** A maintainer must label the issue `approved-feature` before you write a single line of code. Approval is not guaranteed — GSD is intentionally lean and many valid ideas are declined because they conflict with the project's design philosophy.
4. Write the code. Implement exactly the approved spec. Changes to scope require re-approval.
5. Open a PR using the [Feature PR template](.github/PULL_REQUEST_TEMPLATE/feature.md) — link the approved issue.

**Rejection reasons:** Issue not labeled `approved-feature`, spec is incomplete, scope exceeds what was approved, feature conflicts with GSD's solo-developer focus, maintenance burden too high.

---

## The Issue-First Rule — No Exceptions

> **No code before approval.**

For **fixes**: open the issue, confirm it's a bug, then fix it.
For **enhancements**: open the issue, get `approved-enhancement`, then code.
For **features**: open the issue, get `approved-feature`, then code.

PRs that arrive without a properly-labeled linked issue are closed automatically. This is not a bureaucratic hurdle — it protects you from spending time on work that will be rejected, and it protects maintainers from reviewing code for changes that were never agreed to.

---

## Pull Request Guidelines

**Every PR must link to an approved issue.** PRs without a linked issue are closed without review, no exceptions.

- **No draft PRs** — draft PRs are automatically closed. Only open a PR when it is complete, tested, and ready for review. If your work is not finished, keep it on your local branch until it is.
- **Use the correct PR template** — there are separate templates for [Fix](.github/PULL_REQUEST_TEMPLATE/fix.md), [Enhancement](.github/PULL_REQUEST_TEMPLATE/enhancement.md), and [Feature](.github/PULL_REQUEST_TEMPLATE/feature.md). Using the wrong template or using the default template for a feature is a rejection reason.
- **Link with a closing keyword** — use `Closes #123`, `Fixes #123`, or `Resolves #123` in the PR body. The CI check will fail and the PR will be auto-closed if no valid issue reference is found.
- **One concern per PR** — bug fixes, enhancements, and features must be separate PRs
- **No drive-by formatting** — don't reformat code unrelated to your change
- **CI must pass** — all matrix jobs (Ubuntu × Node 22, 24; macOS × Node 24) must be green
- **Scope matches the approved issue** — if your PR does more than what the issue describes, the extra changes will be asked to be removed or moved to a new issue

## Testing Standards

All tests use Node.js built-in test runner (`node:test`) and assertion library (`node:assert`). **Do not use Jest, Mocha, Chai, or any external test framework.**

### Required Imports

```javascript
const { describe, it, test, beforeEach, afterEach, before, after } = require('node:test');
const assert = require('node:assert/strict');
```

### Setup and Cleanup

There are two approved cleanup patterns. Choose the one that fits the situation.

**Pattern 1 — Shared fixtures (`beforeEach`/`afterEach`):** Use when all tests in a `describe` block share identical setup and teardown. This is the most common case.

```javascript
// GOOD — shared setup/teardown with hooks
describe('my feature', () => {
  let tmpDir;

  beforeEach(() => {
    tmpDir = createTempProject();
  });

  afterEach(() => {
    cleanup(tmpDir);
  });

  test('does the thing', () => {
    assert.strictEqual(result, expected);
  });
});
```

**Pattern 2 — Per-test cleanup (`t.after()`):** Use when individual tests require unique teardown that differs from other tests in the same block.

```javascript
// GOOD — per-test cleanup when each test needs different teardown
test('does the thing with a custom setup', (t) => {
  const tmpDir = createTempProject('custom-prefix');
  t.after(() => cleanup(tmpDir));

  assert.strictEqual(result, expected);
});
```

**Never use `try/finally` inside test bodies.** It is verbose, masks test failures, and is not an approved pattern in this project.

```javascript
// BAD — try/finally inside a test body
test('does the thing', () => {
  const tmpDir = createTempProject();
  try {
    assert.strictEqual(result, expected);
  } finally {
    cleanup(tmpDir); // masks failures — don't do this
  }
});
```

> `try/finally` is only permitted inside standalone utility or helper functions that have no access to test context.

### Use Centralized Test Helpers

Import helpers from `tests/helpers.cjs` instead of inlining temp directory creation:

```javascript
const { createTempProject, createTempGitProject, createTempDir, cleanup, runGsdTools } = require('./helpers.cjs');
```

| Helper | Creates | Use When |
|--------|---------|----------|
| `createTempProject(prefix?)` | tmpDir with `.planning/phases/` | Testing GSD tools that need planning structure |
| `createTempGitProject(prefix?)` | Same + git init + initial commit | Testing git-dependent features |
| `createTempDir(prefix?)` | Bare temp directory | Testing features that don't need `.planning/` |
| `cleanup(tmpDir)` | Removes directory recursively | Always use in `afterEach` |
| `runGsdTools(args, cwd, env?)` | Executes gsd-tools.cjs | Testing CLI commands |

### Test Structure

```javascript
describe('featureName', () => {
  let tmpDir;

  beforeEach(() => {
    tmpDir = createTempProject();
    // Additional setup specific to this suite
  });

  afterEach(() => {
    cleanup(tmpDir);
  });

  test('handles normal case', () => {
    // Arrange
    // Act
    // Assert
  });

  test('handles edge case', () => {
    // ...
  });

  describe('sub-feature', () => {
    // Nested describes can have their own hooks
    beforeEach(() => {
      // Additional setup for sub-feature
    });

    test('sub-feature works', () => {
      // ...
    });
  });
});
```

### Fixture Data Formatting

Template literals inside test blocks inherit indentation from the surrounding code. This can introduce unexpected leading whitespace that breaks regex anchors and string matching. Construct multi-line fixture strings using array `join()` instead:

```javascript
// GOOD — no indentation bleed
const content = [
  'line one',
  'line two',
  'line three',
].join('\n');

// BAD — template literal inherits surrounding indentation
const content = `
  line one
  line two
  line three
`;
```

### Prohibited: Source-Grep Tests

**Never read source-code `.cjs` files with `readFileSync` to assert that strings exist within them.** This is source-grep theater: it proves a literal is present in a file, not that the feature works at runtime.

```javascript
// BAD — source-grep theater
const configSrc = fs.readFileSync(
  path.join(GSD_ROOT, 'bin', 'lib', 'config-schema.cjs'), 'utf-8'
);
assert.ok(
  configSrc.includes("'workflow.plan_bounce'"),
  'VALID_CONFIG_KEYS should contain workflow.plan_bounce'
);
```

This test passes even if `workflow.plan_bounce` is present but misspelled in the schema, removed from the validation path, or moved to a different file under a different name. It survives every behavioral regression and fails only on trivial renames.

The correct pattern for config key tests — use the CLI:

```javascript
// GOOD — behavioral test via the CLI
test('config-set accepts workflow.plan_bounce', (t) => {
  const tmpDir = createTempProject();
  t.after(() => cleanup(tmpDir));

  const result = runGsdTools('config-set workflow.plan_bounce true', tmpDir);
  assert.ok(result.success, `config-set should accept workflow.plan_bounce: ${result.error}`);

  const configPath = path.join(tmpDir, '.planning', 'config.json');
  const config = JSON.parse(fs.readFileSync(configPath, 'utf-8'));
  assert.strictEqual(config.workflow?.plan_bounce, true, 'value must be persisted');
});
```

This single test covers key registration in `VALID_CONFIG_KEYS`, the key's namespace resolution in `KNOWN_TOP_LEVEL`, and value persistence — all behaviors that the source-grep test could not touch.

**Why this pattern broke at scale:** Commit `990c3e64` in this repo updated 5 source-grep tests in one pass when `VALID_CONFIG_KEYS` moved between files. Zero of those tests were testing behavior. If they had been behavioral tests, the migration would have been invisible.

**CI enforcement:** A linter (`scripts/lint-no-source-grep.cjs`, run as `npm run lint:tests`) detects violations. Any test file that calls `readFileSync` on a `.cjs` path in a source directory without the exemption annotation below will fail the `lint-tests` CI job.

### Exception: `allow-test-rule: <reason>`

Some tests legitimately read source files. There are six recognized categories:

| Reason | When to use |
|--------|-------------|
| `source-text-is-the-product` | Agent `.md`, workflow `.md`, command `.md` files — their text IS what the runtime loads. Testing text content tests the deployed contract. |
| `architectural-invariant` | Implementation must use a specific primitive (e.g., `Atomics.wait`, atomic file writes) that cannot be tested by observing outputs. |
| `structural-regression-guard` | A specific code pattern must (or must not) exist to prevent a class of bug (e.g., regex global-state misuse). Behavioral tests cannot distinguish which pattern was used. |
| `docs-parity` | A reference doc must stay in sync with source-defined constants (e.g., `CONFIG_DEFAULTS`). The source is the canonical list; there is no runtime API to enumerate it. |
| `integration-test-input` | A source file is used as a real fixture input to a transformation function under test — the file is not inspected for strings but passed as data. |
| `structural-implementation-guard` | A feature's interception or wiring point is not reachable end-to-end via `runGsdTools`. Used temporarily until a behavioral path exists. |

Annotate with a standalone `//` comment before the file's opening block comment:

```javascript
// allow-test-rule: architectural-invariant
// state.cjs locking must use Atomics.wait(), not a spin-loop. Behavioral tests
// cannot observe which sleep primitive was chosen — only source inspection can.

/**
 * Regression tests for locking bugs #1909...
 */
```

The annotation **must** be a standalone `// allow-test-rule:` line, not inside a `/** */` block comment — the CI linter scans for the pattern `// allow-test-rule:`.

### Node.js Version Compatibility

**Node 22 is the minimum supported version.** Node 24 is the primary CI target. All tests must pass on both.

| Version | Status |
|---------|--------|
| **Node 22** | Minimum required — Active LTS until October 2026, Maintenance LTS until April 2027 |
| **Node 24** | Primary CI target — current Active LTS, all tests must pass |
| Node 26 | Forward-compatible target — avoid deprecated APIs |

Do not use:
- Deprecated APIs
- APIs not available in Node 22

Safe to use:
- `node:test` — stable since Node 18, fully featured in 24
- `describe`/`it`/`test` — all supported
- `beforeEach`/`afterEach`/`before`/`after` — all supported
- `t.after()` — per-test cleanup
- `t.plan()` — fully supported
- Snapshot testing — fully supported

### Assertions

Use `node:assert/strict` for strict equality by default:

```javascript
const assert = require('node:assert/strict');

assert.strictEqual(actual, expected);      // ===
assert.deepStrictEqual(actual, expected);  // deep ===
assert.ok(value);                          // truthy
assert.throws(() => { ... }, /pattern/);   // throws
assert.rejects(async () => { ... });       // async throws
```

### Running Tests

```bash
# Run all tests
npm test

# Run a single test file
node --test tests/core.test.cjs

# Run with coverage
npm run test:coverage
```

### CI Test Quality Checks

The following checks run on every PR in addition to the test suite:

| Job | What it checks | How to pass |
|-----|----------------|-------------|
| `lint-tests` | No source-grep tests (see above) | Replace with `runGsdTools()` behavioral tests, or add `// allow-test-rule: <reason>` |

Run locally before pushing: `npm run lint:tests`

### Test Requirements by Contribution Type

The required tests differ depending on what you are contributing:

**Bug Fix:** A regression test is required. Write the test first — it must demonstrate the original failure before your fix is applied, then pass after the fix. A PR that fixes a bug without a regression test will be asked to add one. "Tests pass" does not prove correctness; it proves the bug isn't present in the tests that exist.

**Enhancement:** Tests covering the enhanced behavior are required. Update any existing tests that test the area you changed. Do not leave tests that pass but no longer accurately describe the behavior.

**Feature:** Tests are required for the primary success path and at minimum one failure scenario. Leaving gaps in test coverage for a new feature is a rejection reason.

**Behavior Change:** If your change modifies existing behavior, the existing tests covering that behavior must be updated or replaced. Leaving passing-but-incorrect tests in the suite is not acceptable — a test that passes but asserts the old (now wrong) behavior makes the suite less useful than no test at all.

### Reviewer Standards

Reviewers do not rely solely on CI to verify correctness. Before approving a PR, reviewers:

- Build locally (`npm run build` if applicable)
- Run the full test suite locally (`npm test`)
- Confirm regression tests exist for bug fixes and that they would fail without the fix
- Validate that the implementation matches what the linked issue described — green CI on the wrong implementation is not an approval signal

**"Tests pass in CI" is not sufficient for merge.** The implementation must correctly solve the problem described in the linked issue.

## Code Style

- **CommonJS** (`.cjs`) — the project uses `require()`, not ESM `import`
- **No external dependencies in core** — `gsd-tools.cjs` and all lib files use only Node.js built-ins
- **Conventional commits** — `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `ci:`

## File Structure

```
bin/install.js          — Installer (multi-runtime)
get-shit-done/
  bin/lib/              — Core library modules (.cjs)
  workflows/            — Workflow definitions (.md)
                          Large workflows split per progressive-disclosure
                          pattern: workflows/<name>/modes/*.md +
                          workflows/<name>/templates/*. Parent dispatches
                          to mode files. See workflows/discuss-phase/ as
                          the canonical example (#2551). New modes for
                          discuss-phase land in
                          workflows/discuss-phase/modes/<mode>.md.
                          Per-file budgets enforced by
                          tests/workflow-size-budget.test.cjs.
  references/           — Reference documentation (.md)
  templates/            — File templates
agents/                 — Agent definitions (.md) — CANONICAL SOURCE
commands/gsd/           — Slash command definitions (.md)
tests/                  — Test files (.test.cjs)
  helpers.cjs           — Shared test utilities
docs/                   — User-facing documentation
```

### Source of truth for agents

Only `agents/` at the repo root is tracked by git. The following directories may exist on a developer machine with GSD installed and **must not be edited** — they are install-sync outputs and will be overwritten:

| Path | Gitignored | What it is |
|------|-----------|------------|
| `.claude/agents/` | Yes (`.gitignore:9`) | Local Claude Code runtime sync |
| `.cursor/agents/` | Yes (`.gitignore:12`) | Local Cursor IDE bundle |
| `.github/agents/gsd-*` | Yes (`.gitignore:37`) | Local CI-surface bundle |

If you find that `.claude/agents/` has drifted from `agents/` (e.g., after a branch change), re-run `bin/install.js` to re-sync from the canonical source. Always edit `agents/` — never the derivative directories.

## Security

- **Path validation** — use `validatePath()` from `security.cjs` for any user-provided paths
- **No shell injection** — use `execFileSync` (array args) over `execSync` (string interpolation)
- **No `${{ }}` in GitHub Actions `run:` blocks** — bind to `env:` mappings first

---