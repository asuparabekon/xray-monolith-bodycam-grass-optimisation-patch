# PiP Grass Optimization (Bodycam engine)

Optional grass shaders for the Bodycam X-Ray engine (a Monolith fork that carries PiP). They let the engine draw grass with one hardware-instanced call per detail model instead of the batched constant-buffer path, and add a depth-only grass shadow element for the sun cascades.

Built on **Screen Space Shaders 23**. Without this mod the engine falls back to the batched grass path on its own (it probes the grass shaders at level load), so nothing breaks.

## What it contains

| File | Change against SSS 23 / Anomaly |
| --- | --- |
| `deffer_grass.vs` | Instanced branch (`DETAILS_INSTANCING`: 32-byte instance record, quaternion basis, octahedral normal), per-draw fade (mode 3) and the bender early-out. The non-instanced branch is SSS 23 plus the early-out |
| `deffer_detail_s_flat.vs`, `deffer_detail_w_flat.vs` | Instanced branch with fade mode 3; the non-instanced branch is SSS 23 / vanilla unchanged |
| `dt_instance_decode.h` | The instance record and its bindings |
| `deffer_tree_branch_flat.vs`, `deffer_tree_branch_bump-hq.vs` | SSS 23 plus the bender early-out (output-identical) |
| `details_blend.s`, `deffer_grass_smap_depth.ps` | The `l_point` depth-only grass shadow element, used when `r__grass_smap_element 1` (default) |

[PROVENANCE.md](PROVENANCE.md) lists every file with its upstream.

## Install (Mod Organizer 2)

1. Install the Bodycam engine release.
2. Install this zip as a mod named **PiP Grass Optimization**.
3. Give it a **higher priority** than Screen Space Shaders 23, Enhanced Shaders (KennShade) and Grass Tweaks.
4. Clear `appdata\shaders_cache`.

Console: `r__detail_instancing 1` (default, read at level load), `r__svp_grass_cull`, `r__sun_grass_cull`, `r__grass_smap_element`, `r__detail_density_knee`.

SSS 24 alpha ships `deffer_grass_lod.vs` with no instanced branch. Rebase this mod before using SSS 24.

## Build

`python tools/package.py` writes `dist/PiP Grass Optimization <version>.zip` (meta.ini, README.md, PROVENANCE.md and gamedata at the root, sorted with a fixed timestamp). `--stage DIR` also writes the mod folder into a new or empty DIR outside the checkout.

## Credits

- **PiP Grass Optimization Patch** (instancing branches, record decode, bender early-out, shadow element): TheLostInPlace (m22).
- **Screen Space Shaders**: Ascii1457.
- Per-draw fade and the Bodycam engine side: asuparabekon.
