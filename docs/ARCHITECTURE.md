# Agent Config Manager — Architecture

> Evolving CodexSkillManager into a unified manager for AI coding agent configuration

## Vision

A single macOS app to manage **skills**, **extensions**, **commands**, and **AGENTS.md** files across all major AI coding agents.

---

## Current State (CodexSkillManager)

```
Skills Only
├── Codex        ~/.codex/skills/public
├── Claude Code  ~/.claude/skills  
├── OpenCode     ~/.config/opencode/skill
└── Copilot      ~/.copilot/skills
```

**Features:** List, view SKILL.md, install from Clawdhub, publish to Clawdhub

---

## Proposed Architecture

### 1. Agent Registry

Unified model for all agents and their configuration locations:

```swift
struct AgentConfig: Identifiable {
    let id: String              // "pi", "claude", "codex", "opencode", "copilot"
    let displayName: String     // "Pi Agent", "Claude Code", etc.
    let badgeColor: Color
    
    // Locations (nil if agent doesn't support this concept)
    let skillsPath: String?
    let extensionsPath: String?   // Pi Agent only
    let commandsPath: String?
    let agentsmdPath: String?     // Global AGENTS.md location
}

// Registry
static let agents: [AgentConfig] = [
    AgentConfig(
        id: "pi",
        displayName: "Pi Agent",
        badgeColor: .green,
        skillsPath: "~/.pi/agent/skills",
        extensionsPath: "~/.pi/agent/extensions",
        commandsPath: "~/.pi/agent/prompts",
        agentsmdPath: "~/.pi/agent/AGENTS.md"
    ),
    AgentConfig(
        id: "claude",
        displayName: "Claude Code",
        badgeColor: .orange,
        skillsPath: "~/.claude/skills",
        extensionsPath: nil,
        commandsPath: "~/.claude/commands",
        agentsmdPath: "~/.claude/CLAUDE.md"
    ),
    AgentConfig(
        id: "codex",
        displayName: "Codex",
        badgeColor: .purple,
        skillsPath: "~/.codex/skills/public",
        extensionsPath: nil,
        commandsPath: "~/.codex/prompts",
        agentsmdPath: "~/.codex/AGENTS.md"
    ),
    AgentConfig(
        id: "opencode",
        displayName: "OpenCode",
        badgeColor: .blue,
        skillsPath: "~/.config/opencode/skill",
        extensionsPath: nil,
        commandsPath: "~/.config/opencode/commands",
        agentsmdPath: nil  // Project-level only
    ),
    AgentConfig(
        id: "copilot",
        displayName: "GitHub Copilot",
        badgeColor: .cyan,
        skillsPath: "~/.copilot/skills",
        extensionsPath: nil,
        commandsPath: nil,
        agentsmdPath: nil
    )
]
```

### 2. Content Types

```swift
enum ContentType: String, CaseIterable {
    case skill      // SKILL.md - instructions for specific tasks
    case extension  // TypeScript code that adds tools/commands (Pi Agent only)
    case command    // Slash commands (/handoff, /checkpoint)
    case agentsmd   // AGENTS.md/CLAUDE.md global config
}

// What each agent supports
extension AgentConfig {
    var supportedTypes: Set<ContentType> {
        var types: Set<ContentType> = []
        if skillsPath != nil { types.insert(.skill) }
        if extensionsPath != nil { types.insert(.extension) }
        if commandsPath != nil { types.insert(.command) }
        if agentsmdPath != nil { types.insert(.agentsmd) }
        return types
    }
}
```

### 3. App Structure (Tabs)

```
┌─────────────────────────────────────────────────────────────┐
│  [Skills]  [Extensions]  [Commands]  [AGENTS.md]  [Repos]   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Sidebar          │  Detail                                 │
│  ─────────────    │  ──────────────────────────────────     │
│  🟢 Pi Agent      │                                         │
│  🟠 Claude Code   │  Markdown preview / Code view           │
│  🟣 Codex         │                                         │
│  🔵 OpenCode      │                                         │
│  🔷 Copilot       │                                         │
│                   │                                         │
│  [+ Install]      │  [Edit] [Delete] [Publish]              │
│                   │                                         │
└─────────────────────────────────────────────────────────────┘
```

---

## Feature Breakdown

### Tab 1: Skills (Current + Pi Agent)

**What exists:** Current CodexSkillManager functionality

**Add:**
- Pi Agent support (`~/.pi/agent/skills`)
- Show which agents a skill is installed for (badge pills)
- Cross-install: install same skill to multiple agents

**Data Model:**
```swift
struct Skill: Identifiable {
    let id: String
    let slug: String
    let displayName: String
    let description: String
    let installedAgents: Set<String>  // ["pi", "claude", "codex"]
    let folderURL: URL
    let skillMarkdownURL: URL
}
```

### Tab 2: Extensions (Pi Agent Only)

**New feature:** Manage pi-agent extensions

Pi Agent extensions are TypeScript modules that add tools and commands. They live in `~/.pi/agent/extensions/` and are NOT shared with other agents.

**Features:**
- List extensions in `~/.pi/agent/extensions/`
- View TypeScript code with syntax highlighting
- Show which tools/commands an extension provides (parse exports)
- Enable/disable extensions (rename to `.disabled`)
- Link to extension documentation

**Data Model:**
```swift
struct Extension: Identifiable {
    let id: String
    let name: String
    let folderURL: URL
    let entryPoint: URL             // index.ts
    let providedTools: [String]     // Parsed from registerTool() calls
    let providedCommands: [String]  // Parsed from registerCommand() calls
    let isEnabled: Bool
}
```

**Parsing tools/commands (simple regex):**
```swift
// Find: pi.registerTool({ name: "greet", ...
// Find: pi.registerCommand("hello", ...
let toolPattern = /registerTool\(\s*\{\s*name:\s*["']([^"']+)["']/
let commandPattern = /registerCommand\(\s*["']([^"']+)["']/
```

### Tab 3: Commands (Slash Commands)

**New feature:** Manage slash commands across agents

**Features:**
- List commands from each agent's command directory
- View command markdown
- Show which agents share commands (via symlinks to central location)
- Create new commands
- Sync commands across agents

**Data Model:**
```swift
struct Command: Identifiable {
    let id: String
    let name: String          // "handoff", "checkpoint"
    let installedAgents: Set<String>
    let fileURL: URL
    let isSymlink: Bool
    let symlinkTarget: URL?   // If symlinked to shared location
}
```

### Tab 4: AGENTS.md (Global Config)

**New feature:** Manage global agent instructions

**Features:**
- View/edit the central `~/.agent-config/AGENTS.md`
- Show symlink status for each agent (all should point to central)
- Quick action: "Fix symlinks" - point any broken/missing to central config
- Syntax highlighted markdown editing

**Data Model:**
```swift
struct AgentInstructions: Identifiable {
    let id: String            // Agent ID
    let agent: AgentConfig
    let expectedPath: URL     // Where symlink should be
    let isSymlink: Bool
    let symlinkTarget: URL?   // What it points to
    let pointsToCentral: Bool // Does it point to ~/.agent-config/AGENTS.md?
}
```

### Tab 5: Repos (Project AGENTS.md)

**New feature:** Manage project-level AGENTS.md files

**How it works:**
- Agents load BOTH global (`~/.agent-config/AGENTS.md`) AND project (`./AGENTS.md`)
- Global has shared content (North Star, gj tool, code philosophy)
- Project has only project-specific content (structure, components, conventions)
- No "see also" needed - agents combine them automatically

**Features:**
- Configure watched directories (e.g., `~/dev/`)
- Scan for repos with AGENTS.md
- Detect bloated files (containing duplicate global content)
- Show file size and content summary
- Help trim to project-specific only
- Preview/edit project AGENTS.md

**Data Model:**
```swift
struct RepoConfig: Identifiable {
    let id: String
    let name: String
    let path: URL
    let agentsmdPath: URL?
    let fileSize: Int
    let containsGlobalContent: Bool  // Has North Star, gj tool, etc.
    let lastModified: Date?
}

struct RepoSettings: Codable {
    var watchedDirectories: [URL]   // e.g., [~/dev/]
}
```

**Detection of bloated files:**
```swift
func containsGlobalContent(_ content: String) -> Bool {
    let globalMarkers = [
        "North Star",
        "Modern Apple Development",
        "gj run",
        "Code Philosophy",
        "Chief Visioneer"
    ]
    return globalMarkers.filter { content.contains($0) }.count >= 2
}
```

---

## Consolidated Shared Config

### Target Structure

```
~/.agent-config/                      # Central hub (git repo)
├── AGENTS.md                         # Global instructions (THE source of truth)
├── commands/                         # Slash commands
│   ├── handoff.md
│   ├── checkpoint.md
│   ├── commit.md
│   └── ...
├── docs/                             # Tool documentation
│   ├── gj-tool.md
│   └── ui-automation.md
└── knowledge/                        # Shared knowledge files
    └── swift-patterns.md
```

### Agent Symlinks (Managed by App)

```
~/.pi/agent/AGENTS.md      → ~/.agent-config/AGENTS.md
~/.pi/agent/prompts        → ~/.agent-config/commands
~/.claude/CLAUDE.md        → ~/.agent-config/AGENTS.md
~/.claude/commands         → ~/.agent-config/commands
~/.codex/AGENTS.md         → ~/.agent-config/AGENTS.md
~/.codex/prompts           → ~/.agent-config/commands
```

### Project AGENTS.md (Minimal)

Each project has only project-specific content:

```markdown
# GrooveTech Media Server

macOS app serving synchronized video to AVP headsets. SwiftNIO HTTP + Bonjour discovery.

## Project Structure

groovetech-media-server/
├── GrooveTech Media Server/       # Main macOS app (SwiftUI)
├── GrooveTechMediaServerStarter/  # Swift package: HTTP server, Bonjour
└── docs/                          # Documentation

## Key Components

| Component | Purpose |
|-----------|---------|
| MediaLibraryState | Main view model (@Observable) |
| MediaHTTPServer | SwiftNIO HTTP on port 8080 |
| BonjourService | Auto-discovery for AVP headsets |

## Build

gj run ms
```

No North Star, no gj tool reference, no code philosophy - that's all in the global config.

---

## Migration: ~/dev/opencode-config → ~/.agent-config

The existing `~/dev/opencode-config` content should be merged into `~/.agent-config`:

| Source | Destination |
|--------|-------------|
| `opencode-config/AGENTS.md` | `~/.agent-config/AGENTS.md` |
| `opencode-config/commands/` | `~/.agent-config/commands/` |
| `opencode-config/knowledge/` | `~/.agent-config/knowledge/` |

After migration, `~/dev/opencode-config` can be archived or deleted.

---

## Implementation Phases

### Phase 1: Add Pi Agent Skills (1 hour)
- Add `pi` to `SkillPlatform` enum
- Path: `~/.pi/agent/skills`
- Badge color: green
- Test install/uninstall

### Phase 2: Extensions Tab (1-2 days)
- New `Extension` model
- `ExtensionStore` to scan `~/.pi/agent/extensions`
- `ExtensionListView` and `ExtensionDetailView`
- TypeScript syntax highlighting
- Parse tools/commands from source

### Phase 3: Commands Tab (1 day)
- New `Command` model
- `CommandStore` to scan all agent command directories
- Show symlink relationships
- Cross-agent sync feature

### Phase 4: AGENTS.md Tab (1 day)
- New `AgentInstructions` model
- View/edit central config
- Symlink status for each agent
- "Fix symlinks" quick action

### Phase 5: Repos Tab (2 days)
- `RepoStore` to scan configured directories
- Detect AGENTS.md files
- Identify bloated vs minimal files
- Help trim duplicated content
- Settings for watched directories

### Phase 6: Rename & Polish (1 day)
- Rename to "Agent Config Manager"
- Update bundle ID, app icon
- Update window title
- Update README

---

## File Structure

```
Sources/AgentConfigManager/
├── App/
│   └── AgentConfigManagerApp.swift
├── Models/
│   ├── AgentConfig.swift           # Agent registry
│   ├── ContentType.swift           # skill/extension/command/agentsmd
│   ├── Skill.swift                 # (existing)
│   ├── Extension.swift             # NEW
│   ├── Command.swift               # NEW
│   ├── AgentInstructions.swift     # NEW
│   └── RepoConfig.swift            # NEW
├── Stores/
│   ├── SkillStore.swift            # (existing)
│   ├── ExtensionStore.swift        # NEW
│   ├── CommandStore.swift          # NEW
│   ├── InstructionsStore.swift     # NEW
│   └── RepoStore.swift             # NEW
├── Workers/
│   ├── SkillFileWorker.swift       # (existing)
│   ├── ExtensionFileWorker.swift   # NEW
│   └── RepoScanWorker.swift        # NEW
├── Views/
│   ├── MainTabView.swift           # NEW - tab container
│   ├── Skills/                     # (existing, reorganized)
│   ├── Extensions/                 # NEW
│   ├── Commands/                   # NEW
│   ├── Instructions/               # NEW
│   └── Repos/                      # NEW
└── Shared/
    ├── MarkdownView.swift
    ├── CodeView.swift              # NEW - TypeScript highlighting
    └── BadgeView.swift
```

---

## Summary

| Phase | Scope | Effort |
|-------|-------|--------|
| 1 | Pi Agent skills | 1 hour |
| 2 | Extensions tab | 1-2 days |
| 3 | Commands tab | 1 day |
| 4 | AGENTS.md tab | 1 day |
| 5 | Repos tab | 2 days |
| 6 | Rename & polish | 1 day |

**Total: ~7-8 days for full implementation**

Quick win: Phase 1 alone adds pi-agent support immediately.
