# Agent Config Manager — Design Document

## Interview Summary (Jan 9, 2026)

| Question | Response |
|----------|----------|
| **Tab Structure** | Sidebar sections like Landmarks app (NavigationSplitView) |
| **Priority** | Full plan: All 6 phases (~7-8 days) |
| **Config Migration** | Yes, add a migration wizard |
| **Symlink Management** | Wizard + auto-fix (must be VERY clear to user) |
| **Repo Scanning** | Both: Default ~/dev/ + configurable |
| **Dev Path** | `~/dev` (symlink to Dropbox path) |
| **Extension Features** | ALL: List, view source, show tools/commands, enable/disable, open in editor, link to docs |
| **App Icon** | Yes, design new icon |
| **Acceptance** | Careful use and testing |
| **Constraints** | Auto work must be VERY clear to user what's happening |

---

## Navigation Structure

Following the Landmarks app pattern (NavigationSplitView with sidebar sections):

```swift
enum NavigationSection: String, CaseIterable, Identifiable {
    case skills       // Existing functionality + Pi Agent
    case extensions   // Pi Agent only
    case commands     // Slash commands
    case agentsmd     // Global AGENTS.md
    case repos        // Project AGENTS.md files
    
    var id: String { rawValue }
    
    var name: String {
        switch self {
        case .skills: "Skills"
        case .extensions: "Extensions"
        case .commands: "Commands"
        case .agentsmd: "AGENTS.md"
        case .repos: "Repos"
        }
    }
    
    var symbolName: String {
        switch self {
        case .skills: "book.closed"
        case .extensions: "puzzlepiece.extension"
        case .commands: "terminal"
        case .agentsmd: "doc.text"
        case .repos: "folder"
        }
    }
}
```

### UI Layout

```
┌──────────────────────────────────────────────────────────────────┐
│  Agent Config Manager                              􀈭 􀍟 􀣌      │
├────────────────┬─────────────────────────────────────────────────┤
│                │                                                 │
│  SECTIONS      │  CONTENT                                        │
│  ──────────    │                                                 │
│  􀉚 Skills     │  [Skill list or detail view based on section]  │
│  􀤆 Extensions │                                                 │
│  􀩼 Commands   │                                                 │
│  􀈷 AGENTS.md  │                                                 │
│  􀈕 Repos      │                                                 │
│                │                                                 │
│  ──────────    │                                                 │
│  AGENTS        │                                                 │
│  (filter)      │                                                 │
│  ──────────    │                                                 │
│  🟢 Pi Agent   │                                                 │
│  🟠 Claude     │                                                 │
│  🟣 Codex      │                                                 │
│  🔵 OpenCode   │                                                 │
│  🔷 Copilot    │                                                 │
│                │                                                 │
└────────────────┴─────────────────────────────────────────────────┘
```

---

## New Files to Create

### Models
| File | Purpose |
|------|---------|
| `NavigationSection.swift` | Sidebar section enum |
| `AgentConfig.swift` | Agent registry with paths |
| `Extension.swift` | Pi Agent extension model |
| `Command.swift` | Slash command model |
| `AgentInstructions.swift` | Global AGENTS.md model |
| `RepoConfig.swift` | Project repo model |
| `AppSettings.swift` | User preferences (watched dirs, etc.) |

### Stores
| File | Purpose |
|------|---------|
| `ExtensionStore.swift` | Load/manage Pi Agent extensions |
| `CommandStore.swift` | Load/manage slash commands |
| `InstructionsStore.swift` | Load/manage global AGENTS.md |
| `RepoStore.swift` | Scan/manage project repos |
| `SettingsStore.swift` | User preferences persistence |

### Workers
| File | Purpose |
|------|---------|
| `ExtensionFileWorker.swift` | Scan extensions, parse tools |
| `RepoScanWorker.swift` | Scan directories for repos |
| `SymlinkWorker.swift` | Create/verify/repair symlinks |
| `MigrationWorker.swift` | Migrate opencode-config → agent-config |

### Views
| File | Purpose |
|------|---------|
| `MainSplitView.swift` | Replace SkillSplitView, add sections |
| `Extensions/ExtensionListView.swift` | List Pi Agent extensions |
| `Extensions/ExtensionDetailView.swift` | View extension source/info |
| `Commands/CommandListView.swift` | List slash commands |
| `Commands/CommandDetailView.swift` | View command markdown |
| `Instructions/InstructionsView.swift` | Global AGENTS.md editor |
| `Instructions/AgentSymlinkStatusView.swift` | Show symlink status per agent |
| `Repos/RepoListView.swift` | List scanned repos |
| `Repos/RepoDetailView.swift` | View/edit project AGENTS.md |
| `Repos/RepoSettingsView.swift` | Configure watched directories |
| `Wizards/MigrationWizardView.swift` | Migrate config wizard |
| `Wizards/SymlinkWizardView.swift` | Setup symlinks wizard |
| `Shared/CodeView.swift` | TypeScript syntax highlighting |
| `Shared/ConfirmationOverlay.swift` | Clear confirmation for auto actions |

---

## Files to Modify

| File | Changes |
|------|---------|
| `CodexSkillManagerApp.swift` | Rename to AgentConfigManagerApp, add stores, change window title |
| `SkillPlatform.swift` | Add `.pi` case for Pi Agent |
| `SkillSplitView.swift` | Refactor into MainSplitView with sections |
| `Package.swift` | Rename target to AgentConfigManager |

---

## Migration Wizard Flow

**Triggered:** On first launch if `~/dev/opencode-config` exists but `~/.agent-config` doesn't have all content.

```
┌─────────────────────────────────────────────────────────────┐
│  Migration Wizard                                    Step 1/3│
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  We found configuration in two places:                      │
│                                                             │
│  📁 ~/dev/opencode-config/                                  │
│     • AGENTS.md                                             │
│     • commands/ (27 files)                                  │
│     • knowledge/ (5 files)                                  │
│                                                             │
│  📁 ~/.agent-config/                                        │
│     • commands/ (symlinked)                                 │
│     • instructions/AGENTS.md                                │
│                                                             │
│  ⚠️  These should be consolidated.                          │
│                                                             │
│  [What will happen:]                                        │
│  • Copy missing files to ~/.agent-config/                   │
│  • Update symlinks to point to ~/.agent-config/             │
│  • Keep ~/dev/opencode-config/ as backup                    │
│                                                             │
│                              [Skip]  [Review Changes] [Next]│
└─────────────────────────────────────────────────────────────┘
```

**Key constraint:** VERY clear about what's happening at every step.

---

## Symlink Wizard Flow

**Triggered:** First launch (after migration) or when "Setup Symlinks" clicked.

```
┌─────────────────────────────────────────────────────────────┐
│  Symlink Setup                                       Step 2/3│
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Agent symlinks point each agent to the central config.     │
│                                                             │
│  Current Status:                                            │
│                                                             │
│  🟢 Pi Agent                                                │
│     ~/.pi/agent/AGENTS.md → ~/.agent-config/AGENTS.md   ✓   │
│     ~/.pi/agent/prompts → ~/.agent-config/commands      ✓   │
│                                                             │
│  🟠 Claude Code                                             │
│     ~/.claude/CLAUDE.md → (missing)                     ✗   │
│     ~/.claude/commands → ~/.agent-config/commands       ✓   │
│                                                             │
│  🟣 Codex                                                   │
│     ~/.codex/AGENTS.md → (standalone file)              ⚠️  │
│     ~/.codex/prompts → ~/.agent-config/commands         ✓   │
│                                                             │
│  [What will happen:]                                        │
│  • Create symlink: ~/.claude/CLAUDE.md                      │
│  • Replace file with symlink: ~/.codex/AGENTS.md            │
│    (backup created at ~/.codex/AGENTS.md.backup)            │
│                                                             │
│                               [Skip]  [Fix Selected]  [Fix All]│
└─────────────────────────────────────────────────────────────┘
```

---

## Extension Detail View

```
┌─────────────────────────────────────────────────────────────┐
│  interview                                      [Open in VS Code]│
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  📍 ~/.pi/agent/extensions/interview/                       │
│                                                             │
│  PROVIDES                                                   │
│  ─────────                                                  │
│  Tools:     pi_interview                                    │
│  Commands:  (none)                                          │
│                                                             │
│  STATUS                                                     │
│  ─────────                                                  │
│  ● Enabled                              [Disable Extension] │
│                                                             │
│  FILES                                                      │
│  ─────────                                                  │
│  index.ts (11 KB)                                           │
│  schema.ts (4 KB)                                           │
│  server.ts (22 KB)                                          │
│  form/ (web UI)                                             │
│                                                             │
│  📖 Pi Agent Extension Docs                                 │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│  index.ts                                                   │
│  ─────────────────────────────────────────────────────────  │
│  import { Type } from "@sinclair/typebox";                  │
│  import { Text } from "@mariozechner/pi-tui";               │
│  import type { ExtensionAPI } from "@mariozechner/pi...     │
│  ...                                                        │
└─────────────────────────────────────────────────────────────┘
```

---

## Repos View

```
┌─────────────────────────────────────────────────────────────┐
│  Repos                                    [⚙️ Settings] [🔄 Scan]│
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Scanning: ~/dev/                                           │
│  Found: 47 repos with AGENTS.md                             │
│                                                             │
│  BLOATED (contains global content - should trim)            │
│  ─────────────────────────────────────────────────────────  │
│  ⚠️ groovetech-media-server     AGENTS.md (2.1 KB)          │
│  ⚠️ groovetech-media-player     AGENTS.md (1.8 KB)          │
│  ⚠️ orchestrator                AGENTS.md (3.2 KB)          │
│  ⚠️ AVPStreamKit               AGENTS.md (1.5 KB)          │
│                                                             │
│  MINIMAL (project-specific only) ✓                          │
│  ─────────────────────────────────────────────────────────  │
│  ✓ CodexSkillManager            AGENTS.md (0.4 KB)          │
│  ✓ pi-coding-agent              AGENTS.md (0.3 KB)          │
│                                                             │
│  NO AGENTS.MD                                               │
│  ─────────────────────────────────────────────────────────  │
│  ○ some-other-repo                                          │
│                                                             │
│                              [Trim Selected] [Trim All Bloated]│
└─────────────────────────────────────────────────────────────┘
```

---

## Confirmation Overlay Pattern

For ALL auto-actions, show clear confirmation:

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  ⚠️  Confirm: Fix All Symlinks                       │   │
│  │                                                      │   │
│  │  This will:                                          │   │
│  │                                                      │   │
│  │  1. Create symlink:                                  │   │
│  │     ~/.claude/CLAUDE.md → ~/.agent-config/AGENTS.md  │   │
│  │                                                      │   │
│  │  2. Backup and replace:                              │   │
│  │     ~/.codex/AGENTS.md                               │   │
│  │     → ~/.codex/AGENTS.md.backup                      │   │
│  │     → symlink to ~/.agent-config/AGENTS.md           │   │
│  │                                                      │   │
│  │                           [Cancel]  [Confirm & Run]  │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Verification Checklist

- [ ] Can navigate between all 5 sections
- [ ] Skills section shows Pi Agent skills
- [ ] Extensions section lists all Pi Agent extensions
- [ ] Extensions show provided tools/commands
- [ ] Can enable/disable extensions
- [ ] Commands section shows commands across all agents
- [ ] Commands show symlink status
- [ ] AGENTS.md section shows central config
- [ ] AGENTS.md shows symlink status per agent
- [ ] Can fix symlinks with clear confirmation
- [ ] Repos section scans ~/dev/
- [ ] Repos identifies bloated vs minimal AGENTS.md
- [ ] Migration wizard works when needed
- [ ] All auto-actions show clear confirmation
- [ ] App renamed to "Agent Config Manager"
- [ ] New app icon

---

## Expert Review Feedback (Phase 4)

### Key Architecture Changes

1. **3-Column NavigationSplitView** (not 2-column)
   - Sidebar: Sections + Agent filter
   - Content: Section-specific list
   - Detail: Section-specific detail/editor

2. **Add Root AppModel** (like Landmarks' ModelData)
   ```swift
   @Observable @MainActor
   final class AppModel {
       var selectedSection: NavigationSection = .skills
       var selectedAgents: Set<AgentID> = []  // empty = "all"
       var showMigrationWizard = false
       var showSymlinkWizard = false
       
       let skills: SkillsSectionStore
       let extensions: ExtensionStore
       let commands: CommandStore
       let instructions: InstructionsStore
       let repos: RepoStore
       let settings: SettingsStore
   }
   ```

3. **SkillsSectionStore** - Extract UI state from SkillSplitView
   - Owns: source, searchText, install sheet state, search task
   - Coordinates: SkillStore (local) + RemoteSkillStore (remote)

4. **AgentConfig Registry** - First-class dependency
   - Replace scattered stringly-typed paths
   - Single source of truth for agent paths

5. **Cross-Section Agent Filter**
   - Sidebar agent pills filter lists across ALL sections
   - Lives in AppModel, not individual stores

6. **Global Toolbar with Section Switch**
   - Single toolbar definition in MainSplitView
   - Switch toolbar content by section

### Revised File Structure

```
Sources/AgentConfigManager/
├── App/
│   ├── AgentConfigManagerApp.swift
│   ├── AppModel.swift              # Root model composing stores
│   ├── NavigationSection.swift     # Section enum
│   └── MainSplitView.swift         # 3-column shell
├── Models/
│   ├── AgentConfig.swift           # Agent registry
│   ├── Skill.swift
│   ├── Extension.swift
│   ├── Command.swift
│   ├── AgentInstructions.swift
│   └── RepoConfig.swift
├── Skills/
│   ├── SkillsSectionStore.swift    # UI coordination
│   ├── SkillStore.swift            # Domain logic
│   ├── RemoteSkillStore.swift
│   ├── SkillsContentView.swift     # Content column
│   ├── SkillsDetailView.swift      # Detail column
│   └── ...
├── Extensions/
│   ├── ExtensionStore.swift
│   ├── ExtensionsContentView.swift
│   └── ExtensionsDetailView.swift
├── Commands/
│   ├── CommandStore.swift
│   ├── CommandsContentView.swift
│   └── CommandsDetailView.swift
├── Instructions/
│   ├── InstructionsStore.swift
│   └── InstructionsView.swift
├── Repos/
│   ├── RepoStore.swift
│   ├── ReposContentView.swift
│   └── ReposDetailView.swift
├── Wizards/
│   ├── MigrationWizardView.swift
│   └── SymlinkWizardView.swift
├── Shared/
│   ├── SidebarView.swift
│   ├── ConfirmationOverlay.swift
│   ├── CodeView.swift
│   └── MarkdownView.swift
└── Workers/
    ├── SkillFileWorker.swift
    ├── ExtensionFileWorker.swift
    ├── RepoScanWorker.swift
    ├── SymlinkWorker.swift
    └── MigrationWorker.swift
```
