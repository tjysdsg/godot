# Data Model: Persistent Voxel Structures

## VoxelStructure

The runtime scene object representing one bounded building, prop, or other local voxel object.

| Field | Description | Validation |
|---|---|---|
| `structure_id` | Stable unique world identifier. | Required; unique within a loaded world. |
| `dimensions` | Public editable dimensions in local voxel coordinates. | Every axis is positive; version-one size remains within configured local-section limits. |
| `global_transform` | Runtime world placement and orientation inherited from `Node3D`. | Finite transform; placement policy is applied before insertion. It is not separately stored by the structure model. |
| `type_data` | Type value for every public voxel position. | Each value resolves to a supported block definition; 0 means air. |
| `dirty` | Indicates edits not yet captured in a completed save. | Cleared only after the current record is written successfully. |
| `additional_state` | Optional serializable state supplied by a specialized structure. | Must be serializable and version-compatible. |

### State transitions

```text
new -> initialized -> clean
clean -> edited -> dirty
dirty -> save requested -> saving
saving -> complete -> clean
saving -> failure -> dirty
clean or dirty -> unload -> removed
```

An accepted edit transitions the structure to `dirty`; an out-of-bounds or otherwise rejected edit leaves its state unchanged.

## StructureSaveRecord

The versioned persisted representation of one structure.

| Field | Description | Validation |
|---|---|---|
| `format_version` | Save schema version. | Required; loader accepts supported versions or reports an actionable migration error. |
| `structure_id` | Identifier of the represented structure. | Required and non-empty. |
| `dimensions` | Public editable dimensions. | Matches payload dimensions. |
| `saved_global_transform` | Snapshot of the structure's `Node3D.global_transform` at save time. | Finite values; restored onto the newly instantiated structure before it is registered. |
| `block_type_payload` | Serialized local type-channel data. | Exact expected byte length for dimensions and configured type depth. |
| `additional_state` | Optional machine/specialization state. | Serializable; unknown optional fields are ignored safely where possible. |

The padding cells used for meshing are runtime-only and are not part of the saved public layout.

## VoxelMachine

A `VoxelStructure` specialization with behavior-specific state.

| Field | Description | Validation |
|---|---|---|
| `machine_kind` | Declares the machine behavior family. | Required for machine records. |
| `machine_state` | Serializable behavior-specific state. | Validated by the owning machine type. |

`VoxelMachine` shares the structure identifier, voxel data, runtime `global_transform`, dirty state, and save record lifecycle with `VoxelStructure`.

## StructureRegistry

The world-level collection responsible for locating and restoring independent structures.

| Field | Description | Validation |
|---|---|---|
| `structures_by_id` | Loaded structures keyed by identifier. | No duplicate keys. |
| `save_location` | World save location for structure records. | Writable game-save location; separate from terrain stream storage. |

## GridMapCompanion

An editor-only, generated `GridMap` child that mirrors a structure while it is being authored. It is never a runtime or save-data authority.

| Field | Description | Validation |
|---|---|---|
| `owner_structure` | The `VoxelStructure` whose layout it represents. | Required; exactly one companion per owner in editor context. |
| `mesh_library` | Generated `MeshLibrary` mapping each supported block ID to its authoring mesh. | Regenerated when valid block definitions change; never used at runtime. |
| `editor_only` | Exclusion flag/lifecycle state. | Must disable or remove rendering, collision, navigation, processing, and serialization in a running game. |

## StructureEditorSession

The editor-only session that batches a GridMap authoring pass. It is not part of a world save.

| Field | Description | Validation |
|---|---|---|
| `selected_companion` | The GridMap companion currently being edited. | Must be generated for a structure in the open scene. |
| `structure` | The authoritative owner of the selected companion. | Required for an active session. |
| `active` | Whether the companion has been hydrated and may accept GridMap edits. | At most one active session at a time. |
| `baseline_layout` | Snapshot/hash copied into GridMap when the session began. | Used to skip a rebuild if the user made no final change. |

## Relationships

```text
StructureRegistry 1 ── contains ── 0..* VoxelStructure
VoxelStructure     1 ── persists as ── 1 StructureSaveRecord
VoxelMachine       is a ── VoxelStructure
VoxelMachine       1 ── stores ── 0..1 machine state payload
VoxelStructure         1 ── has (editor only) ── 0..1 GridMapCompanion
StructureEditorSession 1 ── commits ── 0..1 VoxelStructure
```
