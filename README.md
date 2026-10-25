# Bodycam Grass Optimisation

Optional grass shaders for the [Bodycam engine](https://github.com/asuparabekon/xray-monolith-bodycam), based
on Screen Space Shaders 23. They turn on TheLostInPlace's grass renderer, which is built into the engine: it
batches grass draws, keeps grass data on the GPU and skips grass that is hidden.

Without this mod the engine draws grass the old way.

## Install (Mod Organizer 2)

1. Install the Bodycam engine.
2. Install this zip as a mod named **Bodycam Grass Optimisation**.
3. Let it win file conflicts against Screen Space Shaders 23, Enhanced Shaders (KennShade) and Grass Tweaks.
4. Clear `appdata\shaders_cache`.

If you have the older **PiP Grass Optimization** mod, replace it instead of enabling both.

SSS 24 alpha adds `deffer_grass_lod.vs`, which has no instanced variant yet. Don't use this mod with SSS 24.

## Contents

| File | What it is |
| --- | --- |
| `deffer_grass.vs` | SSS 23 grass plus the bender early-out, with branches that read the instance rows and each blade's terrain normal and alpha |
| `deffer_grass_inst*.vs` | The five instanced variants the engine loads (`_inst`, `_inst_merge`, `_inst_merge_occ`, `_inst_merge_thin`, `_inst_merge_occ_thin`) |
| `deffer_detail_s_flat.vs`, `deffer_detail_w_flat.vs` and their `_inst*` variants | The same for the flat detail shaders |
| `dt_inst.h` | Shared bindings for rows, merged vertices, the occlusion index and thinning |
| `dt_res_copy.cs`, `dt_res_copy_ex.cs` | Keep rows on the GPU and upload only the ones that changed |
| `dt_occ_pack.cs`, `dt_occ_expand.cs`, `dt_occ_box.vs`, `dt_occ_box.ps` | The occlusion cull |
| `deffer_tree_branch_flat.vs`, `deffer_tree_branch_bump-hq.vs` | SSS 23 plus the bender early-out, same output |
| `details_blend.s` | SSS 23, kept so this mod still wins over Enhanced Shaders |

[PROVENANCE.md](PROVENANCE.md) lists every file with its upstream.

## Console

These switches default to 1 and apply immediately. Grass thinning (below) is separate and off by default.

| Command | Turns off when 0 |
| --- | --- |
| `r__detail_inst` | The whole pipeline (grass goes back to the old path) |
| `r__detail_inst_res` | Keeping rows on the GPU |
| `r__detail_merge` | Merged draws |
| `r__detail_occ`, `r__detail_occ_first` | The occlusion cull, and drawing near grass first |
| `r__detail_rows` | Cached rows |
| `r__detail_shadow_cull` | Culling grass shadows per light and sun cascade |
| `r__svp_grass_cull` | Culling the PiP scope's grass to the scope view |

`r__detail_thin 1` thins out distant grass. Tune it with `r__detail_thin_start`, `r__detail_thin_keep`
and `r__detail_thin_band`. The PiP scope never thins or occlusion-culls its grass, because both follow
the main camera.

## Build

`python tools/package.py` writes `dist/Bodycam Grass Optimisation <version>.zip` with meta.ini, README.md,
PROVENANCE.md and `gamedata/` at the root. `--stage DIR` also writes the mod folder into a new or empty DIR.

Pushes to `main` build a `release-package` artifact in GitHub Actions without publishing. To release,
bump the version in `meta.ini`, push, then push the matching tag (`v1.2.3`). The workflow checks the
archive against the source, then publishes it with `SHA256SUMS.txt`. Existing releases are never
overwritten.

## Credits

- Grass pipeline (fps-clean) and the PiP Grass Optimization Patch's bender early-out: TheLostInPlace (m22).
- Screen Space Shaders: Ascii1457.
- SSS grass variants and the PiP scope pass: asuparabekon.
