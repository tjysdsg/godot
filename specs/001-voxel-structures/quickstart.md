# Quickstart: Validate Persistent Voxel Structures

## Prerequisites

- Build or use the Godot editor executable from this repository with the `voxel` module enabled.
- Open `ProjectV/` as the Godot project.
- Confirm the existing blocky resources load: `MinecraftVoxelLibrary.tres` and `VoxelMesherBlocky.tres`.

## Validation scenario 1: Local editing

1. Open a validation scene containing one new voxel structure.
2. Initialize it with a 16×16×16 editable volume.
3. Place block IDs 1 and 2 at several valid local positions; remove one by assigning air (0).
4. Attempt one edit beyond the configured bounds.

Expected results:

- Valid edits appear only on the structure, and its collision updates with the visible block layout.
- The invalid edit is rejected and no terrain block changes.
- The structure reports that it has unsaved edits.

## Validation scenario 2: Native GridMap authoring

1. Enable the voxel-structure editor plugin and open a scene containing a voxel structure.
2. Select the structure normally, use its Inspector's **Edit GridMap** action, and verify the companion contains the same layout and exposes Godot's native GridMap palette.
3. Select block IDs 1 and 2 from the palette; place, remove, box-select, and move cells using normal GridMap controls.
4. Undo and redo multiple GridMap edits using Godot's normal history.
5. Use **Apply & Exit GridMap** in the 3D toolbar (or select another node) to end GridMap editing.
6. Verify the structure now has the final GridMap layout and has rebuilt mesh/collision exactly once.
7. Select the structure and use **Edit GridMap** again; verify the companion is hydrated with that authoritative layout.
8. Save the scene or disable the plugin with an active GridMap session; verify that pending GridMap edits commit automatically.
9. Run the scene and verify no companion GridMap mesh, collision, navigation, or data is active.

Expected results:

- Native GridMap controls provide palette selection, snapping, selection, movement, navigation, and undo/redo.
- No manual synchronization action is visible or required.
- The structure updates only as the GridMap editing session finishes, and terrain remains unchanged.
- Runtime has no active companion representation.

## Validation scenario 3: Save and load round trip

1. Create 20 structures with unique identifiers, positions, dimensions, and representative layouts.
2. Request a world structure save and wait for its completion result.
3. Start a new game session or clear the registry, then load the same save.
4. Compare each restored structure against its expected identifier, transform, dimensions, and occupied local positions.

Expected results:

- All 20 structures restore exactly once.
- Every saved block type and transform matches the expected value.
- Terrain state is unchanged by either operation.

## Validation scenario 4: Machine specialization

1. Create one machine structure with representative serializable machine state.
2. Save it alongside an ordinary building.
3. Reload both structures.

Expected results:

- The machine restores its block layout and its machine state.
- The ordinary building restores without requiring machine-specific fields.

## Validation scenario 5: Multi-chunk structure

1. Create a structure whose dimensions span at least four chunks.
2. Place blocks immediately on both sides of a chunk boundary, then edit one boundary block and one block well inside a chunk.
3. Save the structure, start a fresh session, and load it again.

Expected results:

- No internal mesh face appears between solid blocks across a chunk boundary, and collision covers the same occupied blocky volume.
- Boundary edits refresh only the changed chunk and affected neighbors; interior edits do not refresh unrelated chunks.
- The structure restores as one rigid object and one save record with no missing or duplicated blocks.

## Headless smoke check

After implementation, run the project editor headlessly from the repository root:

```powershell
& .\bin\godot.windows.editor.x86_64.console.exe --headless --editor --path .\ProjectV --quit
```

Expected result: the project loads without parse errors from the new structure scripts or resources.
