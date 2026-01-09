# Agent Config Manager — YOLO-Safe Implementation Plan

> Every step ends with `swift build` pass. No orphaned files. Compile-safe and incremental.

## Locked Decisions (Before Starting)

### Decision A: SkillPlatform vs AgentConfig
- **Keep `SkillPlatform`** for skills-only behavior (install destinations, grouping, root URLs)
- **Introduce `AgentID` + `AgentConfig`** as cross-section registry (paths, display names, badge colors)
- **Add mapping both ways:**
  - `AgentConfig.skillPlatform: SkillPlatform?`
  - `SkillPlatform.agentID: AgentID`

### Decision B: Environment Injection Strategy
To keep existing views compiling (many use `@Environment(SkillStore.self)`), we will:
- Add root `AppModel` to environment **AND**
- Continue injecting existing stores directly:
  - `SkillStore`
  - `RemoteSkillStore`
  - `SettingsStore` (new)

### Decision C: 3-Column Layout
Standardize on 3-column `NavigationSplitView`:
- **Sidebar:** Sections + agent filter
- **Content:** List/status (section-specific)
- **Detail:** Editor/detail (section-specific)

For AGENTS.md section:
- Content column: Agent symlink/status list
- Detail column: Central AGENTS.md editor

---

## Phase 0 — Baseline (2 minutes)

### 0.1 Verify clean baseline build
**WHAT**: Ensure project builds before starting
**VERIFY**: `swift build` succeeds

---

## Phase 1 — Pi Agent Support + Safety Fixes

### 1.1 Add `.pi` to `SkillPlatform`
**WHERE**: `Sources/CodexSkillManager/Skills/Shared/SkillPlatform.swift`
**WHAT**: Add case `pi = "Pi Agent"` with storageKey, rootURL (`~/.pi/agent/skills`), badgeTint (green), description
**VERIFY**: `swift build`

### 1.2 Update default install target to Pi
**WHERE**: `Sources/CodexSkillManager/Skills/SkillSplitView.swift`
**WHAT**: Change `@State private var installTargets: Set<SkillPlatform> = [.codex]` to `[.pi]`
**VERIFY**: `swift build`

### 1.3 Fix "open folder" fallback path
**WHERE**: `Sources/CodexSkillManager/Skills/SkillSplitView.swift`
**WHAT**: In `openSelectedSkillFolder(platform: nil)`, replace `~/.codex/skills/public` with `SkillPlatform.pi.rootURL`
**VERIFY**: `swift build`

### 1.4 Update preferred platform ordering
**WHERE**: `Sources/CodexSkillManager/Skills/Local/SkillStore.swift`
**WHAT**: Update both `preferredPlatformOrder` and `preferredOrder` to `[.pi, .codex, .claude, .opencode, .copilot]`
**VERIFY**: `swift build`

### 1.5 Rename window title
**WHERE**: `Sources/CodexSkillManager/App/CodexSkillManagerApp.swift`
**WHAT**: Change WindowGroup title to `"Agent Config Manager"`
**VERIFY**: `swift build`

### 1.6 Application Support directory migration
**WHERE**: `Sources/CodexSkillManager/Skills/Local/SkillStore.swift`
**WHAT**:
1. Add constants: `legacySupportFolderName = "CodexSkillManager"`, `currentSupportFolderName = "AgentConfigManager"`
2. Change `publishStateDirectory()` to use current folder name
3. Update `loadPublishState(for:)` to check legacy folder if current doesn't exist
4. Keep `savePublishState(for:)` writing to current folder only
**VERIFY**: `swift build`

---

## Phase 2 — Foundation (Registry + Settings + 3-Column Scaffolding)

### 2.0 Create new directories
**WHAT**: Create directories if missing:
- `Sources/CodexSkillManager/Models/`
- `Sources/CodexSkillManager/Shared/`
- `Sources/CodexSkillManager/Extensions/`
- `Sources/CodexSkillManager/Repos/`
**VERIFY**: `swift build`

### 2.1 Create `AgentID`
**CREATE**: `Sources/CodexSkillManager/Models/AgentID.swift`
**WHAT**: `enum AgentID: String, CaseIterable, Identifiable, Hashable, Sendable` with cases: pi, claude, codex, opencode, copilot
**VERIFY**: `swift build`

### 2.2 Add mapping from `SkillPlatform` → `AgentID`
**WHERE**: `Sources/CodexSkillManager/Skills/Shared/SkillPlatform.swift`
**WHAT**: Add `var agentID: AgentID { ... }` computed property
**VERIFY**: `swift build`

### 2.3 Create central path constants
**CREATE**: `Sources/CodexSkillManager/Models/AgentConfigPaths.swift`
**WHAT**: `enum AgentConfigPaths` with static URLs:
- `centralRootURL` (`~/.agent-config`)
- `centralAgentsMarkdownURL` (`~/.agent-config/AGENTS.md`)
- `centralCommandsURL` (`~/.agent-config/commands`)
- `piSkillsURL`, `piExtensionsURL`, etc.
**VERIFY**: `swift build`

### 2.4 Create `AgentConfig` registry
**CREATE**: `Sources/CodexSkillManager/Models/AgentConfig.swift`
**WHAT**: `struct AgentConfig: Identifiable, Hashable, Sendable` with id, displayName, badgeColor, skillsURL?, extensionsURL?, commandsURL?, agentsMarkdownURL?. Static `all` array. Add `var skillPlatform: SkillPlatform?` mapping.
**VERIFY**: `swift build`

### 2.5 Create `SettingsStore`
**CREATE**: `Sources/CodexSkillManager/Models/SettingsStore.swift`
**WHAT**: `@Observable @MainActor final class SettingsStore` with:
- `var watchedDirectories: [URL]` (default `[~/dev]`)
- `var selectedAgents: Set<AgentID>` (default empty = All)
- `load()` and `save()` methods using UserDefaults
**VERIFY**: `swift build`

### 2.6 Create `NavigationSection`
**CREATE**: `Sources/CodexSkillManager/App/NavigationSection.swift`
**WHAT**: `enum NavigationSection` with cases: skills, extensions, commands, agentsmd, repos. Add `name` and `symbolName` properties.
**VERIFY**: `swift build`

### 2.7 Create `AppModel`
**CREATE**: `Sources/CodexSkillManager/App/AppModel.swift`
**WHAT**: `@Observable @MainActor final class AppModel` with:
- `var selectedSection: NavigationSection = .skills`
- `var selectedAgents: Set<AgentID> = []`
- `let settings: SettingsStore`
- `let skillStore: SkillStore`
- `let remoteSkillStore: RemoteSkillStore`
- Init loads settings, assigns `selectedAgents = settings.selectedAgents`
- `func persistAgentSelection()` saves to settings
**VERIFY**: `swift build`

### 2.8 Create `SidebarView`
**CREATE**: `Sources/CodexSkillManager/Shared/SidebarView.swift`
**WHAT**: View with bindings for `selectedSection` and `selectedAgents`. Lists NavigationSection cases with icons. Shows agent filter toggles using AgentConfig.all.
**VERIFY**: `swift build`

### 2.9 Create placeholder views
**CREATE**: `Sources/CodexSkillManager/Shared/PlaceholderContentView.swift`
**CREATE**: `Sources/CodexSkillManager/Shared/PlaceholderDetailView.swift`
**WHAT**: Minimal views with title and "Coming soon" message
**VERIFY**: `swift build`

---

## Phase 3 — Skills Refactor into 3-Column Shell

### 3.0 Create `MainSplitView` shell
**CREATE**: `Sources/CodexSkillManager/App/MainSplitView.swift`
**WHAT**: `NavigationSplitView` with SidebarView, PlaceholderContentView, PlaceholderDetailView. Reads AppModel from environment.
**VERIFY**: `swift build`

### 3.1 Create `SkillsSectionStore`
**CREATE**: `Sources/CodexSkillManager/Skills/SkillsSectionStore.swift`
**WHAT**: `@Observable @MainActor final class SkillsSectionStore` with:
- `source`, `searchText`, `showingImport`
- `installSkill`, `installTargets` (default `[.pi]`)
- `downloadErrorMessage`, `isDownloadingRemote`, `didDownloadRemote`
- `searchTask`
- `unowned let local: SkillStore`, `unowned let remote: RemoteSkillStore`
**VERIFY**: `swift build`

### 3.2 Add `skills` to `AppModel`
**WHERE**: `Sources/CodexSkillManager/App/AppModel.swift`
**WHAT**: Add `let skills: SkillsSectionStore`, initialize with local/remote stores
**VERIFY**: `swift build`

### 3.3 Create `SkillsContentView`
**CREATE**: `Sources/CodexSkillManager/Skills/SkillsContentView.swift`
**WHAT**: Copy `listView` logic from SkillSplitView. Use environment for AppModel, SkillStore, RemoteSkillStore. Bind selection. Apply agent filter when source == .local and selectedAgents non-empty.
**VERIFY**: `swift build`

### 3.4 Create `SkillsDetailView`
**CREATE**: `Sources/CodexSkillManager/Skills/SkillsDetailView.swift`
**WHAT**: Copy `detailView` switch logic (local → SkillDetailView, clawdhub → RemoteSkillDetailView)
**VERIFY**: `swift build`

### 3.5 Extract `RemoteInstallSheet`
**CREATE**: `Sources/CodexSkillManager/Skills/RemoteInstallSheet.swift`
**WHAT**: Move RemoteInstallSheet struct from SkillSplitView unchanged
**VERIFY**: `swift build`

### 3.6.1 Create `ConfirmationOverlay`
**CREATE**: `Sources/CodexSkillManager/Shared/ConfirmationOverlay.swift`
**WHAT**: Reusable overlay with title, message, bullet actions, Cancel/Confirm buttons
**VERIFY**: `swift build`

### 3.6.2 Integrate ConfirmationOverlay into install flow
**WHERE**: `Sources/CodexSkillManager/Skills/RemoteInstallSheet.swift`
**WHAT**: Show ConfirmationOverlay before install listing target paths
**VERIFY**: `swift build`

### 3.7 Update MainSplitView for Skills
**WHERE**: `Sources/CodexSkillManager/App/MainSplitView.swift`
**WHAT**: Switch on selectedSection, return SkillsContentView/SkillsDetailView for .skills
**VERIFY**: `swift build`

### 3.8 Add skills lifecycle behavior
**WHERE**: `Sources/CodexSkillManager/Skills/SkillsContentView.swift`
**WHAT**:
1. `.task` to load skills and remoteStore.loadLatest()
2. `.onChange` for store selections
3. `.onChange` for searchText when .clawdhub
**VERIFY**: `swift build`

### 3.9.1 Add search bar to MainSplitView
**WHERE**: `Sources/CodexSkillManager/App/MainSplitView.swift`
**WHAT**: `.searchable` with binding, active only when .skills selected
**VERIFY**: `swift build`

### 3.9.2 Add minimal toolbar (Add Skill)
**WHERE**: `Sources/CodexSkillManager/App/MainSplitView.swift`
**WHAT**: Show when .skills selected, toggle showingImport
**VERIFY**: `swift build`

### 3.9.3 Add Open folder + Download toolbar items
**WHERE**: `Sources/CodexSkillManager/App/MainSplitView.swift`
**WHAT**: Port from SkillSplitView
**VERIFY**: `swift build`

### 3.10 Switch app entry point to MainSplitView
**WHERE**: `Sources/CodexSkillManager/App/CodexSkillManagerApp.swift`
**WHAT**: Replace SkillSplitView with MainSplitView. Create AppModel. Inject environments:
- `.environment(appModel)`
- `.environment(appModel.skillStore)`
- `.environment(appModel.remoteSkillStore)`
- `.environment(appModel.settings)`
**VERIFY**: `swift build` and `swift run`

### 3.11 Delete SkillSplitView
**DELETE**: `Sources/CodexSkillManager/Skills/SkillSplitView.swift`
**VERIFY**: `swift build`

### 3.12.1 Create RepoSettingsView
**CREATE**: `Sources/CodexSkillManager/Repos/RepoSettingsView.swift`
**WHAT**: Minimal UI bound to SettingsStore.watchedDirectories with add/remove
**VERIFY**: `swift build`

### 3.12.2 Integrate RepoSettingsView into Repos placeholder
**WHERE**: `Sources/CodexSkillManager/App/MainSplitView.swift`
**WHAT**: For .repos, add toolbar Settings button presenting RepoSettingsView as sheet
**VERIFY**: `swift build`

---

## Phase 4 — Extensions Section (Pi Agent Only)

### 4.0 Verify Extensions directory exists
**WHAT**: Ensure `Sources/CodexSkillManager/Extensions/` exists
**VERIFY**: `swift build`

### 4.1 Create Extension model
**CREATE**: `Sources/CodexSkillManager/Models/Extension.swift`
**WHAT**: `struct Extension: Identifiable, Hashable, Sendable` with name, folderURL, entryPoint, providedTools, providedCommands, isEnabled
**VERIFY**: `swift build`

### 4.2 Create ExtensionFileWorker
**CREATE**: `Sources/CodexSkillManager/Workers/ExtensionFileWorker.swift`
**WHAT**: `actor ExtensionFileWorker` with `scanExtensions(at:)` and regex parsing for tools/commands
**VERIFY**: `swift build`

### 4.3 Create CodeView
**CREATE**: `Sources/CodexSkillManager/Shared/CodeView.swift`
**WHAT**: Scrollable monospace code viewer with ScrollView and monospaced Text
**VERIFY**: `swift build`

### 4.4 Create ExtensionStore
**CREATE**: `Sources/CodexSkillManager/Extensions/ExtensionStore.swift`
**WHAT**: `@Observable @MainActor final class ExtensionStore` with extensions array, selectedExtensionID, load from piExtensionsURL
**VERIFY**: `swift build`

### 4.5 Add ExtensionStore to AppModel + environment
**WHERE**: `Sources/CodexSkillManager/App/AppModel.swift`, `CodexSkillManagerApp.swift`
**WHAT**: Add `let extensions: ExtensionStore`, inject via environment
**VERIFY**: `swift build`

### 4.6 Create ExtensionsContentView
**CREATE**: `Sources/CodexSkillManager/Extensions/ExtensionsContentView.swift`
**WHAT**: List extensions, bind selection. Agent filter: show list if selectedAgents empty or contains .pi, else show "Select Pi Agent to view extensions"
**VERIFY**: `swift build`

### 4.7 Create ExtensionsDetailView
**CREATE**: `Sources/CodexSkillManager/Extensions/ExtensionsDetailView.swift`
**WHAT**: Show extension info + source code using CodeView
**VERIFY**: `swift build`

### 4.8.1 Wire Extensions into MainSplitView
**WHERE**: `Sources/CodexSkillManager/App/MainSplitView.swift`
**WHAT**: Add .extensions content/detail routing
**VERIFY**: `swift build`

### 4.8.2 Add Extensions toolbar items
**WHERE**: `Sources/CodexSkillManager/App/MainSplitView.swift`
**WHAT**: When .extensions selected, show Refresh and Open in Finder buttons
**VERIFY**: `swift build`

### 4.9 Add extensions lifecycle load
**WHERE**: `Sources/CodexSkillManager/Extensions/ExtensionsContentView.swift`
**WHAT**: `.task { await extensionStore.load() }`
**VERIFY**: `swift build`

---

## Success Criteria (After Phase 4)

- [ ] Pi Agent skills appear alongside other agents
- [ ] Can navigate between all 5 sidebar sections
- [ ] Skills section works with 3-column layout
- [ ] Agent filter filters Skills list when non-empty
- [ ] Extensions section lists Pi Agent extensions
- [ ] Extensions shows "Select Pi Agent" when filtered out
- [ ] CodeView displays TypeScript source
- [ ] ConfirmationOverlay used for skill install
- [ ] RepoSettingsView accessible from Repos toolbar
- [ ] App renamed to "Agent Config Manager"
- [ ] Publish state migrated from legacy folder

---

## Files Summary (Phases 1-4)

| Action | Count | Key Files |
|--------|-------|-----------|
| CREATE | 22 | AgentID, AgentConfig, AgentConfigPaths, SettingsStore, NavigationSection, AppModel, SidebarView, MainSplitView, SkillsSectionStore, SkillsContentView, SkillsDetailView, RemoteInstallSheet, ConfirmationOverlay, PlaceholderViews, RepoSettingsView, Extension, ExtensionFileWorker, CodeView, ExtensionStore, ExtensionsContentView, ExtensionsDetailView |
| MODIFY | 5 | SkillPlatform, SkillStore, SkillSplitView (then delete), CodexSkillManagerApp, AppModel |
| DELETE | 1 | SkillSplitView.swift |

---

## Remaining Phases (5-9)

After Phase 4 is complete and verified:
- **Phase 5**: Commands section
- **Phase 6**: AGENTS.md section + SymlinkWorker
- **Phase 7**: Repos section + RepoScanWorker
- **Phase 8**: Wizards (Migration, Symlink)
- **Phase 9**: Rename package + final polish

These will follow the same YOLO-safe pattern established in Phases 1-4.

---

## Final YOLO-Hardening Fixes (from Plan Review)

### Fix A: Make AgentConfigPaths explicitly used
- **Phase 2.4**: Use `AgentConfigPaths` for URL construction in AgentConfig
- **Phase 4.4**: Load from `AgentConfigPaths.piExtensionsURL`

### Fix B: RemoteInstallSheet hosting explicit
- **Phase 3.9.3**: MainSplitView owns `.sheet(item: $appModel.skills.installSkill)` presentation. Boolean/item stored in SkillsSectionStore.

### Fix C: Split large steps

#### 3.3 Split into:
- **3.3a**: Create SkillsContentView with minimal List placeholder. VERIFY: `swift build`
- **3.3b**: Wire local skills list + selection binding. VERIFY: `swift build`
- **3.3c**: Wire remote skills list + selection binding. VERIFY: `swift build`
- **3.3d**: Add agent filter logic. VERIFY: `swift build`

#### 3.9.3 Split into:
- **3.9.3a**: Add Open Folder button (local only). VERIFY: `swift build`
- **3.9.3b**: Add Download button (remote only). VERIFY: `swift build`
- **3.9.3c**: Add RemoteInstallSheet presentation. VERIFY: `swift build`

### Fix D: Agent toggle semantics
- **Empty selectedAgents = All agents** (show everything)
- **SidebarView**: Add "All Agents" toggle at top that clears the set
- When any specific agent is selected, "All Agents" is deselected
- Document this in SidebarView implementation (Phase 2.8)

---

## Updated Task Count (Phases 1-4)

With splits applied:
- Phase 0: 1 task
- Phase 1: 6 tasks  
- Phase 2: 9 tasks
- Phase 3: 18 tasks (was 15, now split)
- Phase 4: 10 tasks

**Total: 44 atomic tasks for Phases 0-4**

Each task is 5-15 minutes and ends with `swift build` verification.

---

## Plan Status: YOLO-READY ✅

This plan has been:
1. ✅ Expert reviewed for architecture (rp-cli plan mode)
2. ✅ Expert reviewed for YOLO-safety (rp-cli plan mode)  
3. ✅ All gaps identified and fixed
4. ✅ Tasks split to atomic 5-15 min size
5. ✅ Every task has swift build verification
6. ✅ No orphaned files
7. ✅ Environment injection explicit
8. ✅ Directory creation handled
9. ✅ Agent filter applied where needed
10. ✅ ConfirmationOverlay integrated
11. ✅ RepoSettingsView integrated
12. ✅ Application Support migration addressed

Ready for execution.
