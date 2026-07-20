# Tasks: Persistent Voxel Structures

**Input**: Design documents from `/specs/001-voxel-structures/`

**Prerequisites**: [plan.md](plan.md), [spec.md](spec.md), [research.md](research.md), [data-model.md](data-model.md), [contract](contracts/voxel-structure-gdscript.md), and [quickstart.md](quickstart.md)

**Tests**: No automated TDD requirement was requested. Validate the editor integration with the scenarios in `quickstart.md` and the headless editor smoke check.

**Organization**: Tasks are grouped by user story. The GridMap companion is generated editor-only state; `VoxelStructure` remains the runtime and persistence authority.

## Phase 1: Setup and clean replacement

**Purpose**: Remove the rejected custom viewport UX before building the replacement.

- [X] T001 Remove the custom toolbar/panel, raycast paint mode, and custom input forwarding from `ProjectV/addons/voxel_structure_editor/voxel_structure_editor_plugin.gd`.
- [X] T002 [P] Remove the obsolete panel, custom gizmo, and temporary block-selection scripts/resources from `ProjectV/addons/voxel_structure_editor/`.
- [X] T003 Remove obsolete plugin references, generated-resource references, and old editor-specific nodes from `ProjectV/project.godot` and `ProjectV/Scenes/VoxelStructure.tscn`.
- [X] T004 Run the headless editor smoke check after the removal using `ProjectV/project.godot` and fix any stale script/resource references.

---

## Phase 2: Foundational structure and companion contracts

**Purpose**: Establish the batch-edit and editor-only lifecycle APIs that all stories depend on.

**⚠️ CRITICAL**: Complete this phase before GridMap authoring work.

- [X] T005 Extend `ProjectV/Scripts/voxel_structure.gd` with a validated bulk-layout replacement API that accepts public local block data, updates padding, marks dirty, and rebuilds mesh/collision once.
- [X] T006 Extend `ProjectV/Scripts/voxel_structure.gd` with a stable public-layout snapshot/hash API for comparing a complete GridMap session result without exposing padded cells.
- [X] T007 Create `ProjectV/Scripts/voxel_structure_gridmap_sync.gd` as an editor-only synchronizer with companion ownership, block-ID/item-ID mapping, active-session state, and re-entrancy protection.
- [X] T008 Update `ProjectV/Scenes/VoxelStructure.tscn` and `ProjectV/Scripts/voxel_structure.gd` so generated companions are created only in editor context and are disabled or removed before runtime rendering, collision, navigation, processing, and persistence.
- [X] T009 Verify local set/get/remove, invalid-coordinate rejection, and one-batch rebuild behavior in `ProjectV/Scenes/test.tscn` or a dedicated structure validation scene.

**Checkpoint**: The authoritative runtime structure has a safe batch layout contract and cannot accidentally run a companion in-game.

---

## Phase 3: User Story 1 - Build and edit a structure (Priority: P1) 🎯 MVP

**Goal**: Preserve bounded, independently rendered and collidable structure edits outside terrain.

**Independent Test**: Create an empty structure, add, replace, and remove blocks with the public structure API; verify visual/collision updates and out-of-bounds rejection.

- [X] T010 [US1] Update `ProjectV/Scripts/voxel_structure.gd` so single-cell edits and bulk-layout edits share validation, dirty-state, and rebuild behavior.
- [X] T011 [US1] Update `ProjectV/Scenes/test.tscn` with an isolated bounded structure validation fixture that proves terrain data is unchanged by structure edits.
- [X] T012 [US1] Run validation scenario 1 from `specs/001-voxel-structures/quickstart.md` and correct local-buffer, meshing, or collision regressions in `ProjectV/Scripts/voxel_structure.gd`.

**Checkpoint**: User Story 1 remains independently functional before editor authoring is added.

---

## Phase 4: User Story 2 - Edit structures with native GridMap tools (Priority: P2)

**Goal**: Replace custom voxel painting with seamless, session-boundary use of Godot's GridMap editor.

**Independent Test**: Select a structure, automatically enter its GridMap authoring session, edit and undo/redo with GridMap, select away, and observe one automatic authoritative structure update with no user Apply/Bake step.

- [X] T013 [US2] Implement generated `MeshLibrary` construction and valid voxel-ID ↔ GridMap-item mapping in `ProjectV/Scripts/voxel_structure_gridmap_sync.gd` using the project block resources.
- [X] T014 [US2] Implement generated editor-only GridMap companion creation, transform/dimension alignment, and stale-cache hydration in `ProjectV/Scripts/voxel_structure_gridmap_sync.gd`.
- [X] T015 [US2] Replace `ProjectV/addons/voxel_structure_editor/voxel_structure_editor_plugin.gd` with selection-driven session orchestration that automatically opens a structure's companion and delegates all authoring input to Godot's GridMap editor.
- [X] T016 [US2] Implement automatic session finalization on companion deselection and selection changes in `ProjectV/addons/voxel_structure_editor/voxel_structure_editor_plugin.gd`, committing the complete GridMap layout through the bulk structure API only when it differs from the session baseline.
- [X] T017 [US2] Add automatic active-session finalization for scene-save, plugin-disable, and editor-shutdown paths in `ProjectV/addons/voxel_structure_editor/voxel_structure_editor_plugin.gd`.
- [X] T018 [US2] Make all runtime or scripted changes invalidate the companion cache in `ProjectV/Scripts/voxel_structure.gd` and rehydrate it on the next authoring session through `ProjectV/Scripts/voxel_structure_gridmap_sync.gd`.
- [X] T019 [US2] Ensure the generated GridMap companion is internal/editor-only and invisible to gameplay in `ProjectV/Scripts/voxel_structure_gridmap_sync.gd` and `ProjectV/Scripts/voxel_structure.gd`.
- [X] T020 [US2] Run validation scenario 2 from `specs/001-voxel-structures/quickstart.md`, including palette IDs 1/2, snapping, movement, GridMap undo/redo, automatic exit commit, save-time flush, and no-runtime-companion verification.

**Checkpoint**: Godot GridMap owns authoring UX; no custom paint mode, gizmo, panel, or manual synchronization remains.

---

## Phase 5: User Story 3 - Save and restore a structure (Priority: P3)

**Goal**: Preserve authoritative structure layouts and placement independently of generated companions.

**Independent Test**: Save and load 20 structures after an authoring session; compare IDs, dimensions, transforms, and block layouts, and verify no GridMap companion data is part of the save.

- [X] T021 [US3] Update `ProjectV/Scripts/voxel_structure.gd` and `ProjectV/Resources/structure_save_record.gd` so save payloads are always derived from authoritative public layout and exclude companion/editor-session state.
- [X] T022 [US3] Update `ProjectV/Scripts/structure_save_service.gd` so a save request finishes any active authoring session before serializing structures.
- [X] T023 [US3] Verify loaded structures regenerate an editor companion only when later opened in the editor, not while the game is running, in `ProjectV/Scripts/voxel_structure_gridmap_sync.gd`.
- [X] T024 [US3] Run validation scenario 3 from `specs/001-voxel-structures/quickstart.md` and resolve round-trip or terrain-isolation failures.

**Checkpoint**: Structure persistence remains independent of GridMap and terrain.

---

## Phase 6: User Story 4 - Persist machine-specific state (Priority: P4)

**Goal**: Retain machine state while it uses the same authoritative structure and editor-companion lifecycle.

**Independent Test**: Save and reload a voxel machine authored through its companion and confirm both layout and machine state restore.

- [X] T025 [US4] Update `ProjectV/Scripts/voxel_machine.gd` to inherit the final bulk-layout, companion-invalidation, and save behavior without serializing editor-only state.
- [X] T026 [US4] Update `ProjectV/Scenes/VoxelMachine.tscn` and `ProjectV/Scenes/test.tscn` with a machine authoring/save fixture.
- [X] T027 [US4] Run validation scenario 4 from `specs/001-voxel-structures/quickstart.md` and correct machine save/load integration issues.

**Checkpoint**: Machines retain specialized state without diverging from the structure workflow.

---

## Phase 7: Polish and cross-cutting validation

**Purpose**: Confirm the replacement is clean, bounded, and maintainable.

- [X] T028 Review `ProjectV/addons/voxel_structure_editor/` and `ProjectV/project.godot` to confirm no old custom paint UX, panel, gizmo, block-selection handle, or stale resource reference remains.
- [X] T029 [P] Update `ProjectV/technical-resources.md` and `AGENTS.md` with the editor-only GridMap companion architecture and the rule that it is derived rather than runtime data.
- [X] T030 Run `git diff --check` for `ProjectV/` and `specs/001-voxel-structures/` and resolve whitespace or serialization issues.
- [X] T031 Run the headless editor smoke check from `specs/001-voxel-structures/quickstart.md` and fix parse/load errors in touched ProjectV files.
- [X] T032 Perform every applicable quickstart scenario in `specs/001-voxel-structures/quickstart.md` and record outcomes in the implementation handoff.

---

## Dependencies and execution order

- Phase 1 must finish before any replacement code is introduced.
- Phase 2 blocks all user-story work.
- US1 (Phase 3) validates the authoritative structure independently.
- US2 (Phase 4) depends on US1's stable batch-layout API.
- US3 (Phase 5) depends on US2 because saves must flush a session safely.
- US4 (Phase 6) depends on US3's final save contract.
- Polish follows all desired stories.

## Parallel opportunities

- T002 can proceed alongside T001 because it removes separate obsolete files.
- T005 and T007 can proceed in parallel after agreeing on the public layout contract.
- T013 and T015 can proceed in parallel after T007 establishes the synchronizer interface.
- T021 and T023 can proceed in parallel after US2 completes.
- T029 can proceed independently once the architecture is stable.

## Implementation strategy

1. Remove the rejected interaction system completely.
2. Establish and validate `VoxelStructure` as the sole mutable/persisted layout authority.
3. Deliver the GridMap authoring session as the next increment, with no manual conversion UI.
4. Verify persistence and machines only after editor sessions flush correctly.

All tasks use the required checklist format with IDs, paths, and user-story labels.
