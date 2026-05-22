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
