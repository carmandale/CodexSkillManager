# AgentConfigManager

## What this app is
AgentConfigManager is a macOS SwiftUI app built with SwiftPM (no Xcode project) that manages skills, extensions, commands, and AGENTS.md files for multiple AI coding agents.

## How it works
- The app scans multiple agent directories for skills, extensions, and commands
- Uses a 3-column NavigationSplitView with sidebar sections, content list, and detail view
- Supports Pi Agent, Claude Code, Codex, OpenCode, and Copilot
- Agent filter allows focusing on specific platforms

## Build and run
- Build: `swift build`
- Run: `swift run AgentConfigManager`
When editing this app, build after each change and fix any compile errors before continuing.

## Packaging and release
Use the `macos-spm-app-packaging` skill for packaging, notarization, appcast, and GitHub release steps.
Local packaging helpers live in `Scripts/`:
- `Scripts/compile_and_run.sh`: package (adhoc sign) + launch the `.app`.
- `Scripts/package_app.sh`: build and create `AgentConfigManager.app`.
- `Scripts/sign-and-notarize.sh`: sign + notarize for releases.
- `Scripts/make_appcast.sh`: generate Sparkle appcast from a zip.
- `Scripts/generate_sparkle_keys.sh`: generate Sparkle keypair and export private key.

Sparkle env vars (set in `~/.zshrc`):
- `SPARKLE_PUBLIC_KEY`
- `SPARKLE_PRIVATE_KEY_FILE`
- `SPARKLE_FEED_URL`

## Release flow (commit → changelog → notarize → appcast → GitHub release)
1) Update version: bump `MARKETING_VERSION` and `BUILD_NUMBER` in `version.env`.
2) Build: `swift build`.
3) Commit + push:
   - `git add -A`
   - `git commit -m "feat: ..."` (or other Conventional Commit type)
   - `git push`
4) Write release notes (short, user-facing bullets) and save to a file, e.g. `/tmp/agentconfigmanager-release-notes-<version>.md`.
5) Notarize and package:
   - `APP_STORE_CONNECT_API_KEY_P8="/path/to/key.p8" APP_STORE_CONNECT_KEY_ID="..." APP_STORE_CONNECT_ISSUER_ID="..." APP_IDENTITY="Developer ID Application: ..."`
   - `./Scripts/sign-and-notarize.sh`
   - Note: `SPARKLE_PUBLIC_KEY` must be set (and `SPARKLE_FEED_URL` if non-default) or the build will be missing Sparkle keys and updates will not work.
6) Generate Sparkle appcast entry:
   - `SPARKLE_PRIVATE_KEY_FILE="..." ./Scripts/make_appcast.sh AgentConfigManager-<version>.zip <appcast-url>`
   - Note: Sparkle uses the build number (`BUILD_NUMBER`) for `sparkle:version`, so it must increase each release.
   - `git add appcast.xml`
   - `git commit -m "chore: update sparkle appcast"`
   - `git push`
7) Publish GitHub release (creates the tag):
   - `gh release create v<version> AgentConfigManager-<version>.zip appcast.xml --title "Agent Config Manager <version>" --notes-file /tmp/agentconfigmanager-release-notes-<version>.md`

## Project layout
- `Package.swift`: SwiftPM manifest for the executable target.
- `Sources/AgentConfigManager/App/AgentConfigManagerApp.swift`: App entry point + dependency injection.
- `Sources/AgentConfigManager/App/AppModel.swift`: Root coordinator with all stores.
- `Sources/AgentConfigManager/App/MainSplitView.swift`: 3-column NavigationSplitView shell.
- `Sources/AgentConfigManager/App/SidebarView.swift`: Sidebar with sections and agent filter.
- `Sources/AgentConfigManager/Skills/`: Skill management views and stores.
- `Sources/AgentConfigManager/Extensions/`: Pi Agent extension views and stores.
- `Sources/AgentConfigManager/Commands/`: Command management views and stores.
- `Sources/AgentConfigManager/AgentsMd/`: AGENTS.md symlink management.
- `Sources/AgentConfigManager/Repos/`: Repository scanning views and stores.
- `Sources/AgentConfigManager/Wizards/`: Migration and symlink wizards.
- `Sources/AgentConfigManager/Models/`: Data models (AgentID, AgentConfig, etc.).
- `version.env`: Template version file (used by the packaging scripts if added later).
