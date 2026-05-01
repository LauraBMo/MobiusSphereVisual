# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## Package Overview

**MobiusSphereVisual** is a Julia package (v1.0.0-DEV) that renders animations of
Möbius sphere transformations using POV-Ray and FFmpeg. It accepts the axis/angle/
translation output of MobiusSphere and produces an `.mp4` (or `.gif`).

## Commands

Julia is at `~/src/juliaup/bin/julia`. Run from package root with `--project=.`.

```bash
# Run test suite
~/src/juliaup/bin/julia --project=. -e "using Pkg; Pkg.test()"

# Quick smoke-test render (requires povray + ffmpeg in PATH)
~/src/juliaup/bin/julia --project=. -e "
  using MobiusSphereVisual
  render_mobius_animation([0.,0.,1.], pi/4, [0.,0.,0.];
                          output=\"test.mp4\", nframes=10, quality=:draft)
"
```

## Architecture — 3 Julia files + 1 POV template

| File | Responsibility |
|------|----------------|
| `src/MobiusSphereVisual.jl` | Public API: `render_mobius_animation` |
| `src/Emit.jl` | String substitution into `assets/mobius_template.pov`; z-up → y-up axis swap |
| `src/Render.jl` | `povraycall`, `ffmpegcall`, quality presets, input validation |
| `assets/mobius_template.pov` | Single `clock`-driven POV-Ray template |

### Coordinate system

MobiusSphere uses **z as the polar axis** (NorthAxis = 3 in
`StereographicProjections.jl`). POV-Ray uses **y-up**. The swap is performed
in `Emit.jl / generate_pov_scene`:

```
Julia vector [vx, vy, vz]  →  POV-Ray <vx, vz, vy>
```

All other coordinate handling (camera, lights, floor) is y-up inside the POV files.

### Quality presets

Defined in `Render.jl` as `QUALITY_PRESETS`. Radiosity is on at `:high` and above;
photons only at `:film`.

| Symbol  | Radiosity | Photons | Typical use |
|---------|-----------|---------|-------------|
| `:draft`  | off | off | Quick iteration |
| `:medium` | off | off | Preview |
| `:high`   | on  | off | Default output |
| `:ultra`  | on  | off | Near-final |
| `:film`   | on  | on  | Publication |

### POV asset files

```
assets/
  mobius_template.pov   – single template; #includes the three files below
  macros.inc            – sphere macros (SphereGlassShell, SphereArgumentCap, …)
  mobius_textures.inc   – GrayCheckerFloor texture declaration
  mobius_scene.inc      – MobiusCamera, BackgroundColor, FloorPlane declarations
  render.ini            – POV-Ray ini template (filled by generate_pov_ini)
```

All three `.inc` files are copied to the temp directory by `copy_assets` before
POV-Ray is invoked. The template must not reference any other local files.

### Template placeholders

```
@V_X@ @V_Y@ @V_Z@   – rotation axis (y-up after swap)
@THETA@             – rotation angle in degrees
@T_X@ @T_Y@ @T_Z@  – translation vector (y-up after swap)
@GLOBAL_SETTINGS_EXTRA@  – injected radiosity/photon blocks
```

Animation is split into two halves via `clock`:
- `clock ∈ [0, 0.5]`: pure rotation ramps from 0 to THETA
- `clock ∈ [0.5, 1]`: rotation holds at THETA, translation ramps in

## Dependencies

- **POV-Ray** (≥ 3.7) — ray tracer; must be in `PATH` as `povray`
- **FFmpeg** — video/GIF assembly; must be in `PATH` as `ffmpeg`
- **FileIO**, **Printf**, **LinearAlgebra** — Julia stdlib / registered packages
