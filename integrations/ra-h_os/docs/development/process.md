# Development Process (RA-OS)

This repo is the open-source build of RA-H. Keep changes focused, reviewable, and easy to maintain.

`AGENTS.md` is the source of truth for agent/contributor workflow in this repository.

## Branching

- Create a feature branch off `main` for all changes.
- Use short, descriptive names: `docs/<short-name>`, `fix/<short-name>`, `feat/<short-name>`.
- Avoid direct commits to `main`.

## Local Setup

```bash
git clone https://github.com/bradwmorris/ra-h_os.git
cd ra-h_os
npm install
npm run setup:local
npm run dev
```

## Dev Loop

1. Reproduce or define the change.
2. Implement in a small, isolated diff.
3. Run checks (see below).
4. Update docs if behavior or UX changes.

## Checks

```bash
npm run type-check
npm run lint
npm run build
```

## PR Checklist

- Clear description of the change and why it matters.
- Screenshots or GIFs for UI changes.
- Docs updated if the public-facing behavior changed.
- Checks pass locally.

## Sync Policy (Private Upstream)

- `ra-h_os` accepts direct contributions.
- Maintainers may port relevant changes between public and private repos.
- Public contributions will not be overwritten by syncs.

## Current Status

- `main` includes the March 15, 2026 sync from the private app repo:
  - stronger node/chunk retrieval
  - flatter dimension/runtime contract
  - stricter node/edge validation
  - improved eval logging/UI
  - reduced 5-scenario eval suite with archived legacy scenarios
- after pulling changes, if SQLite routes fail locally, run `npm run setup:local` under the same Node version used for `npm run dev`
