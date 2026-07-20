# Implementation Plan: Persistent Voxel Structures

**Branch**: `001-voxel-structures` | **Date**: 2026-07-19 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/001-voxel-structures/spec.md`

## Summary

Add bounded, independently transformable voxel structures for buildings, props, and machines. Each structure owns chunked local block data, rebuilds only affected chunk representations and their boundary neighbors, and persists as one world object. In the editor, an automatically generated, editor-only GridMap companion provides Godot's native grid authoring UI and synchronizes bidirectionally with the authoritative structure data without user intervention. The design deliberately keeps this data separate from streamed `VoxelLodTerrain` terrain data and its procedural generation.

## Technical Context

**Language/Version**: GDScript on Godot 4.7

**Primary Dependencies**: Godot scene, `GridMap`, `MeshLibrary`, editor-plugin, resource, mesh, collision, and file APIs; locally built Zylann Voxel Tools module; existing `VoxelBlockyLibrary` and `VoxelMesherBlocky` resources

**Storage**: Versioned project-owned structure save files under `user://`; each record contains metadata plus the non-empty chunk coordinates, extents, and type-channel payloads for one structure

**Testing**: Godot headless project load for syntax/integration checks; focused GDScript tests or a dedicated validation scene for edit, mesh/collision, and save/load round trips

**Target Platform**: Windows desktop prototype, with exported-game save paths supported through `user://`

**Project Type**: Godot game project within the `ProjectV/` submodule

**Performance Goals**: Interactive single-voxel edits must rebuild only the edited chunk and any face-neighbor chunks affected at a boundary; a 16×16×16 chunk must complete an edit-to-visible update within one rendered frame under normal prototype load

**Constraints**: Structures are bounded, use blocky type IDs from `MinecraftVoxelLibrary.tres`, retain a one-voxel air padding around each meshing chunk, and must not alter terrain data. A structure is partitioned into fixed-size internal chunks while retaining one public local coordinate space, rigid body, and save record. The new chunked format does not need to read the current flat payload.

**Chunk representation**: Each non-empty chunk receives a generated mesh and collision representation beneath the structure rigid body. Meshing samples neighbor chunks through its padding so shared faces are culled. Collision uses merged solid boxes that cover the blocky occupied volume; this avoids a concave moving-body collider and avoids one physics shape per voxel.

**Scale/Scope**: Single-player first; at least 20 independently saved structures, including one spanning at least four chunks. The editor tooling covers local voxel placement, replacement, and removal for a selected structure. Connectivity splitting, dynamic fragment physics, seamless terrain fusion, and multiplayer replication are out of scope.

**Editor UX model**: Use Godot's native `GridMap` editor as an invisible implementation detail of each selected structure. A `@tool` synchronization component creates a non-runtime companion GridMap and generated MeshLibrary from `VoxelStructure` data; selecting that companion begins an editing session and gives the designer Godot's palette, snapping, selection, movement, undo/redo, and viewport navigation directly. The companion is populated when the session begins and its complete layout is committed back to `VoxelStructure` once when the session ends. There is no Apply, Bake, import, export, custom paint mode, or runtime GridMap rendering.

## Constitution Check

The current constitution is an uncustomized template and defines no enforceable project principles or gates. No constitutional violation is identified. The design remains deliberately small: one local structure abstraction, one save-record format, and reuse of existing block resources.

**Post-design check**: Passed. The selected design adds no new external service, duplicate terrain system, or unbounded streaming mechanism.

## Project Structure

### Documentation (this feature)

```text
specs/001-voxel-structures/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── voxel-structure-gdscript.md
└── tasks.md                 # Created later by /speckit-tasks
```

### Source Code (repository root)

```text
ProjectV/
├── Scenes/
│   └── VoxelStructure.tscn              # Reusable structure scene; companion is generated in editor
├── addons/voxel_structure_editor/
│   ├── plugin.cfg                       # Godot editor plugin descriptor
│   └── voxel_structure_editor_plugin.gd # Companion lifecycle, selection, and session-boundary commits
├── Scripts/
│   ├── voxel_structure.gd               # Local voxel ownership, editing, remeshing
│   ├── voxel_structure_gridmap_sync.gd   # Editor-only GridMap generation and session synchronization
│   ├── voxel_machine.gd                 # Optional machine specialization
│   └── structure_save_service.gd        # World-level save/load coordination
├── Resources/
│   └── structure_save_record.gd         # Versioned persisted record
├── MinecraftVoxelLibrary.tres           # Existing block IDs: 0 air, 1 grass, 2 log
└── VoxelMesherBlocky.tres               # Existing blocky mesher and library binding
```

**Structure Decision**: Add a focused `ProjectV` structure subsystem rather than extending `VoxelLodTerrain`. It consumes the existing block library and mesher, while owning a sparse set of local chunks, rendering, collision, persistence, and a generated GridMap authoring mirror independently. Chunk coordinates and meshing padding remain internal details.

## Complexity Tracking

No constitution-driven complexity exceptions are required.

## Replacement and Removal Plan

The current custom viewport-edit implementation is not retained. Before adding the companion workflow, remove the custom toolbar/panel, mouse raycast editing, hover-cell preview, temporary per-block selection node, and custom gizmo plugin. Remove their plugin registration and scene references as well. The replacement is deliberately a clean start: the new editor plugin is responsible only for companion creation, synchronization, visibility, and editor selection; Godot's GridMap editor owns all block-authoring input and undo/redo.

## Synchronization Design

`VoxelStructure` is the sole runtime and save authority. In editor context it owns a generated `GridMap` child marked editor-only, with a generated `MeshLibrary` mapped one-to-one from valid structure block IDs. The synchronizer uses an explicit editing-session state and a re-entrancy guard:

1. On GridMap companion selection, finish any prior session, then populate its cells from authoritative voxel data and mark the session active.
2. Allow GridMap to own all editing and undo/redo during the active session; do not synchronize or remesh on individual cell edits.
3. On companion deselection, selection of another structure, scene save, plugin disable, or editor shutdown, read the complete GridMap layout once, replace the authoritative layout in one operation, and rebuild only the changed chunk representations and their affected boundary neighbors.
4. Structure-side edits invalidate the companion cache and are reflected the next time that companion is selected.
5. Never run the companion or synchronization in a game; it is removed/disabled before runtime serialization and excluded from save records.

GridMap exposes cell reads and writes but no public per-cell mutation signal. Session-boundary synchronization avoids needing one while preserving built-in GridMap undo/redo.

When a completed GridMap layout differs from its baseline, the synchronizer identifies changed chunks and refreshes those chunks plus only boundary neighbors whose visible faces can change.
