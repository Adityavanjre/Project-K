# Installing Understand-Anything for OpenCode

## Prerequisites

- Git
- [OpenCode](https://opencode.ai) installed

## Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Lum1104/Understand-Anything.git ~/.opencode/understand-anything
   ```

2. **Create the skills symlinks:**
   ```bash
   mkdir -p ~/.agents/skills
   # Note: if Codex's Understand-Anything is already installed, these symlinks
   # already exist and the ln commands will safely fail — that is fine, the
   # existing symlinks work for OpenCode too.
   for skill in understand understand-chat understand-dashboard understand-diff understand-explain understand-onboard; do
     ln -sf ~/.opencode/understand-anything/understand-anything-plugin/skills/$skill ~/.agents/skills/$skill
   done
   # Universal plugin root symlink — lets the dashboard skill find packages/dashboard/
   # Skip if already exists (e.g. another platform was installed first)
   [ -e ~/.understand-anything-plugin ] || [ -L ~/.understand-anything-plugin ] || ln -s ~/.opencode/understand-anything/understand-anything-plugin ~/.understand-anything-plugin
   ```

   **Windows (PowerShell):**
   ```powershell
   New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.agents\skills"
   $skills = @("understand","understand-chat","understand-dashboard","understand-diff","understand-explain","understand-onboard")
   foreach ($skill in $skills) {
     cmd /c mklink /J "$env:USERPROFILE\.agents\skills\$skill" "$env:USERPROFILE\.opencode\understand-anything\understand-anything-plugin\skills\$skill"
   }
   # Universal plugin root symlink
   cmd /c mklink /J "$env:USERPROFILE\.understand-anything-plugin" "$env:USERPROFILE\.opencode\understand-anything\understand-anything-plugin"
   ```

3. **Restart OpenCode** to discover the skills.

## Verify

```bash
ls -la ~/.agents/skills/ | grep understand
```

You should see symlinks for each skill pointing into the cloned repository.

## Usage

Skills activate automatically when relevant. You can also invoke directly:

```
use skill tool to load understand
```

Or just ask: "Analyze this codebase and build a knowledge graph"

## Updating

```bash
cd ~/.opencode/understand-anything && git pull
```

Skills update instantly through the symlinks.

## Uninstalling

```bash
for skill in understand understand-chat understand-dashboard understand-diff understand-explain understand-onboard; do
  rm -f ~/.agents/skills/$skill
done
rm ~/.understand-anything-plugin
rm -rf ~/.opencode/understand-anything
```

## Troubleshooting

### Skills not found

1. Check that the symlinks exist: `ls -la ~/.agents/skills/ | grep understand`
2. Verify the clone succeeded: `ls ~/.opencode/understand-anything/understand-anything-plugin/skills/`
3. Restart OpenCode

### Tool mapping

When skills reference Claude Code tools:
- `TodoWrite` → `todowrite`
- `Task` with subagents → `@mention` syntax
- `Skill` tool → OpenCode's native `skill` tool
- File operations → your native tools
