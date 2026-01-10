# PRD: Agent Config Manager — Full Implementation

## Introduction

Evolve CodexSkillManager into a unified manager for AI coding agent configuration. Users will manage skills, extensions, slash commands, and AGENTS.md files across all major AI agents (Pi, Claude, Codex, OpenCode, Copilot) from a single macOS app. The app consolidates scattered configuration into a central `~/.agent-config/` directory with symlinks pointing all agents to shared content, while allowing project-specific AGENTS.md files to remain minimal and locally-scoped.

---

## Goals

- Add Pi Agent support (skills + extensions) alongside existing agents
- Migrate from 2-column to 3-column NavigationSplitView with agent filtering
- Manage extensions (Pi Agent only): view source, parse tools/commands, enable/disable
- Manage slash commands across all agents: view, sync, detect symlinks
- Manage global AGENTS.md: view/edit central config, verify symlink status, auto-fix
- Scan project repos: detect AGENTS.md files, identify bloated vs minimal, help trim
- Provide clear migration path: opencode-config → ~/.agent-config with wizard
- Provide clear symlink setup wizard with explicit confirmation for auto-actions
- Support configurable watched directories for repo scanning
- Deliver with YOLO-safe incremental builds: each phase ends with `swift build` passing

---

## User Stories

### Phase 0: Baseline Verification

#### US-001: Verify clean baseline build
**Description:** As a developer, I need to ensure the project builds before starting major refactoring.

**Acceptance Criteria:**
- [ ] Run `swift build`
- [ ] Build succeeds with no errors
- [ ] Typecheck passes

---

### Phase 1: Pi Agent Support + Safety Fixes

#### US-002: Add Pi Agent to SkillPlatform enum
**Description:** As a developer, I need to register Pi Agent as a skill platform alongside Codex, Claude, etc.

**Acceptance Criteria:**
- [ ] Add `.pi = "Pi Agent"` case to SkillPlatform enum
- [ ] Set storageKey, rootURL (`~/.pi/agent/skills`), badgeTint (green), description
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-003: Update default install target to Pi Agent
**Description:** As a user installing a skill, the default target should be Pi Agent instead of Codex.

**Acceptance Criteria:**
- [ ] Change `@State private var installTargets` default from `[.codex]` to `[.pi]`
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-004: Fix open folder fallback path
**Description:** When opening a folder without platform specified, use Pi Agent path instead of hardcoded Codex path.

**Acceptance Criteria:**
- [ ] In SkillSplitView, replace `~/.codex/skills/public` fallback with `SkillPlatform.pi.rootURL`
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-005: Update preferred platform ordering
**Description:** Reorder platform listing to prioritize Pi Agent first.

**Acceptance Criteria:**
- [ ] Update both `preferredPlatformOrder` and `preferredOrder` to `[.pi, .codex, .claude, .opencode, .copilot]`
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-006: Rename app window title
**Description:** Change window title from "Codex Skill Manager" to "Agent Config Manager".

**Acceptance Criteria:**
- [ ] Update WindowGroup title in CodexSkillManagerApp.swift
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-007: Migrate Application Support folder
**Description:** Move publish state from legacy folder to new folder, with fallback support for old location.

**Acceptance Criteria:**
- [ ] Add constants for legacy (`CodexSkillManager`) and current (`AgentConfigManager`) folder names
- [ ] Update `publishStateDirectory()` to use current folder
- [ ] Update `loadPublishState()` to check legacy folder if current doesn't exist
- [ ] `savePublishState()` writes to current folder only
- [ ] Typecheck passes
- [ ] `swift build` succeeds

---

### Phase 2: Foundation — Registry, Settings, 3-Column Scaffolding

#### US-008: Create directory structure
**Description:** Create necessary source directories for new features.

**Acceptance Criteria:**
- [ ] Create `Sources/CodexSkillManager/Models/` if missing
- [ ] Create `Sources/CodexSkillManager/Shared/` if missing
- [ ] Create `Sources/CodexSkillManager/Extensions/` if missing
- [ ] Create `Sources/CodexSkillManager/Repos/` if missing
- [ ] Create `Sources/CodexSkillManager/Workers/` if missing
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-009: Create AgentID enum
**Description:** Define enum for agent identification across all sections.

**Acceptance Criteria:**
- [ ] Create AgentID.swift with `enum AgentID: String, CaseIterable, Identifiable, Hashable, Sendable`
- [ ] Add cases: pi, claude, codex, opencode, copilot
- [ ] Implement id property as rawValue
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-010: Add AgentID mapping to SkillPlatform
**Description:** Link SkillPlatform to AgentID for cross-section lookups.

**Acceptance Criteria:**
- [ ] Add computed property `var agentID: AgentID` to SkillPlatform
- [ ] Map each platform case to corresponding agent
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-011: Create AgentConfigPaths constants
**Description:** Centralize all configuration paths in one place.

**Acceptance Criteria:**
- [ ] Create AgentConfigPaths.swift
- [ ] Add static URLs: centralRootURL, centralAgentsMarkdownURL, centralCommandsURL, piSkillsURL, piExtensionsURL, etc.
- [ ] All paths use expanded `~` syntax
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-012: Create AgentConfig registry
**Description:** Build central registry of all agents with their configuration locations.

**Acceptance Criteria:**
- [ ] Create AgentConfig.swift with struct implementing Identifiable, Hashable, Sendable
- [ ] Include: id, displayName, badgeColor, skillsURL?, extensionsURL?, commandsURL?, agentsMarkdownURL?
- [ ] Create static `all: [AgentConfig]` array with all 5 agents
- [ ] Add `var skillPlatform: SkillPlatform?` mapping
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-013: Create SettingsStore
**Description:** Persist user preferences like watched directories and agent selection.

**Acceptance Criteria:**
- [ ] Create SettingsStore.swift with `@Observable @MainActor` class
- [ ] Add `var watchedDirectories: [URL]` with default `[~/dev]`
- [ ] Add `var selectedAgents: Set<AgentID>` with default empty
- [ ] Implement `load()` using UserDefaults
- [ ] Implement `save()` using UserDefaults
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-014: Create NavigationSection enum
**Description:** Define sidebar sections for the app.

**Acceptance Criteria:**
- [ ] Create NavigationSection.swift
- [ ] Add cases: skills, extensions, commands, agentsmd, repos
- [ ] Implement `var name: String` property
- [ ] Implement `var symbolName: String` property (SF Symbols)
- [ ] Implement Identifiable protocol
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-015: Create AppModel root coordinator
**Description:** Build root model that coordinates all stores and app state.

**Acceptance Criteria:**
- [ ] Create AppModel.swift with `@Observable @MainActor` class
- [ ] Add `var selectedSection: NavigationSection = .skills`
- [ ] Add `var selectedAgents: Set<AgentID> = []`
- [ ] Add `let settings: SettingsStore`
- [ ] Add `let skillStore: SkillStore`
- [ ] Add `let remoteSkillStore: RemoteSkillStore`
- [ ] Init loads settings and syncs selectedAgents
- [ ] Add `persistAgentSelection()` method
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-016: Create SidebarView
**Description:** Implement sidebar with section navigation and agent filter.

**Acceptance Criteria:**
- [ ] Create SidebarView.swift
- [ ] Display all NavigationSection cases with icons
- [ ] Show agent filter toggles for each agent in AgentConfig.all
- [ ] Add "All Agents" toggle that clears selectedAgents set
- [ ] Bind toggles to AppModel.selectedAgents
- [ ] Call persistAgentSelection() on changes
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-017: Create placeholder views
**Description:** Create minimal content and detail placeholder views for future sections.

**Acceptance Criteria:**
- [ ] Create PlaceholderContentView.swift with title + "Coming soon"
- [ ] Create PlaceholderDetailView.swift with title + "Coming soon"
- [ ] Both accept String title parameter
- [ ] Typecheck passes
- [ ] `swift build` succeeds

---

### Phase 3: Refactor Skills into 3-Column Layout

#### US-018: Create MainSplitView shell
**Description:** Build 3-column NavigationSplitView that routes based on selected section.

**Acceptance Criteria:**
- [ ] Create MainSplitView.swift
- [ ] Implement 3-column NavigationSplitView: sidebar + content + detail
- [ ] Column 1: SidebarView
- [ ] Column 2: PlaceholderContentView (will be replaced by section)
- [ ] Column 3: PlaceholderDetailView (will be replaced by section)
- [ ] Read AppModel from environment
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-019: Create SkillsSectionStore
**Description:** Extract UI coordination logic from SkillSplitView into dedicated store.

**Acceptance Criteria:**
- [ ] Create SkillsSectionStore.swift with `@Observable @MainActor` class
- [ ] Add: source (local/clawdhub), searchText, showingImport
- [ ] Add: installSkill, installTargets (default `[.pi]`)
- [ ] Add: downloadErrorMessage, isDownloadingRemote, didDownloadRemote
- [ ] Add: searchTask for debouncing
- [ ] Weak refs to SkillStore and RemoteSkillStore
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-020: Add SkillsSectionStore to AppModel
**Description:** Integrate skills store into root model.

**Acceptance Criteria:**
- [ ] Add `let skills: SkillsSectionStore` property to AppModel
- [ ] Initialize with local and remote store references
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-021: Create SkillsContentView — minimal list
**Description:** Build list column for skills section (will grow in substeps).

**Acceptance Criteria:**
- [ ] Create SkillsContentView.swift
- [ ] Show minimal List placeholder with "Skills" title
- [ ] Bind section/agent filter
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-022: Wire SkillsContentView — local skills list
**Description:** Display local skills in list column.

**Acceptance Criteria:**
- [ ] Read AppModel, SkillStore from environment
- [ ] Populate list with `skillStore.skills` (local only)
- [ ] Bind selection to `@State var selectedLocalSkill`
- [ ] Show skill name and platform badges
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-023: Wire SkillsContentView — remote skills list
**Description:** Display remote (Clawdhub) skills when source switched.

**Acceptance Criteria:**
- [ ] Read RemoteSkillStore from environment
- [ ] Switch list content based on `appModel.skills.source`
- [ ] When .local: show local skills
- [ ] When .clawdhub: show remote skills
- [ ] Bind selection to separate `@State var selectedRemoteSkill`
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-024: Wire SkillsContentView — agent filter
**Description:** Filter skill list by selected agents.

**Acceptance Criteria:**
- [ ] When source == .local AND selectedAgents non-empty: filter skills by agent
- [ ] When selectedAgents empty: show all skills (no filter)
- [ ] Remote skills unaffected by agent filter
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-025: Create SkillsDetailView
**Description:** Build detail column for viewing/installing skills.

**Acceptance Criteria:**
- [ ] Create SkillsDetailView.swift
- [ ] Switch on source: .local → SkillDetailView, .clawdhub → RemoteSkillDetailView
- [ ] Pass selected skill to respective detail view
- [ ] Handle nil selection (show placeholder)
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-026: Extract RemoteInstallSheet
**Description:** Move install flow into separate reusable component.

**Acceptance Criteria:**
- [ ] Create RemoteInstallSheet.swift
- [ ] Move RemoteInstallSheet struct from SkillSplitView unchanged
- [ ] Maintains all install logic and state
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-027: Create ConfirmationOverlay
**Description:** Build reusable overlay for confirming destructive/auto actions.

**Acceptance Criteria:**
- [ ] Create ConfirmationOverlay.swift
- [ ] Accept title, message, action items (bullet list)
- [ ] Show Cancel and Confirm buttons
- [ ] Darkened background with centered white box
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-028: Integrate ConfirmationOverlay into install flow
**Description:** Show confirmation before installing skill.

**Acceptance Criteria:**
- [ ] Update RemoteInstallSheet to show ConfirmationOverlay
- [ ] List all target paths where skill will be installed
- [ ] User must confirm before proceeding with install
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-029: Wire Extensions routing into MainSplitView
**Description:** Add Extensions section to 3-column router.

**Acceptance Criteria:**
- [ ] Update MainSplitView switch on selectedSection
- [ ] When .extensions: route to PlaceholderContentView/PlaceholderDetailView (temporary)
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-030: Wire Commands routing into MainSplitView
**Description:** Add Commands section to 3-column router.

**Acceptance Criteria:**
- [ ] Update MainSplitView switch on selectedSection
- [ ] When .commands: route to PlaceholderContentView/PlaceholderDetailView (temporary)
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-031: Wire AGENTS.md routing into MainSplitView
**Description:** Add AGENTS.md section to 3-column router.

**Acceptance Criteria:**
- [ ] Update MainSplitView switch on selectedSection
- [ ] When .agentsmd: route to PlaceholderContentView/PlaceholderDetailView (temporary)
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-032: Wire Repos routing into MainSplitView
**Description:** Add Repos section to 3-column router.

**Acceptance Criteria:**
- [ ] Update MainSplitView switch on selectedSection
- [ ] When .repos: route to PlaceholderContentView/PlaceholderDetailView (temporary)
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-033: Add search bar to MainSplitView
**Description:** Show searchable modifier when Skills section active.

**Acceptance Criteria:**
- [ ] Add `.searchable` modifier to MainSplitView
- [ ] Bind to `appModel.skills.searchText`
- [ ] Only show when `selectedSection == .skills`
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-034: Add toolbar — Add Skill button
**Description:** Show add skill button in toolbar when Skills active.

**Acceptance Criteria:**
- [ ] Add button in MainSplitView toolbar
- [ ] Show only when `selectedSection == .skills`
- [ ] Toggle `appModel.skills.showingImport`
- [ ] Present RemoteInstallSheet when true
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-035: Add toolbar — Open Folder button
**Description:** Show open folder button for local skills.

**Acceptance Criteria:**
- [ ] Add button in MainSplitView toolbar
- [ ] Show only when `.skills` selected AND source == .local
- [ ] Call existing `openSelectedSkillFolder` logic
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-036: Add toolbar — Download button
**Description:** Show download button for remote skills.

**Acceptance Criteria:**
- [ ] Add button in MainSplitView toolbar
- [ ] Show only when `.skills` selected AND source == .clawdhub
- [ ] Call existing `downloadLatestClawdhub` logic
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-037: Add lifecycle tasks to SkillsContentView
**Description:** Load skills and remote store on view appearance.

**Acceptance Criteria:**
- [ ] Add `.task { await skillStore.load() }`
- [ ] Add `.task { await remoteSkillStore.loadLatest() }`
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-038: Add onChange for store selection
**Description:** Update detail view when selection changes.

**Acceptance Criteria:**
- [ ] Add `.onChange(of: selectedLocalSkill)` handler
- [ ] Update AppModel or SkillsSectionStore with new selection
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-039: Add onChange for search text
**Description:** Trigger search when source is Clawdhub.

**Acceptance Criteria:**
- [ ] Add `.onChange(of: appModel.skills.searchText)` handler
- [ ] Call remoteSkillStore search method
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-040: Switch app entry point to MainSplitView
**Description:** Replace SkillSplitView with new 3-column shell.

**Acceptance Criteria:**
- [ ] Update CodexSkillManagerApp.swift
- [ ] Create AppModel instance
- [ ] Replace SkillSplitView() with MainSplitView()
- [ ] Inject environments: appModel, skillStore, remoteSkillStore, settings
- [ ] Verify skills section still works
- [ ] Typecheck passes
- [ ] `swift build` succeeds
- [ ] `swift run` shows app with 5 sections in sidebar

#### US-041: Create RepoSettingsView
**Description:** UI for managing watched directories for repo scanning.

**Acceptance Criteria:**
- [ ] Create RepoSettingsView.swift
- [ ] Bind to `SettingsStore.watchedDirectories`
- [ ] Show list of current directories
- [ ] Add button to add new directory (file picker)
- [ ] Remove button for each directory
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-042: Integrate RepoSettingsView into MainSplitView
**Description:** Add settings access from Repos toolbar.

**Acceptance Criteria:**
- [ ] Add Settings button to toolbar when `.repos` selected
- [ ] Present RepoSettingsView as sheet
- [ ] Bind to `SettingsStore`
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-043: Delete SkillSplitView
**Description:** Remove old 2-column view now that MainSplitView is live.

**Acceptance Criteria:**
- [ ] Delete `Sources/CodexSkillManager/Skills/SkillSplitView.swift`
- [ ] All references removed from app entry point
- [ ] Typecheck passes
- [ ] `swift build` succeeds

---

### Phase 4: Extensions Section — Pi Agent Only

#### US-044: Create Extension model
**Description:** Define data structure for Pi Agent extensions.

**Acceptance Criteria:**
- [ ] Create Extension.swift with struct implementing Identifiable, Hashable, Sendable
- [ ] Include: id (UUID), name (String), folderURL (URL), entryPoint (URL), providedTools ([String]), providedCommands ([String]), isEnabled (Bool)
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-045: Create ExtensionFileWorker
**Description:** Actor to scan and parse extensions.

**Acceptance Criteria:**
- [ ] Create ExtensionFileWorker.swift
- [ ] Implement `scanExtensions(at: URL) -> [Extension]` async method
- [ ] Implement regex pattern for `registerTool()` calls: `/registerTool\(\s*\{\s*name:\s*["']([^"']+)["']/`
- [ ] Implement regex pattern for `registerCommand()` calls: `/registerCommand\(\s*["']([^"']+)["']/`
- [ ] Parse index.ts entry point for tools/commands
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-046: Create CodeView
**Description:** Syntax-highlighted code viewer for TypeScript.

**Acceptance Criteria:**
- [ ] Create CodeView.swift
- [ ] Accept code String and filename as parameters
- [ ] Display in monospace font with line numbers (optional but nice)
- [ ] Use ScrollView for large files
- [ ] Syntax highlighting: keywords, strings, comments (use basic SF symbols or simple color patterns)
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-047: Create ExtensionStore
**Description:** Manage Pi Agent extensions.

**Acceptance Criteria:**
- [ ] Create ExtensionStore.swift with `@Observable @MainActor` class
- [ ] Add `var extensions: [Extension] = []`
- [ ] Add `var selectedExtensionID: UUID?`
- [ ] Implement `async load()` method using ExtensionFileWorker
- [ ] Load from `AgentConfigPaths.piExtensionsURL`
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-048: Add ExtensionStore to AppModel
**Description:** Integrate extensions store into root model.

**Acceptance Criteria:**
- [ ] Add `let extensions: ExtensionStore` to AppModel
- [ ] Initialize in AppModel init
- [ ] Inject via environment in CodexSkillManagerApp
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-049: Create ExtensionsContentView
**Description:** List extensions with agent filter support.

**Acceptance Criteria:**
- [ ] Create ExtensionsContentView.swift
- [ ] Show list of extensions
- [ ] When selectedAgents empty OR contains .pi: show list
- [ ] When selectedAgents non-empty AND excludes .pi: show "Select Pi Agent to view extensions"
- [ ] Bind selection to ExtensionStore.selectedExtensionID
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-050: Create ExtensionsDetailView
**Description:** View extension info and source code.

**Acceptance Criteria:**
- [ ] Create ExtensionsDetailView.swift
- [ ] Show extension folder path
- [ ] Show section: "PROVIDES" with tools and commands lists
- [ ] Show section: "FILES" with file list from extension folder
- [ ] Show "Open in VS Code" button
- [ ] Display source code of index.ts using CodeView
- [ ] Link to Pi Agent Extension Docs
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-051: Wire Extensions section in MainSplitView
**Description:** Route to Extensions views when section selected.

**Acceptance Criteria:**
- [ ] Update MainSplitView switch on selectedSection
- [ ] When .extensions: show ExtensionsContentView + ExtensionsDetailView
- [ ] Replace placeholders
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-052: Add Extensions toolbar items
**Description:** Show refresh and open buttons for Extensions.

**Acceptance Criteria:**
- [ ] Add Refresh button in toolbar when `.extensions` selected
- [ ] Call `await extensionStore.load()`
- [ ] Add "Open in Finder" button
- [ ] Open `AgentConfigPaths.piExtensionsURL`
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-053: Add lifecycle load to ExtensionsContentView
**Description:** Load extensions on view appearance.

**Acceptance Criteria:**
- [ ] Add `.task { await extensionStore.load() }`
- [ ] Typecheck passes
- [ ] `swift build` succeeds

---

### Phase 5: Commands Section

#### US-054: Create Command model
**Description:** Define data structure for slash commands.

**Acceptance Criteria:**
- [ ] Create Command.swift with struct implementing Identifiable, Hashable, Sendable
- [ ] Include: id (UUID), name (String), installedAgents (Set<AgentID>), fileURL (URL), isSymlink (Bool), symlinkTarget (URL?)
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-055: Create CommandFileWorker
**Description:** Actor to scan command directories.

**Acceptance Criteria:**
- [ ] Create CommandFileWorker.swift
- [ ] Implement `scanCommandDirectories(for agents: [AgentConfig]) -> [Command]` async method
- [ ] Scan each agent's command directory
- [ ] Detect symlinks and symlink targets
- [ ] Parse command filename as name
- [ ] Group commands across agents (same name = cross-agent)
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-056: Create CommandStore
**Description:** Manage slash commands.

**Acceptance Criteria:**
- [ ] Create CommandStore.swift with `@Observable @MainActor` class
- [ ] Add `var commands: [Command] = []`
- [ ] Add `var selectedCommandID: UUID?`
- [ ] Implement `async load(agents: [AgentConfig])` method
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-057: Add CommandStore to AppModel
**Description:** Integrate commands store into root model.

**Acceptance Criteria:**
- [ ] Add `let commands: CommandStore` to AppModel
- [ ] Initialize in AppModel init
- [ ] Inject via environment in CodexSkillManagerApp
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-058: Create CommandsContentView
**Description:** List commands with symlink status.

**Acceptance Criteria:**
- [ ] Create CommandsContentView.swift
- [ ] Show list of commands
- [ ] Display agent badges (which agents have this command)
- [ ] Show symlink indicator (✓ if pointing to central, ⚠️ if standalone, ✗ if missing)
- [ ] Bind selection to CommandStore.selectedCommandID
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-059: Create CommandsDetailView
**Description:** View command content and symlink status.

**Acceptance Criteria:**
- [ ] Create CommandsDetailView.swift
- [ ] Show command file path
- [ ] Show symlink status per agent (where command exists)
- [ ] Display markdown content using MarkdownView
- [ ] Show "Fix Symlinks" button (if any are broken)
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-060: Wire Commands section in MainSplitView
**Description:** Route to Commands views when section selected.

**Acceptance Criteria:**
- [ ] Update MainSplitView switch on selectedSection
- [ ] When .commands: show CommandsContentView + CommandsDetailView
- [ ] Replace placeholders
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-061: Add Commands toolbar items
**Description:** Show refresh button for Commands.

**Acceptance Criteria:**
- [ ] Add Refresh button in toolbar when `.commands` selected
- [ ] Call `await commandStore.load(agents: AgentConfig.all)`
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-062: Add lifecycle load to CommandsContentView
**Description:** Load commands on view appearance.

**Acceptance Criteria:**
- [ ] Add `.task { await commandStore.load(agents: AgentConfig.all) }`
- [ ] Typecheck passes
- [ ] `swift build` succeeds

---

### Phase 6: AGENTS.md Section + Symlink Setup

#### US-063: Create AgentInstructions model
**Description:** Define data structure for global agent instructions.

**Acceptance Criteria:**
- [ ] Create AgentInstructions.swift with struct implementing Identifiable, Hashable, Sendable
- [ ] Include: id (AgentID), agent (AgentConfig), expectedPath (URL), isSymlink (Bool), symlinkTarget (URL?), pointsToCentral (Bool)
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-064: Create SymlinkWorker
**Description:** Actor to verify and repair symlinks.

**Acceptance Criteria:**
- [ ] Create SymlinkWorker.swift
- [ ] Implement `checkSymlink(at: URL) -> (isSymlink: Bool, target: URL?)` async method
- [ ] Implement `createSymlink(from: URL, to: URL) -> Result<Void, Error>` async method
- [ ] Implement `replaceWithSymlink(at: URL, pointingTo: URL) -> Result<Void, Error>` with backup
- [ ] Create backups when replacing files: `.backup` suffix
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-065: Create InstructionsStore
**Description:** Manage global AGENTS.md and symlink status.

**Acceptance Criteria:**
- [ ] Create InstructionsStore.swift with `@Observable @MainActor` class
- [ ] Add `var instructions: [AgentInstructions] = []`
- [ ] Add `var centralContent: String = ""`
- [ ] Implement `async load()` method checking all agents
- [ ] Load central AGENTS.md content from `AgentConfigPaths.centralAgentsMarkdownURL`
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-066: Add InstructionsStore to AppModel
**Description:** Integrate instructions store into root model.

**Acceptance Criteria:**
- [ ] Add `let instructions: InstructionsStore` to AppModel
- [ ] Initialize in AppModel init
- [ ] Inject via environment in CodexSkillManagerApp
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-067: Create InstructionsContentView
**Description:** Show symlink status for all agents.

**Acceptance Criteria:**
- [ ] Create InstructionsContentView.swift
- [ ] List all agents from AgentConfig.all
- [ ] For each: show symlink status (✓ pointing to central, ✗ missing, ⚠️ broken)
- [ ] Show expected path and actual target
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-068: Create AgentSymlinkStatusView
**Description:** Detail view for symlink status of single agent.

**Acceptance Criteria:**
- [ ] Create AgentSymlinkStatusView.swift
- [ ] Show agent name and badge color
- [ ] Display expected path
- [ ] Display current symlink target (if exists)
- [ ] Show status indicator and explanation
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-069: Create InstructionsView
**Description:** Editor for central AGENTS.md file.

**Acceptance Criteria:**
- [ ] Create InstructionsView.swift
- [ ] Display central AGENTS.md content
- [ ] TextEditor for markdown editing
- [ ] Save button to persist changes
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-070: Create SymlinkWizardView
**Description:** Interactive wizard to setup/repair symlinks.

**Acceptance Criteria:**
- [ ] Create SymlinkWizardView.swift with multi-step UI
- [ ] Step 1: Show current status (pass/warn/fail per agent)
- [ ] Step 2: Show proposed fixes (what will be created/replaced)
- [ ] Step 3: Show backup locations for any replaced files
- [ ] Show clear confirmation with ConfirmationOverlay
- [ ] Execute fixes via SymlinkWorker
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-071: Wire AGENTS.md section in MainSplitView
**Description:** Route to Instructions views when section selected.

**Acceptance Criteria:**
- [ ] Update MainSplitView switch on selectedSection
- [ ] When .agentsmd: show InstructionsContentView + InstructionsView
- [ ] Add "Setup Symlinks" button in toolbar
- [ ] Present SymlinkWizardView when button clicked
- [ ] Replace placeholders
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-072: Add lifecycle load to InstructionsContentView
**Description:** Load instructions on view appearance.

**Acceptance Criteria:**
- [ ] Add `.task { await instructionsStore.load() }`
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-073: Create MigrationWizardView
**Description:** Interactive wizard to migrate opencode-config → ~/.agent-config

**Acceptance Criteria:**
- [ ] Create MigrationWizardView.swift with multi-step UI
- [ ] Step 1: Detect both locations, show what will be copied
- [ ] Step 2: Show file counts for AGENTS.md, commands/, knowledge/
- [ ] Step 3: Confirm and execute migration via MigrationWorker
- [ ] Show ConfirmationOverlay with explicit actions
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-074: Create MigrationWorker
**Description:** Actor to handle config migration.

**Acceptance Criteria:**
- [ ] Create MigrationWorker.swift
- [ ] Implement `checkMigrationNeeded() -> Bool` method
- [ ] Implement `async migrate() -> Result<Void, Error>` method
- [ ] Copy AGENTS.md if central doesn't have it
- [ ] Copy commands/ if central doesn't have it
- [ ] Copy knowledge/ if central doesn't have it
- [ ] Keep opencode-config as backup
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-075: Add migration check to app startup
**Description:** Show migration wizard if needed on first launch.

**Acceptance Criteria:**
- [ ] Update AppModel with `var showMigrationWizard = false`
- [ ] Call `migrationWorker.checkMigrationNeeded()` in app init
- [ ] Show SymlinkWizardView in sheet when true
- [ ] After migration complete, show SymlinkWizardView
- [ ] Typecheck passes
- [ ] `swift build` succeeds

---

### Phase 7: Repos Section

#### US-076: Create RepoConfig model
**Description:** Define data structure for scanned repositories.

**Acceptance Criteria:**
- [ ] Create RepoConfig.swift with struct implementing Identifiable, Hashable, Sendable
- [ ] Include: id (UUID), name (String), path (URL), agentsmdPath (URL?), fileSize (Int), containsGlobalContent (Bool), lastModified (Date?)
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-077: Create RepoScanWorker
**Description:** Actor to scan directories for repos.

**Acceptance Criteria:**
- [ ] Create RepoScanWorker.swift
- [ ] Implement `scanDirectories(_ dirs: [URL]) -> [RepoConfig]` async method
- [ ] Recursively find AGENTS.md files
- [ ] Implement `containsGlobalContent(_ content: String) -> Bool` detector
- [ ] Mark as bloated if contains: "North Star", "Modern Apple Development", "gj run", "Code Philosophy", "Chief Visioneer" (2+ matches)
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-078: Create RepoStore
**Description:** Manage scanned repositories.

**Acceptance Criteria:**
- [ ] Create RepoStore.swift with `@Observable @MainActor` class
- [ ] Add `var repos: [RepoConfig] = []`
- [ ] Add `var selectedRepoID: UUID?`
- [ ] Add `var isScanning = false`
- [ ] Implement `async scan(directories: [URL])` method
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-079: Add RepoStore to AppModel
**Description:** Integrate repos store into root model.

**Acceptance Criteria:**
- [ ] Add `let repos: RepoStore` to AppModel
- [ ] Initialize in AppModel init
- [ ] Inject via environment in CodexSkillManagerApp
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-080: Create ReposContentView
**Description:** List repos grouped by bloated/minimal/no AGENTS.md.

**Acceptance Criteria:**
- [ ] Create ReposContentView.swift
- [ ] Group repos into 3 sections: BLOATED, MINIMAL, NO AGENTS.MD
- [ ] Show repo name and file size
- [ ] Show warning badge for bloated files
- [ ] Bind selection to RepoStore.selectedRepoID
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-081: Create ReposDetailView
**Description:** View/edit individual repo AGENTS.md.

**Acceptance Criteria:**
- [ ] Create ReposDetailView.swift
- [ ] Show repo path and file size
- [ ] Show bloated status with explanation
- [ ] Display AGENTS.md content in editor
- [ ] Show "Trim to Project-Specific" button (if bloated)
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-082: Wire Repos section in MainSplitView
**Description:** Route to Repos views when section selected.

**Acceptance Criteria:**
- [ ] Update MainSplitView switch on selectedSection
- [ ] When .repos: show ReposContentView + ReposDetailView
- [ ] Replace placeholders
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-083: Add Repos toolbar items
**Description:** Show scan and settings buttons.

**Acceptance Criteria:**
- [ ] Add Scan button in toolbar when `.repos` selected
- [ ] Call `await repoStore.scan(directories: settings.watchedDirectories)`
- [ ] Show isScanning indicator
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-084: Add lifecycle load to ReposContentView
**Description:** Scan repos on view appearance.

**Acceptance Criteria:**
- [ ] Add `.task { await repoStore.scan(directories: appModel.settings.watchedDirectories) }`
- [ ] Typecheck passes
- [ ] `swift build` succeeds

---

### Phase 8: Final Rename & Polish

#### US-085: Rename app bundle and target
**Description:** Update from CodexSkillManager to AgentConfigManager.

**Acceptance Criteria:**
- [ ] Update `Package.swift` target name to `AgentConfigManager`
- [ ] Update bundle identifier to `com.example.AgentConfigManager` (or appropriate ID)
- [ ] Rename main App file from `CodexSkillManagerApp.swift` to `AgentConfigManagerApp.swift`
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-086: Design and integrate new app icon
**Description:** Create distinctive icon for Agent Config Manager.

**Acceptance Criteria:**
- [ ] Design icon in vector format (or high-res PNG)
- [ ] Add to Icon.iconset/ directory at required sizes
- [ ] Update Icon.icns with new design
- [ ] Verify in app when running
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-087: Update README
**Description:** Document app purpose, features, and usage.

**Acceptance Criteria:**
- [ ] Rewrite README.md for Agent Config Manager
- [ ] Document all 5 sections: Skills, Extensions, Commands, AGENTS.md, Repos
- [ ] Include screenshots of each section
- [ ] Document migration wizard
- [ ] Document symlink setup
- [ ] Include build/run instructions
- [ ] Typecheck passes
- [ ] `swift build` succeeds

#### US-088: Test all sections end-to-end
**Description:** Verify complete workflow with real Pi Agent and other agents.

**Acceptance Criteria:**
- [ ] Navigate all 5 sections in sidebar
- [ ] Agent filter toggles work
- [ ] Skills section: install skill to multiple agents
- [ ] Extensions section: view Pi Agent extension source
- [ ] Commands section: see symlink status across agents
- [ ] AGENTS.md section: run symlink wizard, verify repairs
- [ ] Repos section: scan ~/dev/, identify bloated files
- [ ] All automatic actions show ConfirmationOverlay
- [ ] Migration wizard works (if triggered)
- [ ] Typecheck passes
- [ ] `swift build` succeeds

---

## Functional Requirements

### Skills Section
- FR-1: List skills from all installed agents (Pi, Claude, Codex, OpenCode, Copilot)
- FR-2: Filter skills by selected agents
- FR-3: Install skill to selected target agents with confirmation overlay
- FR-4: Open skill folder in Finder
- FR-5: Support local skills and Clawdhub remote browsing
- FR-6: Default install target is Pi Agent

### Extensions Section
- FR-7: List Pi Agent extensions from ~/.pi/agent/extensions/
- FR-8: Parse and display tools/commands from extension source code
- FR-9: Show extension source code with TypeScript syntax highlighting
- FR-10: Open extension folder in VS Code
- FR-11: Only visible when Pi Agent is selected (or "All Agents" selected)

### Commands Section
- FR-12: List slash commands from all agent command directories
- FR-13: Show which agents have each command (badge pills)
- FR-14: Detect symlink status: central, standalone, missing
- FR-15: Display command content in markdown
- FR-16: Show "Fix Symlinks" action for broken symlinks

### AGENTS.md Section
- FR-17: Display central ~/.agent-config/AGENTS.md in editor
- FR-18: Show symlink status for each agent's AGENTS.md path
- FR-19: Verify which symlinks point to central config
- FR-20: Symlink Setup Wizard to create/repair all symlinks
- FR-21: Show explicit confirmation before executing symlink repairs
- FR-22: Create backups before replacing any files

### Repos Section
- FR-23: Scan configurable watched directories (default ~/dev/)
- FR-24: Find all AGENTS.md files in repos
- FR-25: Detect bloated files (containing global content markers)
- FR-26: Group repos by: BLOATED, MINIMAL, NO AGENTS.MD
- FR-27: Display file size and content summary
- FR-28: Offer "Trim to Project-Specific" guidance

### Foundation
- FR-29: Central registry (AgentConfig) for all agents and their paths
- FR-30: Persistent user settings (watched directories, agent selection)
- FR-31: 3-column NavigationSplitView with sidebar + content + detail
- FR-32: Agent filter that works across all sections
- FR-33: Migration wizard for opencode-config → ~/.agent-config
- FR-34: All automatic/destructive actions require ConfirmationOverlay
- FR-35: YOLO-safe build: every phase ends with `swift build` passing

---

## Non-Goals

- Not supporting other agents' proprietary extension formats (only Pi Agent)
- Not building a skill editor or creation tool (view/install only)
- Not managing agent installation or versioning
- Not supporting per-project skill installation
- Not implementing auto-update of agent configs from cloud
- Not building a web version or iOS app
- Not managing project dependencies in AGENTS.md (presentation only)

---

## Design Considerations

### UI/UX
- 3-column NavigationSplitView mirrors Landmarks app pattern (familiar to macOS users)
- Agent filter is persistent and cross-section (not per-section)
- All auto-actions (symlink setup, migration) use explicit ConfirmationOverlay
- Color-coded agent badges (green for Pi, orange for Claude, etc.)
- Inline status indicators: ✓, ⚠️, ✗ for symlink/bloated detection

### Architecture
- Root AppModel coordinates all stores and app state
- Each section has dedicated Store + ContentView + DetailView
- Workers (SymlinkWorker, RepoScanWorker, etc.) handle I/O separately
- Environment injection for stores and settings
- No child view owns its own stores—all from AppModel

---

## Technical Considerations

### Symlink Safety
- Always create backups before replacing files (`.backup` suffix)
- Show exact paths in ConfirmationOverlay before executing
- Log all symlink operations for debugging
- Verify symlinks after creation with checkSymlink()

### Repo Scanning
- Scan asynchronously to avoid blocking UI
- Use FileManager.contentsOfDirectory with error handling
- Limit initial scan depth to avoid slow network shares
- Cache scan results with timestamp

### Code Parsing
- Use Regex for extracting tools/commands from TypeScript
- Fallback to empty lists if parsing fails (non-blocking)
- Assume well-formed exported code (no advanced JS parsing)

### Path Handling
- Expand ~ in all path constants
- Use URL throughout (not String paths)
- Handle symlinks correctly with URL.standardized
- Check file existence before accessing

---

## Success Metrics

- User can navigate all 5 sections without crashes
- Skills install to Pi Agent by default
- Extensions section shows Pi Agent extensions with source
- Commands section detects cross-agent symlinks
- AGENTS.md symlink setup wizard repairs all broken symlinks
- Repos section identifies 2+ bloated files in test directory
- All automatic actions require explicit user confirmation
- Migration wizard successfully consolidates opencode-config
- App builds and runs on macOS 12+ with SwiftUI
- No compilation errors or warnings

---

## Open Questions

- Should repos also show Git info (last commit, branch)?
- Should symlink wizard offer single-agent symlink creation?
- Should commands section support creating new commands?
- Should repos support editing project AGENTS.md inline?
- What macOS version should be minimum target?

