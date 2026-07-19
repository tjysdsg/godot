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
