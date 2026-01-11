# Agent Config Manager

![image](image.png)

Agent Config Manager is a macOS SwiftUI app built with SwiftPM (no Xcode project). It manages local skills, extensions, commands, and AGENTS.md files for multiple AI coding agents including Pi Agent, Claude Code, Codex, OpenCode, and Copilot.

## Features
- Browse local skills from multiple agents (`~/.pi/agent/skills`, `~/.codex/skills/public`, `~/.claude/skills`, etc.)
- Browse Pi Agent extensions from `~/.pi/agent/extensions`
- Browse commands from `~/.agent-config/commands`
- Manage AGENTS.md symlinks across agents
- Scan repositories for agent configurations
- Render `SKILL.md` with Markdown, plus inline reference previews
- Import skills from a folder or zip
- Delete skills from the sidebar
- Browse Clawdhub skills with search + latest drops
- Download remote skills to selected agent platforms
- Visual tags for installed status and versions
- Agent filter to focus on specific platforms
- Migration wizard for importing legacy configs
- Symlink wizard for setting up central AGENTS.md

## Requirements
- macOS 26+
- Swift 6.2+

## Build and run
```
swift build
swift run AgentConfigManager
```

## Package a local app
```
./Scripts/compile_and_run.sh
```

## Credits
- Markdown rendering via https://github.com/gonzalezreal/swift-markdown-ui
- Remote skill catalog via https://clawdhub.com
