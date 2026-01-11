# Agent Config Manager — Agent Filter & Paths Refactor Plan

> Based on Oracle research (GPT-5.2 Pro) with documentation-grounded findings
> Created: 2026-01-11
> Updated: 2026-01-11 (incorporated review feedback)

---

## Overview

This plan addresses three main goals:
1. **Fix incorrect paths** in `AgentConfigPaths.swift` based on oracle research
2. **Refactor agent filter** from checkboxes to status indicators (filtering removed, replaced with navigation)
3. **Add missing sections**: Plugins, Hooks (properly separated)
4. **Remove GitHub Copilot** (user doesn't use it)

---

## Corrected Agent Capability Matrix

```
Agent       Skills    Extensions    Plugins       Hooks                  Commands
────────────────────────────────────────────────────────────────────────────────────
Pi Agent    ✅ SKILL.md  ✅ TS      ❌            ✅ via extensions      ✅ via extensions
Claude      ✅ SKILL.md  ❌         ✅ JSON       ✅ folder + settings   ✅ folder
Codex       ✅ SKILL.md  ❌         ❌            ❌                     ✅ prompts/
OpenCode    ✅ SKILL.md  ❌         ✅ TS/JS      ✅ via plugins         ✅ folder
```

---

## Phase 0: Directory Setup

### 0.1 Create new directories

```bash
mkdir -p Sources/AgentConfigManager/Plugins
mkdir -p Sources/AgentConfigManager/Hooks
mkdir -p Sources/AgentConfigManager/Agents
```

**VERIFY**: Directories exist

---

## Phase 1: Fix AgentConfigPaths.swift

### Current Issues

| Agent | Issue | Current | Correct |
|-------|-------|---------|---------|
| Claude | Missing instructions filename | `AGENTS.md` | `CLAUDE.md` |
| Claude | Missing plugins path | — | `~/.claude/plugins/` |
| Claude | Missing hooks path | — | `~/.claude/hooks/` |
| Codex | Wrong skills path | `skills/public` | `skills/` |
| Codex | Missing prompts path | — | `~/.codex/prompts/` |
| OpenCode | Wrong root path | `~/.opencode` | `~/.config/opencode` |
| OpenCode | Wrong skills path | `~/.opencode/skills` | `~/.config/opencode/skill/` (singular!) |
| OpenCode | Missing commands path | — | `~/.config/opencode/command/` (singular!) |
| OpenCode | Missing plugins path | — | `~/.config/opencode/plugin/` |
| Copilot | Remove entirely | exists | remove |

### 1.1 Update AgentConfigPaths.swift

**WHERE**: `Sources/AgentConfigManager/Models/AgentConfigPaths.swift`

```swift
import Foundation

enum AgentConfigPaths {
    private static let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
    private static let configDirectory = homeDirectory.appending(path: ".config")

    // MARK: - Central Configuration (shared across agents)
    
    static let centralRootURL = homeDirectory.appending(path: ".agent-config")
    static let centralAgentsMarkdownURL = centralRootURL.appending(path: "AGENTS.md")
    static let centralCommandsURL = centralRootURL.appending(path: "commands")
    static let centralKnowledgeURL = centralRootURL.appending(path: "knowledge")

    // MARK: - Pi Agent
    
    static let piRootURL = homeDirectory.appending(path: ".pi/agent")
    static let piSkillsURL = piRootURL.appending(path: "skills")
    static let piExtensionsURL = piRootURL.appending(path: "extensions")
    static let piCommandsURL = piRootURL.appending(path: "commands")
    static let piAgentsMarkdownURL = piRootURL.appending(path: "AGENTS.md")
    static let piSettingsURL = piRootURL.appending(path: "settings.json")

    // MARK: - Claude Code
    
    static let claudeRootURL = homeDirectory.appending(path: ".claude")
    static let claudeSkillsURL = claudeRootURL.appending(path: "skills")
    static let claudeCommandsURL = claudeRootURL.appending(path: "commands")
    static let claudeHooksURL = claudeRootURL.appending(path: "hooks")
    static let claudePluginsURL = claudeRootURL.appending(path: "plugins")  // Primary source
    static let claudePluginsCacheURL = claudePluginsURL.appending(path: "cache")  // Derived/cached
    static let claudeSettingsURL = claudeRootURL.appending(path: "settings.json")
    static let claudeAgentsMarkdownURL = claudeRootURL.appending(path: "CLAUDE.md")  // FIXED: was AGENTS.md

    // MARK: - Codex CLI
    
    static let codexRootURL = homeDirectory.appending(path: ".codex")
    static let codexSkillsURL = codexRootURL.appending(path: "skills")  // FIXED: was skills/public
    static let codexPromptsURL = codexRootURL.appending(path: "prompts")  // Commands for Codex
    static let codexRulesURL = codexRootURL.appending(path: "rules")
    static let codexConfigURL = codexRootURL.appending(path: "config.toml")
    static let codexAgentsMarkdownURL = codexRootURL.appending(path: "AGENTS.md")

    // MARK: - OpenCode
    
    static let opencodeRootURL = configDirectory.appending(path: "opencode")  // FIXED: was ~/.opencode
    static let opencodeSkillsURL = opencodeRootURL.appending(path: "skill")  // FIXED: singular (was "skills")
    static let opencodeCommandsURL = opencodeRootURL.appending(path: "command")  // FIXED: singular
    static let opencodePluginsURL = opencodeRootURL.appending(path: "plugin")  // singular
    static let opencodeAgentsMarkdownURL = opencodeRootURL.appending(path: "AGENTS.md")
    
    // OpenCode project-local paths (for reference in comments):
    // .opencode/skill/, .opencode/command/, .opencode/plugin/

    // MARK: - Legacy Migration
    
    static let legacyOpencodeConfigURL = homeDirectory.appending(path: "opencode-config")
    static let legacyOpencodeAgentsMarkdownURL = legacyOpencodeConfigURL.appending(path: "AGENTS.md")
    static let legacyOpencodeCommandsURL = legacyOpencodeConfigURL.appending(path: "commands")
    static let legacyOpencodeKnowledgeURL = legacyOpencodeConfigURL.appending(path: "knowledge")
    
    // MARK: - Path Resolution Helpers
    
    /// Returns the first URL that exists on disk, or nil if none exist
    static func firstExisting(_ candidates: [URL]) -> URL? {
        let fm = FileManager.default
        return candidates.first { fm.fileExists(atPath: $0.path) }
    }
    
    /// OpenCode skill path with fallback (singular preferred, plural fallback)
    static var opencodeSkillsResolved: URL? {
        firstExisting([
            opencodeSkillsURL,
            opencodeRootURL.appending(path: "skills")  // plural fallback
        ])
    }
    
    /// OpenCode command path with fallback
    static var opencodeCommandsResolved: URL? {
        firstExisting([
            opencodeCommandsURL,
            opencodeRootURL.appending(path: "commands")  // plural fallback
        ])
    }
}
```

**VERIFY**: `swift build`

---

### 1.2 Update AgentID.swift — Remove Copilot

**WHERE**: `Sources/AgentConfigManager/Models/AgentID.swift`

```swift
enum AgentID: String, CaseIterable, Identifiable, Hashable, Sendable {
    case pi
    case claude
    case codex
    case opencode
    // REMOVED: case copilot
    
    var id: String { rawValue }
    
    var cliName: String {
        switch self {
        case .pi: return "pi"
        case .claude: return "claude"
        case .codex: return "codex"
        case .opencode: return "opencode"
        }
    }
}
```

**VERIFY**: `swift build`

---

### 1.3 Update SkillPlatform.swift — Fix paths, remove Copilot

**WHERE**: `Sources/AgentConfigManager/Skills/Shared/SkillPlatform.swift`

Remove `.copilot` case and fix paths:

```swift
enum SkillPlatform: String, CaseIterable, Identifiable, Hashable, Sendable, Codable {
    case pi = "Pi Agent"
    case codex = "Codex"
    case claude = "Claude Code"
    case opencode = "OpenCode"
    // REMOVED: case copilot

    var relativePath: String {
        switch self {
        case .pi:
            return ".pi/agent/skills"
        case .codex:
            return ".codex/skills"  // FIXED: was .codex/skills/public
        case .claude:
            return ".claude/skills"
        case .opencode:
            return ".config/opencode/skill"  // FIXED: singular (was .opencode/skills)
        }
    }
    
    var agentID: AgentID {
        switch self {
        case .pi: return .pi
        case .codex: return .codex
        case .claude: return .claude
        case .opencode: return .opencode
        }
    }
    
    // ... keep other properties, remove copilot cases from each
}
```

**VERIFY**: `swift build`

---

### 1.4 Create SupportMode enum

**CREATE**: `Sources/AgentConfigManager/Models/SupportMode.swift`

```swift
import Foundation

/// Describes how an agent supports a particular capability
enum SupportMode: Hashable, Sendable {
    /// Not supported
    case none
    
    /// Supported via a dedicated folder
    case folder(URL)
    
    /// Supported via the extension system (Pi Agent)
    case viaExtensions
    
    /// Supported via the plugin system (OpenCode)
    case viaPlugins
    
    /// Supported via a settings/config file
    case viaSettings(URL)
    
    var isSupported: Bool {
        if case .none = self { return false }
        return true
    }
    
    var folderURL: URL? {
        if case .folder(let url) = self { return url }
        return nil
    }
    
    var displayDescription: String {
        switch self {
        case .none: return "Not supported"
        case .folder: return "Folder"
        case .viaExtensions: return "Via extensions"
        case .viaPlugins: return "Via plugins"
        case .viaSettings: return "Via settings"
        }
    }
}
```

**VERIFY**: `swift build`

---

### 1.5 Create AgentCapabilities struct

**CREATE**: `Sources/AgentConfigManager/Models/AgentCapabilities.swift`

```swift
import Foundation

/// Defines what capabilities an agent supports and how
struct AgentCapabilities: Hashable, Sendable {
    let skills: SupportMode
    let extensions: SupportMode
    let plugins: SupportMode
    let hooks: SupportMode
    let commands: SupportMode
    let instructions: SupportMode
    
    /// The filename used for skill documentation (e.g., "SKILL.md")
    let skillDocFilename: String
    
    /// All content URLs for this agent (used to determine "hasContent")
    var contentURLs: [URL] {
        [skills, extensions, plugins, hooks, commands, instructions]
            .compactMap { $0.folderURL }
    }
    
    // MARK: - Predefined Configurations
    
    static let pi = AgentCapabilities(
        skills: .folder(AgentConfigPaths.piSkillsURL),
        extensions: .folder(AgentConfigPaths.piExtensionsURL),
        plugins: .none,
        hooks: .viaExtensions,
        commands: .viaExtensions,  // Commands registered via pi.registerCommand()
        instructions: .folder(AgentConfigPaths.piAgentsMarkdownURL),
        skillDocFilename: "SKILL.md"
    )
    
    static let claude = AgentCapabilities(
        skills: .folder(AgentConfigPaths.claudeSkillsURL),
        extensions: .none,
        plugins: .folder(AgentConfigPaths.claudePluginsURL),
        hooks: .folder(AgentConfigPaths.claudeHooksURL),  // Also configured in settings.json
        commands: .folder(AgentConfigPaths.claudeCommandsURL),
        instructions: .folder(AgentConfigPaths.claudeAgentsMarkdownURL),
        skillDocFilename: "SKILL.md"
    )
    
    static let codex = AgentCapabilities(
        skills: .folder(AgentConfigPaths.codexSkillsURL),
        extensions: .none,
        plugins: .none,
        hooks: .none,
        commands: .folder(AgentConfigPaths.codexPromptsURL),  // "prompts" = commands for Codex
        instructions: .folder(AgentConfigPaths.codexAgentsMarkdownURL),
        skillDocFilename: "SKILL.md"
    )
    
    static let opencode = AgentCapabilities(
        skills: .folder(AgentConfigPaths.opencodeSkillsURL),
        extensions: .none,
        plugins: .folder(AgentConfigPaths.opencodePluginsURL),
        hooks: .viaPlugins,
        commands: .folder(AgentConfigPaths.opencodeCommandsURL),
        instructions: .folder(AgentConfigPaths.opencodeAgentsMarkdownURL),
        skillDocFilename: "SKILL.md"
    )
}
```

**VERIFY**: `swift build`

---

### 1.6 Update AgentConfig.swift

**WHERE**: `Sources/AgentConfigManager/Models/AgentConfig.swift`

Replace with capabilities-based model, store colors as RGB (Sendable-safe):

```swift
import SwiftUI

struct AgentConfig: Identifiable, Hashable, Sendable {
    let id: AgentID
    let displayName: String
    let badgeColorRGB: (red: Double, green: Double, blue: Double)
    let capabilities: AgentCapabilities
    
    var badgeColor: Color {
        Color(red: badgeColorRGB.red, green: badgeColorRGB.green, blue: badgeColorRGB.blue)
    }

    var skillPlatform: SkillPlatform? {
        switch id {
        case .pi: return .pi
        case .claude: return .claude
        case .codex: return .codex
        case .opencode: return .opencode
        }
    }
    
    // Convenience accessors
    var skillsURL: URL? { capabilities.skills.folderURL }
    var extensionsURL: URL? { capabilities.extensions.folderURL }
    var pluginsURL: URL? { capabilities.plugins.folderURL }
    var hooksURL: URL? { capabilities.hooks.folderURL }
    var commandsURL: URL? { capabilities.commands.folderURL }
    var instructionsURL: URL? { capabilities.instructions.folderURL }
    
    func supports(_ section: NavigationSection) -> Bool {
        switch section {
        case .skills: return capabilities.skills.isSupported
        case .extensions: return capabilities.extensions.isSupported
        case .plugins: return capabilities.plugins.isSupported
        case .hooks: return capabilities.hooks.isSupported
        case .commands: return capabilities.commands.isSupported
        case .agentsmd: return capabilities.instructions.isSupported
        case .repos: return true  // Not agent-specific
        }
    }
    
    func supportMode(for section: NavigationSection) -> SupportMode {
        switch section {
        case .skills: return capabilities.skills
        case .extensions: return capabilities.extensions
        case .plugins: return capabilities.plugins
        case .hooks: return capabilities.hooks
        case .commands: return capabilities.commands
        case .agentsmd: return capabilities.instructions
        case .repos: return .none
        }
    }

    static let all: [AgentConfig] = [
        AgentConfig(
            id: .pi,
            displayName: "Pi Agent",
            badgeColorRGB: (0.0, 0.8, 0.0),  // Green
            capabilities: .pi
        ),
        AgentConfig(
            id: .claude,
            displayName: "Claude Code",
            badgeColorRGB: (217/255, 119/255, 87/255),  // Orange/coral
            capabilities: .claude
        ),
        AgentConfig(
            id: .codex,
            displayName: "Codex",
            badgeColorRGB: (164/255, 97/255, 212/255),  // Purple
            capabilities: .codex
        ),
        AgentConfig(
            id: .opencode,
            displayName: "OpenCode",
            badgeColorRGB: (76/255, 144/255, 226/255),  // Blue
            capabilities: .opencode
        ),
        // REMOVED: GitHub Copilot
    ]
    
    static func config(for id: AgentID) -> AgentConfig? {
        all.first { $0.id == id }
    }
}
```

**VERIFY**: `swift build`

---

## Phase 2: Refactor Sidebar — Status Indicators

### 2.1 Create AgentInstallStatus Model

**CREATE**: `Sources/AgentConfigManager/Models/AgentInstallStatus.swift`

```swift
import SwiftUI

struct AgentInstallStatus: Identifiable {
    let agent: AgentConfig
    let cliInstalled: Bool
    let configExists: Bool
    let hasContent: Bool
    
    var id: AgentID { agent.id }
    
    var statusIcon: String {
        if cliInstalled && hasContent { return "checkmark.circle.fill" }
        if cliInstalled && configExists { return "circle" }
        return "minus.circle"
    }
    
    var statusColor: Color {
        if cliInstalled && hasContent { return .green }
        if cliInstalled && configExists { return .secondary }
        return .secondary.opacity(0.5)
    }
    
    var statusDescription: String {
        if cliInstalled && hasContent { return "Configured" }
        if cliInstalled && configExists { return "Installed" }
        if cliInstalled { return "CLI only" }
        return "Not installed"
    }
}
```

**VERIFY**: `swift build`

---

### 2.2 Create AgentStatusStore

**CREATE**: `Sources/AgentConfigManager/Models/AgentStatusStore.swift`

```swift
import Foundation
import Observation

@Observable
@MainActor
final class AgentStatusStore {
    var statuses: [AgentInstallStatus] = []
    
    func load() async {
        var results: [AgentInstallStatus] = []
        
        for config in AgentConfig.all {
            let status = await Self.checkStatus(for: config)
            results.append(status)
        }
        
        statuses = results
    }
    
    /// Nonisolated helper to avoid Sendable capture issues
    private static func checkStatus(for config: AgentConfig) async -> AgentInstallStatus {
        let cliInstalled = await checkCLIExists(config.id.cliName)
        let configExists = checkConfigExists(for: config)
        let hasContent = checkHasContent(for: config)
        
        return AgentInstallStatus(
            agent: config,
            cliInstalled: cliInstalled,
            configExists: configExists,
            hasContent: hasContent
        )
    }
    
    private static func checkCLIExists(_ name: String) async -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = [name]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    private static func checkConfigExists(for config: AgentConfig) -> Bool {
        let fm = FileManager.default
        // Check if the root directory exists (parent of skills)
        if let skillsURL = config.skillsURL {
            return fm.fileExists(atPath: skillsURL.deletingLastPathComponent().path)
        }
        return false
    }
    
    private static func checkHasContent(for config: AgentConfig) -> Bool {
        let fm = FileManager.default
        
        // Check all content URLs
        for url in config.capabilities.contentURLs {
            if let contents = try? fm.contentsOfDirectory(atPath: url.path) {
                let hasNonHidden = contents.contains { !$0.hasPrefix(".") }
                if hasNonHidden { return true }
            }
        }
        
        return false
    }
}
```

**VERIFY**: `swift build`

---

### 2.3 Update NavigationSection

**WHERE**: `Sources/AgentConfigManager/Models/NavigationSection.swift`

```swift
enum NavigationSection: String, CaseIterable, Identifiable {
    case skills
    case extensions
    case plugins
    case hooks
    case commands
    case agentsmd
    case repos
    
    var id: String { rawValue }
    
    var name: String {
        switch self {
        case .skills: return "Skills"
        case .extensions: return "Extensions"
        case .plugins: return "Plugins"
        case .hooks: return "Hooks"
        case .commands: return "Commands"
        case .agentsmd: return "AGENTS.md"
        case .repos: return "Repos"
        }
    }
    
    var symbolName: String {
        switch self {
        case .skills: return "book.closed"
        case .extensions: return "puzzlepiece.extension"
        case .plugins: return "powerplug"
        case .hooks: return "arrow.triangle.branch"
        case .commands: return "terminal"
        case .agentsmd: return "doc.text"
        case .repos: return "folder"
        }
    }
    
    /// Which agents support this section
    var supportedAgentIDs: Set<AgentID> {
        Set(AgentConfig.all.filter { $0.supports(self) }.map(\.id))
    }
}
```

**VERIFY**: `swift build`

---

### 2.4 Update SidebarView — Status Indicators with Navigation

**WHERE**: `Sources/AgentConfigManager/Shared/SidebarView.swift`

Replace checkboxes with status rows that navigate to agent detail:

```swift
import SwiftUI

struct SidebarView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(AgentStatusStore.self) private var agentStatus

    var body: some View {
        @Bindable var appModel = appModel
        
        List(selection: $appModel.selectedSection) {
            Section("Sections") {
                ForEach(NavigationSection.allCases) { section in
                    Label(section.name, systemImage: section.symbolName)
                        .tag(section)
                }
            }

            Section("Installed Agents") {
                ForEach(agentStatus.statuses) { status in
                    Button {
                        appModel.selectedAgentForDetail = status.agent.id
                    } label: {
                        AgentStatusRow(status: status)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .listStyle(.sidebar)
        .task {
            await agentStatus.load()
        }
    }
}

private struct AgentStatusRow: View {
    let status: AgentInstallStatus
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(status.agent.badgeColor)
                .frame(width: 8, height: 8)
            
            Text(status.agent.displayName)
            
            Spacer()
            
            Image(systemName: status.statusIcon)
                .foregroundStyle(status.statusColor)
                .font(.caption)
        }
    }
}
```

**VERIFY**: `swift build`

---

## Phase 3: Add Missing Sections

### 3.1 Create PluginsContentView

**CREATE**: `Sources/AgentConfigManager/Plugins/PluginsContentView.swift`

```swift
import SwiftUI

struct PluginsContentView: View {
    var body: some View {
        List {
            // Claude plugins (JSON format)
            if let claudeConfig = AgentConfig.config(for: .claude) {
                Section {
                    if let pluginsURL = claudeConfig.pluginsURL {
                        Text(pluginsURL.path.replacingOccurrences(
                            of: FileManager.default.homeDirectoryForCurrentUser.path,
                            with: "~"
                        ))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    Text("Plugin format: JSON (.claude-plugin/plugin.json)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    // TODO: List actual plugins from ~/.claude/plugins/
                } header: {
                    HStack {
                        Circle().fill(claudeConfig.badgeColor)
                            .frame(width: 8, height: 8)
                        Text("Claude Code")
                    }
                }
            }
            
            // OpenCode plugins (TypeScript format)
            if let opencodeConfig = AgentConfig.config(for: .opencode) {
                Section {
                    if let pluginsURL = opencodeConfig.pluginsURL {
                        Text(pluginsURL.path.replacingOccurrences(
                            of: FileManager.default.homeDirectoryForCurrentUser.path,
                            with: "~"
                        ))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    Text("Plugin format: TypeScript/JavaScript")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    // TODO: List actual plugins from ~/.config/opencode/plugin/
                } header: {
                    HStack {
                        Circle().fill(opencodeConfig.badgeColor)
                            .frame(width: 8, height: 8)
                        Text("OpenCode")
                    }
                }
            }
            
            // Agents that don't support plugins
            Section {
                ForEach([AgentID.pi, .codex], id: \.self) { agentID in
                    if let config = AgentConfig.config(for: agentID) {
                        HStack {
                            Circle().fill(config.badgeColor)
                                .frame(width: 8, height: 8)
                            Text(config.displayName)
                            Spacer()
                            Text("Not supported")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Text("Not Available")
            }
        }
        .listStyle(.sidebar)
    }
}
```

**VERIFY**: `swift build`

---

### 3.2 Create PluginsDetailView

**CREATE**: `Sources/AgentConfigManager/Plugins/PluginsDetailView.swift`

```swift
import SwiftUI

struct PluginsDetailView: View {
    var body: some View {
        ContentUnavailableView(
            "Select a Plugin",
            systemImage: "powerplug",
            description: Text("Choose a plugin from the list to view details")
        )
    }
}
```

**VERIFY**: `swift build`

---

### 3.3 Create HooksContentView

**CREATE**: `Sources/AgentConfigManager/Hooks/HooksContentView.swift`

```swift
import SwiftUI

struct HooksContentView: View {
    var body: some View {
        List {
            // Claude - folder-backed hooks
            if let claudeConfig = AgentConfig.config(for: .claude) {
                Section {
                    if let hooksURL = claudeConfig.hooksURL {
                        Text(hooksURL.path.replacingOccurrences(
                            of: FileManager.default.homeDirectoryForCurrentUser.path,
                            with: "~"
                        ))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    Text("Configured in settings.json")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Text("Hook types: PreToolUse, PostToolUse, SessionStart, SessionEnd, etc.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    // TODO: List actual hooks from ~/.claude/hooks/
                } header: {
                    HStack {
                        Circle().fill(claudeConfig.badgeColor)
                            .frame(width: 8, height: 8)
                        Text("Claude Code")
                        Spacer()
                        Text("Folder")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Pi Agent - hooks via extensions
            if let piConfig = AgentConfig.config(for: .pi) {
                Section {
                    Text("Hooks are lifecycle events in extensions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Use: pi.on('event', handler)")
                        .font(.caption.monospaced())
                        .foregroundStyle(.tertiary)
                    Text("Events: session_start, tool_call, tool_result, turn_start, etc.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                } header: {
                    HStack {
                        Circle().fill(piConfig.badgeColor)
                            .frame(width: 8, height: 8)
                        Text("Pi Agent")
                        Spacer()
                        Text("Via Extensions")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // OpenCode - hooks via plugins
            if let opencodeConfig = AgentConfig.config(for: .opencode) {
                Section {
                    Text("Hooks are exported from plugin modules")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Export: { 'tool.execute.before': async (...) => { } }")
                        .font(.caption.monospaced())
                        .foregroundStyle(.tertiary)
                } header: {
                    HStack {
                        Circle().fill(opencodeConfig.badgeColor)
                            .frame(width: 8, height: 8)
                        Text("OpenCode")
                        Spacer()
                        Text("Via Plugins")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Codex - no hooks
            if let codexConfig = AgentConfig.config(for: .codex) {
                Section {
                    ContentUnavailableView(
                        "Not Supported",
                        systemImage: "xmark.circle",
                        description: Text("Codex does not support hooks (feature requested)")
                    )
                } header: {
                    HStack {
                        Circle().fill(codexConfig.badgeColor)
                            .frame(width: 8, height: 8)
                        Text("Codex")
                    }
                }
            }
        }
        .listStyle(.sidebar)
    }
}
```

**VERIFY**: `swift build`

---

### 3.4 Create HooksDetailView

**CREATE**: `Sources/AgentConfigManager/Hooks/HooksDetailView.swift`

```swift
import SwiftUI

struct HooksDetailView: View {
    var body: some View {
        ContentUnavailableView(
            "Select a Hook",
            systemImage: "arrow.triangle.branch",
            description: Text("Choose a hook from the list to view details")
        )
    }
}
```

**VERIFY**: `swift build`

---

### 3.5 Create AgentDetailView

**CREATE**: `Sources/AgentConfigManager/Agents/AgentDetailView.swift`

```swift
import SwiftUI
import AppKit

struct AgentDetailView: View {
    let agent: AgentConfig
    
    var body: some View {
        Form {
            Section("Paths") {
                if let url = agent.skillsURL {
                    PathRow(label: "Skills", url: url)
                }
                if let url = agent.extensionsURL {
                    PathRow(label: "Extensions", url: url)
                }
                if let url = agent.pluginsURL {
                    PathRow(label: "Plugins", url: url)
                }
                if let url = agent.hooksURL {
                    PathRow(label: "Hooks", url: url)
                }
                if let url = agent.commandsURL {
                    PathRow(label: "Commands", url: url)
                }
                if let url = agent.instructionsURL {
                    PathRow(label: "Instructions", url: url)
                }
            }
            
            Section("Capabilities") {
                CapabilityRow("Skills", mode: agent.capabilities.skills)
                CapabilityRow("Extensions", mode: agent.capabilities.extensions)
                CapabilityRow("Plugins", mode: agent.capabilities.plugins)
                CapabilityRow("Hooks", mode: agent.capabilities.hooks)
                CapabilityRow("Commands", mode: agent.capabilities.commands)
            }
            
            Section("Skill Documentation") {
                LabeledContent("Filename") {
                    Text(agent.capabilities.skillDocFilename)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(agent.displayName)
    }
}

private struct PathRow: View {
    let label: String
    let url: URL
    
    private var displayPath: String {
        url.path.replacingOccurrences(
            of: FileManager.default.homeDirectoryForCurrentUser.path,
            with: "~"
        )
    }
    
    var body: some View {
        LabeledContent(label) {
            HStack {
                Text(displayPath)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                Button {
                    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
                } label: {
                    Image(systemName: "folder")
                }
                .buttonStyle(.borderless)
            }
        }
    }
}

private struct CapabilityRow: View {
    let name: String
    let mode: SupportMode
    
    init(_ name: String, mode: SupportMode) {
        self.name = name
        self.mode = mode
    }
    
    var body: some View {
        LabeledContent(name) {
            HStack(spacing: 4) {
                if mode.isSupported {
                    Text(mode.displayDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Image(systemName: mode.isSupported ? "checkmark.circle.fill" : "xmark.circle")
                    .foregroundStyle(mode.isSupported ? .green : .secondary)
            }
        }
    }
}
```

**VERIFY**: `swift build`

---

## Phase 4: Wire Up Navigation and Stores

### 4.1 Update AppModel — Add agent detail selection and status store

**WHERE**: `Sources/AgentConfigManager/Models/AppModel.swift`

Add:

```swift
// Add to AppModel properties:
var selectedAgentForDetail: AgentID? = nil

// Note: AgentStatusStore will be injected via environment, not owned by AppModel
```

Also remove any `selectedAgents: Set<AgentID>` filtering logic since we're removing filtering.

**VERIFY**: `swift build`

---

### 4.2 Update MainSplitView — Route new sections + agent detail

**WHERE**: `Sources/AgentConfigManager/Shared/MainSplitView.swift`

```swift
import SwiftUI

struct MainSplitView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        NavigationSplitView {
            SidebarView()
        } content: {
            contentView(for: appModel.selectedSection)
        } detail: {
            detailView()
        }
        .sheet(item: agentDetailBinding) { agentID in
            if let config = AgentConfig.config(for: agentID) {
                NavigationStack {
                    AgentDetailView(agent: config)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") {
                                    appModel.selectedAgentForDetail = nil
                                }
                            }
                        }
                }
            }
        }
    }
    
    private var agentDetailBinding: Binding<AgentID?> {
        Binding(
            get: { appModel.selectedAgentForDetail },
            set: { appModel.selectedAgentForDetail = $0 }
        )
    }

    @ViewBuilder
    private func contentView(for section: NavigationSection) -> some View {
        switch section {
        case .skills:
            SkillsSectionContentView()
        case .extensions:
            ExtensionsContentView()
        case .plugins:
            PluginsContentView()
        case .hooks:
            HooksContentView()
        case .commands:
            CommandsContentView()
        case .agentsmd:
            AgentsMdContentView()
        case .repos:
            ReposContentView()
        }
    }

    @ViewBuilder
    private func detailView() -> some View {
        switch appModel.selectedSection {
        case .skills:
            SkillsSectionDetailView()
        case .extensions:
            ExtensionsDetailView()
        case .plugins:
            PluginsDetailView()
        case .hooks:
            HooksDetailView()
        case .commands:
            CommandsDetailView()
        case .agentsmd:
            AgentsMdDetailView()
        case .repos:
            ReposDetailView()
        }
    }
}

// Make AgentID conform to Identifiable for sheet(item:)
extension AgentID: Identifiable {
    var id: String { rawValue }
}
```

**VERIFY**: `swift build`

---

### 4.3 Update AgentConfigManagerApp — Inject AgentStatusStore

**WHERE**: `Sources/AgentConfigManager/App/AgentConfigManagerApp.swift`

Add environment injection for the new store:

```swift
@main
struct AgentConfigManagerApp: App {
    @State private var appModel: AppModel
    @State private var agentStatusStore = AgentStatusStore()
    
    // ... existing init ...
    
    var body: some Scene {
        WindowGroup {
            MainSplitView()
                .environment(appModel)
                .environment(appModel.skillStore)
                .environment(appModel.remoteSkillStore)
                .environment(appModel.extensionStore)
                .environment(appModel.commandStore)
                .environment(appModel.agentsMdStore)
                .environment(appModel.repoStore)
                .environment(appModel.settings)
                .environment(agentStatusStore)  // NEW
        }
    }
}
```

**VERIFY**: `swift build`

---

### 4.4 Update SettingsStore — Remove selectedAgents (filtering removed)

**WHERE**: `Sources/AgentConfigManager/Models/SettingsStore.swift`

Remove the `selectedAgents` property and related persistence code since filtering is replaced with status indicators.

**VERIFY**: `swift build`

---

## Summary

### Files to Create (9)

| File | Purpose |
|------|---------|
| `Models/SupportMode.swift` | Enum for capability support modes |
| `Models/AgentCapabilities.swift` | Struct defining agent capabilities |
| `Models/AgentInstallStatus.swift` | Model for agent installation status |
| `Models/AgentStatusStore.swift` | Store for checking agent install status |
| `Plugins/PluginsContentView.swift` | List Claude + OpenCode plugins |
| `Plugins/PluginsDetailView.swift` | Plugin detail placeholder |
| `Hooks/HooksContentView.swift` | List hooks by agent with support mode |
| `Hooks/HooksDetailView.swift` | Hook detail placeholder |
| `Agents/AgentDetailView.swift` | Agent configuration overview |

### Files to Modify (8)

| File | Changes |
|------|---------|
| `AgentConfigPaths.swift` | Fix all paths, add resolution helpers |
| `AgentID.swift` | Remove `.copilot`, add `cliName` |
| `SkillPlatform.swift` | Fix paths, remove Copilot |
| `AgentConfig.swift` | Capabilities-based model, RGB colors |
| `NavigationSection.swift` | Add `.plugins`, `.hooks` |
| `SidebarView.swift` | Status indicators replacing checkboxes |
| `MainSplitView.swift` | Route new sections, agent detail sheet |
| `AgentConfigManagerApp.swift` | Inject AgentStatusStore |
| `SettingsStore.swift` | Remove selectedAgents |
| `AppModel.swift` | Add selectedAgentForDetail, remove filtering |

### Directories to Create (3)

- `Sources/AgentConfigManager/Plugins/`
- `Sources/AgentConfigManager/Hooks/`
- `Sources/AgentConfigManager/Agents/`

---

## Task Checklist

### Phase 0: Setup
- [ ] 0.1 Create directories (Plugins/, Hooks/, Agents/)

### Phase 1: Fix Paths & Models
- [ ] 1.1 Update AgentConfigPaths.swift
- [ ] 1.2 Update AgentID.swift — remove Copilot
- [ ] 1.3 Update SkillPlatform.swift — fix paths, remove Copilot
- [ ] 1.4 Create SupportMode.swift
- [ ] 1.5 Create AgentCapabilities.swift
- [ ] 1.6 Update AgentConfig.swift

### Phase 2: Sidebar Refactor
- [ ] 2.1 Create AgentInstallStatus.swift
- [ ] 2.2 Create AgentStatusStore.swift
- [ ] 2.3 Update NavigationSection.swift
- [ ] 2.4 Update SidebarView.swift

### Phase 3: New Sections
- [ ] 3.1 Create PluginsContentView.swift
- [ ] 3.2 Create PluginsDetailView.swift
- [ ] 3.3 Create HooksContentView.swift
- [ ] 3.4 Create HooksDetailView.swift
- [ ] 3.5 Create AgentDetailView.swift

### Phase 4: Wire Up
- [ ] 4.1 Update AppModel.swift
- [ ] 4.2 Update MainSplitView.swift
- [ ] 4.3 Update AgentConfigManagerApp.swift
- [ ] 4.4 Update SettingsStore.swift

Each task ends with `swift build` verification.

---

## YOLO-Safety Checklist

- [x] All new files have correct imports (SwiftUI, AppKit, Foundation)
- [x] Color stored as RGB tuple (Sendable-safe)
- [x] AgentStatusStore uses static helpers (avoids Sendable capture)
- [x] No forced unwraps — use safe `AgentConfig.config(for:)` helper
- [x] Path resolution with fallbacks for singular/plural variations
- [x] Directories created before file creation
- [x] Environment injection specified explicitly
- [x] Filtering behavior explicitly removed (not silently broken)

---

## Plan Status: READY FOR EXECUTION ✅
