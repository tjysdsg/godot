# Repository Guide

This repository combines the Godot engine source with the `ProjectV` game project.

## Layout

- `./` - Godot Engine source code. Engine changes belong in the usual Godot source
  directories, including `core/`, `scene/`, `servers/`, `editor/`, `platform/`,
  and `drivers/`.
- `ProjectV/` - the actual game project. This is a Git submodule at
  `git@github.com:tjysdsg/ProjectV.git`. Put game-specific assets, scenes,
  scripts, and project configuration here.
- `modules/voxel/` - the Godot Voxel module used by ProjectV. This is a Git
  submodule at `git@github.com:Zylann/godot_voxel.git`; it is compiled into this
  Godot checkout rather than living inside the game project.

## Submodules

`ProjectV/` and `modules/voxel/` are independent Git repositories tracked by
the root repository as submodules. When changing either one, commit its changes
within that submodule, then update the corresponding gitlink in this repository.
Use `git submodule update --init --recursive` after cloning the root repository
to populate them.

## Change Boundaries

Keep game work in `ProjectV/`. Change the engine root only for engine-level
needs, and change `modules/voxel/` only when the voxel module itself needs an
update or fix. Coordinate changes that require a particular engine, voxel-module,
and game-project revision by committing each repository separately and recording
the selected submodule commits in the root repository.
# Project workspace guide

`E:\godot` is the Godot engine source tree. `ProjectV/` is the actual game
project and `modules/voxel/` is the Voxel Tools engine module; both are git
submodules. Game changes normally belong under `ProjectV/`, while engine and
module changes need their own submodule-aware review.

## Voxel structures

`ProjectV/Scripts/voxel_structure.gd` is the authoritative bounded voxel data,
mesh, collision, and save source for a building or prop. `VoxelMachine` extends
it for machine-specific save state. Do not mix this data with `VoxelLodTerrain`.

The editor addon generates a `GridMap` companion only while working in the
editor. It is derived from `VoxelStructure` data, uses Godot's native GridMap
UX, commits once at editing-session boundaries, has no scene owner, and must
never be treated as runtime or persistent data. Keep custom viewport painting,
panels, and gizmo handling out of this workflow.

## Terrain safety boundary

Do not change `VoxelLodTerrain` or `VoxelTerrain` editor-streaming settings
(including `run_stream_in_editor`), generators, viewers, visibility, data, or
scene placement while working on voxel structures or their editor companion.
Those systems are independent. Modify them only when the user explicitly asks
for a terrain change.
