# Installing Understand-Anything for Antigravity

## Prerequisites

- Git

## Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Lum1104/Understand-Anything.git ~/.antigravity/understand-anything
   ```

2. **Create the skills symlinks:**
   ```bash
   mkdir -p ~/.gemini/antigravity/skills
   ln -s ~/.antigravity/understand-anything/understand-anything-plugin/skills ~/.gemini/antigravity/skills/understand-anything
   # Universal plugin root symlink — lets the dashboard skill find packages/dashboard/
   # Skip if already exists (e.g. another platform was installed first)
   [ -e ~/.understand-anything-plugin ] || [ -L ~/.understand-anything-plugin ] || ln -s ~/.antigravity/understand-anything/understand-anything-plugin ~/.understand-anything-plugin
   ```

   **Windows (PowerShell):**
   ```powershell
   New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.gemini\antigravity\skills"
   cmd /c mklink /J "$env:USERPROFILE\.gemini\antigravity\skills\understand-anything" "$env:USERPROFILE\.antigravity\understand-anything\understand-anything-plugin\skills"
   cmd /c mklink /J "$env:USERPROFILE\.understand-anything-plugin" "$env:USERPROFILE\.antigravity\understand-anything\understand-anything-plugin"
   ```

3. **Restart the chat or IDE** so Antigravity can discover the skills.

## Verify

```bash
ls -la ~/.gemini/antigravity/skills/understand-anything
```

You should see a symlink pointing to the skills directory in the cloned repo.

## Usage

Skills activate automatically when relevant. You can also invoke directly by saying:
- "Run the understand skill to analyze this codebase"
- "Use the understand-dashboard skill to view the architecture map"
- "Use understand-chat to answer a question about the graph"

## Updating

```bash
cd ~/.antigravity/understand-anything && git pull
```

Skills update instantly through the symlink.

## Uninstalling

```bash
rm ~/.gemini/antigravity/skills/understand-anything
rm ~/.understand-anything-plugin
rm -rf ~/.antigravity/understand-anything
```
