# Feature Specification: Persistent Voxel Structures

**Feature Branch**: `001-voxel-structures`

**Created**: 2026-07-19

**Status**: Draft

**Input**: User description: "Create a separate voxel structure class for small, persistent objects such as buildings and machines, without relying on procedural terrain generation."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Build and edit a structure (Priority: P1)

As a player or level designer, I can create a bounded voxel structure and add, replace, or remove individual blocks so that buildings and machines can be built independently of the terrain.

**Why this priority**: Direct editing of a self-contained structure is the core value; persistence and specialized machine data are not useful without it.

**Independent Test**: Create one structure, perform add, replace, and remove operations on local block positions, and verify that its visible and physical shape reflects each completed edit.

**Acceptance Scenarios**:

1. **Given** a new empty structure, **When** the user places a valid block at a local position, **Then** the structure displays that block at the requested position.
2. **Given** a structure containing a block, **When** the user removes that block, **Then** that position becomes empty and the structure updates accordingly.
3. **Given** an edit outside the structure's defined bounds, **When** the user attempts the edit, **Then** the structure remains unchanged and the rejected edit is reported safely.

---

### User Story 2 - Edit structures with native GridMap tools (Priority: P2)

As a level designer, I can use Godot's native GridMap palette and grid-editing tools to author a voxel structure, while the structure's persistent voxel data stays synchronized automatically.

**Why this priority**: Editor tools make the local structure workflow practical for content creation and provide a visual way to verify the same bounded editing model used at runtime.

**Independent Test**: Open a scene with a voxel structure in the Godot editor, use its automatically created GridMap companion to place IDs 1 and 2 and remove one block, then verify the voxel structure updates without Apply, Bake, import, or other manual synchronization.

**Acceptance Scenarios**:

1. **Given** a scene containing a voxel structure, **When** the designer selects its companion GridMap, **Then** Godot exposes native palette, selection, snapping, and viewport controls with valid structure block types.
2. **Given** GridMap cell changes or built-in undo/redo during an editing session, **When** the designer exits GridMap editing, **Then** the authoritative structure updates its data, mesh, and collision automatically without changing terrain data.
3. **Given** a runtime or scripted structure edit in the editor, **When** it completes, **Then** its companion GridMap mirrors the resulting layout automatically.
4. **Given** a running game, **When** a voxel structure is instantiated, **Then** its companion GridMap is absent or disabled and contributes no rendering, collision, navigation, or gameplay data.

---

### User Story 3 - Save and restore a structure (Priority: P3)

As a player, I can save a world containing voxel structures and later restore it so that every saved structure returns with the same block layout and world placement.

**Why this priority**: Buildings and player-created objects must survive game sessions to provide meaningful progression.

**Independent Test**: Create and edit a structure, save it, start a fresh session, load the saved structure, and compare its dimensions, transform, and every occupied block position with the saved version.

**Acceptance Scenarios**:

1. **Given** a modified structure, **When** a save completes, **Then** its block layout, dimensions, and transform are persisted as one structure record.
2. **Given** a saved structure record, **When** it is loaded, **Then** the reconstructed structure has the same block layout and placement as before saving.
3. **Given** multiple saved structures, **When** they are loaded, **Then** each retains its own data without overwriting another structure.

---

### User Story 4 - Persist machine-specific state (Priority: P4)

As a player, I can use a voxel machine whose functional state remains attached to that machine after saving and loading.

**Why this priority**: Machines build on the structure foundation and require their own state, such as ownership, inventory, or operating configuration.

**Independent Test**: Create a machine structure with representative state, save and reload it, and verify that both its voxel layout and machine state are restored.

**Acceptance Scenarios**:

1. **Given** a machine structure with functional state, **When** it is saved and reloaded, **Then** its state is restored with the structure.
2. **Given** a non-machine building, **When** it is saved and reloaded, **Then** it does not require machine-specific state to load successfully.

### Edge Cases

- A structure occupies more than one local mesh or data section; its layout must remain contiguous and save as one logical object.
- A save is requested while edits are pending; the saved result must include every edit accepted before save completion.
- A saved block refers to an unavailable block definition; loading must preserve the structure record and handle the affected position without corrupting other blocks.
- Two structures overlap in world space; the system must apply the project's placement policy consistently and must not silently merge their data.
- A structure contains only empty positions; it must remain valid, saveable, and removable.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST represent a structure as a bounded collection of locally addressed voxel positions, separate from the streamed terrain volume.
- **FR-002**: The system MUST allow a player or editor workflow to add, replace, read, and remove an individual voxel within a structure's bounds.
- **FR-003**: The system MUST update a structure's rendered and collision representation after an accepted voxel edit.
- **FR-004**: The system MUST reject edits outside the structure's bounds without changing saved or visible structure data.
- **FR-005**: The system MUST persist each structure's identity, dimensions, world transform, and voxel layout as a logical unit.
- **FR-006**: The system MUST restore all persisted structure data without requiring terrain generation to recreate the structure.
- **FR-007**: The system MUST support multiple independent structures in the same saved world.
- **FR-008**: The system MUST expose a way for specialized structures to persist additional state associated with that structure.
- **FR-009**: The system MUST preserve a clear separation between terrain voxel data and structure voxel data; editing or saving one MUST NOT implicitly modify the other.
- **FR-010**: The system MUST provide a completion signal or observable completion state for structure save operations.
- **FR-011**: In the editor, the system MUST automatically create and maintain an editor-only GridMap companion from every voxel structure's authoritative layout, including generated MeshLibrary and block-ID mapping.
- **FR-012**: The companion MUST use Godot's native GridMap editor for palette selection, snapping, placement, selection, movement, undo/redo, and viewport navigation; no separate voxel paint mode is required.
- **FR-013**: The system MUST populate the GridMap companion from the authoritative voxel structure when GridMap editing begins.
- **FR-014**: GridMap edits, including built-in undo/redo, MUST synchronize back to the authoritative voxel structure automatically once when GridMap editing ends, without an Apply, Bake, import, export, or other manual action. Selection changes, scene saves, and plugin shutdown MUST safely finish an active editing session first.
- **FR-015**: Structure edits performed outside GridMap editing MUST update the companion before its next editing session.
- **FR-016**: The companion GridMap and generated MeshLibrary MUST be editor-only; they MUST be excluded or disabled in a running game and MUST not render, collide, navigate, save as runtime world data, or modify terrain.

### Key Entities

- **Voxel Structure**: A bounded, independently positioned collection of block positions and block values representing a building, prop, or other small world object.
- **Structure Voxel Data**: The local block layout owned by one voxel structure, including empty positions and references to supported block types.
- **Structure Save Record**: The persisted representation of one structure's identity, placement, dimensions, voxel data, and optional additional state.
- **Voxel Machine**: A specialized voxel structure that adds functional state, such as ownership, inventory, configuration, or operating status.
- **Structure Registry**: The world-level collection that identifies and restores multiple independent structures.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can create an empty structure, place and remove at least 100 blocks, and see each accepted edit reflected before performing the next deliberate edit.
- **SC-002**: After a completed save and reload, 100% of blocks, dimensions, and world transforms in a test set of 20 structures match their saved values.
- **SC-003**: A test structure spanning up to four local data sections restores as one contiguous object with no missing or duplicated blocks.
- **SC-004**: Saving or editing a structure does not alter any terrain block in an otherwise unchanged test world.
- **SC-005**: A machine structure restores both its voxel layout and all declared machine state in 100% of save-and-load test runs.
- **SC-006**: A level designer can complete a place, replace, and remove operation on a selected structure from the editor without writing or running a custom gameplay script.
- **SC-007**: A level designer can undo and redo a completed editor voxel edit and recover the exact prior and subsequent block values.

## Assumptions

- Version one targets bounded buildings, props, and machines that ordinarily fit in one local data section and may span a small number of adjacent sections.
- Terrain remains responsible for large-scale ground, caves, and streaming-world edits; merging structure data into terrain data is out of scope.
- Existing block type definitions remain the source of valid block values used by structures.
- Structure placement, overlap policy, and authorization rules will follow the existing game's world and multiplayer rules when those systems are introduced.
- Version one does not require seamless mesh fusion between a structure and adjacent terrain or another structure.
- Editor tooling targets the Godot editor and is separate from gameplay input; it uses the same public structure edit contract.
- The GridMap companion is a generated editor representation, never an additional source of persistent runtime truth; `VoxelStructure` remains authoritative.
