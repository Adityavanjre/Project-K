# Installing Understand-Anything for VS Code + GitHub Copilot

## Prerequisites

- [VS Code](https://code.visualstudio.com/) with the [GitHub Copilot](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot) extension (v1.108+)
- Git

## Option A — Auto-discovery (recommended)

Clone this repo and open it in VS Code. GitHub Copilot automatically discovers the plugin via `.copilot-plugin/plugin.json` — no manual steps required.

```bash
git clone https://github.com/Lum1104/Understand-Anything.git
code Understand-Anything
```

Skills will appear when you type `/` in GitHub Copilot Chat.

## Option B — Personal skills (available across all projects)

1. **Clone the repository** (to any location you prefer):
   ```bash
   git clone https://github.com/Lum1104/Understand-Anything.git ~/understand-anything
   ```

2. **Create a symlink for each skill** into `~/.copilot/skills/`:
   ```bash
   mkdir -p ~/.copilot/skills
   SKILLS_DIR=~/understand-anything/understand-anything-plugin/skills
   for skill in "$SKILLS_DIR"/*/; do
     ln -sf "$skill" ~/.copilot/skills/$(basename "$skill")
   done
   # Universal plugin root symlink — lets the dashboard skill find packages/dashboard/
   # Skip if already exists (e.g. another platform was installed first)
   [ -e ~/.understand-anything-plugin ] || [ -L ~/.understand-anything-plugin ] || \
     ln -s ~/understand-anything/understand-anything-plugin ~/.understand-anything-plugin
   ```

   **Windows (PowerShell):**
   ```powershell
   New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.copilot\skills"
   $skillsDir = "$env:USERPROFILE\understand-anything\understand-anything-plugin\skills"
   Get-ChildItem $skillsDir -Directory | ForEach-Object {
     cmd /c mklink /J "$env:USERPROFILE\.copilot\skills\$($_.Name)" $_.FullName
   }
   cmd /c mklink /J "$env:USERPROFILE\.understand-anything-plugin" "$env:USERPROFILE\understand-anything\understand-anything-plugin"
   ```

3. **Reload VS Code** (`Cmd+Shift+P` → `Developer: Reload Window`) so GitHub Copilot discovers the skills.

## Verify

Type `/` in GitHub Copilot Chat — you should see all six skills listed:

- `understand` — build the knowledge graph
- `understand-chat` — ask questions about the codebase
- `understand-dashboard` — open the interactive dashboard
- `understand-diff` — analyze impact of current changes
- `understand-explain` — deep-dive into a file or function
- `understand-onboard` — generate an onboarding guide

## Usage

Skills activate automatically when relevant. You can also invoke them directly by typing `/` in Copilot Chat and selecting a skill.

## Updating

```bash
cd ~/understand-anything && git pull
```

Skills update instantly through the symlinks.

## Uninstalling

```bash
for skill in understand understand-chat understand-dashboard understand-diff understand-explain understand-onboard; do
  rm -f ~/.copilot/skills/$skill
done
rm -f ~/.understand-anything-plugin
rm -rf ~/understand-anything
```
