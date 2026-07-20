# Research: Persistent Voxel Structures

## Decision: Use a sparse collection of local chunks as the authoritative block layout for each structure

**Rationale**: Chunked local storage keeps structures independent of terrain streaming while allowing a large bounded object to update locally. Each chunk owns a bounded voxel buffer, and the structure maps public local coordinates to those chunks. Missing chunks read as air, so empty regions need not allocate data. An edit rebuilds its own chunk and only neighbors whose shared faces can change.

**Alternatives considered**:

- `VoxelTerrain` or `VoxelLodTerrain`: appropriate for large streamed terrain, but their data loading and generator fallback behavior introduce unnecessary complexity for local objects.
- A single structure-wide dense buffer: straightforward for small props, but requires whole-object rebuilding and does not scale local edits for large structures.
- A custom sparse dictionary of block positions: potentially smaller for nearly empty objects, but requires custom meshing input construction and complicates routine edits.

## Decision: Reuse `VoxelMesherBlocky` and the existing block library for visual meshes

**Rationale**: `ProjectV/VoxelMesherBlocky.tres` is already bound to `MinecraftVoxelLibrary.tres`, where block ID 0 is empty and IDs 1 and 2 are the current solid blocks. The blocky mesher consumes `CHANNEL_TYPE`, removes occluded faces, and can build a mesh directly from a local buffer.

**Alternatives considered**:

- Construct cube meshes manually: duplicates library/material logic and loses face culling.
- Add structure voxels directly to terrain: prevents independent transforms and violates the required data boundary.

## Decision: Store a one-voxel air border around each meshing chunk

**Rationale**: Voxel Tools meshers treat outer buffer cells as neighbors. Each chunk mesh receives a padded buffer whose border samples adjacent chunks, so exterior faces are emitted correctly while faces between adjacent solid chunks remain culled. Public structure coordinates never expose padding.

**Alternatives considered**:

- No padding: exterior faces may be missing or incorrectly culled.
- Expose padded coordinates to callers: leaks renderer-specific details into gameplay and save data.

## Decision: Serialize non-empty chunks in a project-owned, versioned structure record

**Rationale**: Storing dimensions, transform, chunk coordinates, chunk extents, type payloads, record version, and optional machine state preserves one bounded save unit without depending on terrain streaming or a generator. The new format deliberately does not need to load the current flat type payload.

**Alternatives considered**:

- `VoxelStreamSQLite`: designed for terrain block streaming and asynchronous terrain saves. It is unnecessary for a small object owned by one scene.
- Save every occupied voxel as a list: easier to inspect, but larger and slower for ordinary solid buildings. It remains a future option for very sparse structure types.

## Decision: Rebuild affected chunk mesh and compound collision after accepted edits; defer dynamic fragments

**Rationale**: The initial feature requires visually and physically accurate local edits. Rebuilding one small object is bounded and isolates update cost. The project’s technical direction reserves connectivity analysis, detached fragments, and dynamic physics proxies for a later destruction vertical slice.

**Alternatives considered**:

- Reuse terrain collision: couples unrelated systems and prevents structures from moving independently.
- Dynamic triangle collision: excluded by the project technical direction for mutable/dynamic objects.

## Decision: Use an automatically synchronized editor-only GridMap companion for authoring

**Rationale**: Godot's built-in GridMap editor already supplies palette selection, grid snapping, selection, movement, copy/paste, layer controls, viewport navigation, and undo/redo. `VoxelStructure` remains the authoritative runtime and persisted layout; the companion GridMap and MeshLibrary are generated from it only in editor context, are hidden from the game, and never enter runtime save records.

**Alternatives considered**:

- Custom direct viewport paint mode: conflicts with Godot navigation, selection, and gizmos, and duplicates mature GridMap interactions.
- Make `VoxelStructure` inherit `GridMap`: would make GridMap data the runtime representation and abandon Voxel Tools meshing/persistence.
- Manual Bake/Apply: adds a failure-prone step; the requested workflow must feel seamless.

## Decision: Synchronize automatically at GridMap editing-session boundaries

**Rationale**: The GridMap API exposes reads (`get_used_cells`, `get_cell_item`) and writes (`set_cell_item`), but no public per-cell-changed signal. Synchronizing every edit would require polling and repeatedly rebuild the structure mesh/collision. Instead, the synchronizer starts a session when its GridMap companion is selected: it populates the GridMap once from authoritative data, then lets Godot own all edits and undo/redo. On deselection, scene save, plugin disable, or editor shutdown, it reads the final layout once and updates the structure only if that layout differs. This requires no manual action and avoids feedback loops.

**Alternatives considered**:

- Per-edit or idle polling: unnecessary, increases editor work, and causes premature structure remeshing.
- Modify GridMap editor source to add a change signal: requires an engine fork and violates the no-source-modification constraint.

## Decision: Provide a base structure plus optional machine specialization

**Rationale**: A building only needs voxel data and placement. A machine additionally needs optional gameplay state such as ownership, inventory, configuration, or operating state. Keeping that state extensible avoids forcing machine concepts into every building while ensuring it shares the same save lifecycle.

**Alternatives considered**:

- Separate persistence system for machines: duplicates save logic and risks the block layout and machine state diverging.

## Sources inspected

- `modules/voxel/doc/source/api/VoxelBuffer.md`
- `modules/voxel/doc/source/api/VoxelMesher.md`
- `modules/voxel/doc/source/api/VoxelMesherBlocky.md`
- `ProjectV/MinecraftVoxelLibrary.tres`
- `ProjectV/VoxelMesherBlocky.tres`
- `ProjectV/technical-resources.md`
- `modules/gridmap/editor/grid_map_editor_plugin.cpp` and `.h`
- `modules/gridmap/grid_map.cpp` (cell mutation and available signals)
- [Godot GridMap workflow](https://docs.godotengine.org/en/stable/tutorials/3d/using_gridmaps.html)
- [Godot GridMapEditorPlugin API](https://docs.godotengine.org/en/stable/classes/class_gridmapeditorplugin.html)
