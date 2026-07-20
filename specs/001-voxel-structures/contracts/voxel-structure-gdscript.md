# Voxel Structure Contract

This contract defines the project-facing behavior of the local voxel structure subsystem. Names are planning-level contracts; implementation may refine parameter types while preserving the stated behavior.

## `VoxelStructure`

### Initialization

`initialize(structure_id, dimensions, transform, initial_data)`

- Creates bounded chunked local voxel data with all unspecified positions and unallocated chunks set to air.
- Applies the supplied transform without modifying terrain.
- Produces a renderable and collidable representation, including an empty representation when no solid blocks exist.
- Fails safely if dimensions or initial data are invalid.

### Local reads and edits

`get_block(local_position) -> block_id`

- Returns the block type at a valid local position.
- Must not expose padded meshing cells.

`set_block(local_position, block_id) -> accepted`

- Replaces the block at a valid local position, including block ID 0 to remove it.
- Rejects invalid positions or unavailable block IDs without mutating state.
- On acceptance, marks the structure dirty and refreshes the affected chunk plus any face-neighbor chunk representations whose boundary can change.

`is_in_bounds(local_position) -> bool`

- Returns whether a public local coordinate can be edited.

`get_chunk_coordinate(local_position) -> chunk_coordinate`

- Internal helper that maps a valid public coordinate to its owning chunk.
- Public gameplay and editor callers do not need to use chunk coordinates.

## Godot GridMap companion plugin

`begin_gridmap_edit(structure) -> GridMap`

- Creates or reuses the structure's generated editor-only companion and MeshLibrary.
- Replaces its cells from the current authoritative structure layout, then returns/selects it for Godot's native GridMap editor.
- Does not rebuild the structure while the resulting session remains active.

`end_gridmap_edit(reason) -> accepted`

- Reads all used GridMap cells and translates MeshLibrary item IDs to valid structure block IDs.
- If the final layout differs from the session baseline, replaces the structure layout in one operation and performs one mesh/collision rebuild.
- Runs automatically on companion deselection, scene save, plugin disable, or editor shutdown; it never requires a designer command.
- Must not access or modify `VoxelTerrain` or `VoxelLodTerrain` data.

`invalidate_companion(structure)`

- Marks a companion stale after a runtime or scripted `VoxelStructure` edit.
- The next `begin_gridmap_edit` hydrates it from the new authoritative layout.

### Persistence

`to_save_record() -> StructureSaveRecord`

- Produces a complete, self-contained record of identity, dimensions, a `saved_global_transform` snapshot of the inherited `Node3D.global_transform`, non-empty chunk layouts, and additional state.

`load_from_save_record(record) -> accepted`

- Validates schema, chunk coordinates, extents, and payloads before replacing existing local data. The current flat payload format is not required to load.
- On success, restores `saved_global_transform` onto the structure, rebuilds the local representation, and leaves terrain untouched.
- On failure, leaves the current structure state unchanged and returns a usable error result.

`save_completed(success)` signal/event

- Reports the result of a requested save for this structure.
- Clears `dirty` only for a successful save that includes the current edit revision.

## `StructureRegistry`

`register(structure) -> accepted`

- Requires a unique structure identifier.
- Does not merge or overwrite a different registered structure implicitly.

`save_all() -> completion`

- Requests saves for every dirty registered structure.
- Completion is successful only after every included structure has completed saving.

`load_all() -> result`

- Restores all valid structure records from the selected world save.
- A malformed record must be reported without preventing unrelated valid structures from loading.

## `VoxelMachine`

`get_additional_save_state() -> serializable_state`

`load_additional_save_state(serializable_state) -> accepted`

- Extends the base structure save contract without duplicating block-layout persistence.
- A non-machine `VoxelStructure` need not provide machine state.
