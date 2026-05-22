# Installing Understand-Anything for Codex

## Prerequisites

- Git

## Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Lum1104/Understand-Anything.git ~/.codex/understand-anything
   ```

2. **Create the skills symlinks:**
   ```bash
   mkdir -p ~/.agents/skills
   # Note: if OpenCode's Understand-Anything is already installed, these symlinks
   # already exist and the ln commands will safely fail — that is fine, the
   # existing symlinks work for Codex too.
   for skill in understand understand-chat understand-dashboard understand-diff understand-explain understand-onboard; do
     ln -sf ~/.codex/understand-anything/understand-anything-plugin/skills/$skill ~/.agents/skills/$skill
   done
   # Universal plugin root symlink — lets the dashboard skill find packages/dashboard/
   # Skip if already exists (e.g. another platform was installed first)
   [ -e ~/.understand-anything-plugin ] || [ -L ~/.understand-anything-plugin ] || ln -s ~/.codex/understand-anything/understand-anything-plugin ~/.understand-anything-plugin
   ```

   **Windows (PowerShell):**
   ```powershell
   New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.agents\skills"
   $skills = @("understand","understand-chat","understand-dashboard","understand-diff","understand-explain","understand-onboard")
   foreach ($skill in $skills) {
     cmd /c mklink /J "$env:USERPROFILE\.agents\skills\$skill" "$env:USERPROFILE\.codex\understand-anything\understand-anything-plugin\skills\$skill"
   }
   # Universal plugin root symlink
   cmd /c mklink /J "$env:USERPROFILE\.understand-anything-plugin" "$env:USERPROFILE\.codex\understand-anything\understand-anything-plugin"
   ```

3. **Restart Codex** to discover the skills.

## Verify

```bash
ls -la ~/.agents/skills/ | grep understand
```

You should see symlinks for each skill pointing into the cloned repository.

## Usage

Skills activate automatically when relevant. You can also invoke directly:
- "Analyze this codebase and build a knowledge graph"
- "Help me understand this project's architecture"

## Updating

```bash
cd ~/.codex/understand-anything && git pull
```

Skills update instantly through the symlinks.

## Uninstalling

```bash
for skill in understand understand-chat understand-dashboard understand-diff understand-explain understand-onboard; do
  rm -f ~/.agents/skills/$skill
done
rm ~/.understand-anything-plugin
rm -rf ~/.codex/understand-anything
```
