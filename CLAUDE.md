# CLAUDE.md

Guidance for Claude Code (claude.ai/code) when working in this repository.

## Goal

Reproduce the visual aesthetic of Douglas Arnold & Jonathan Rogness's
**"Möbius Transformations Revealed"** in Julia + POV-Ray + FFmpeg.

The reference material is at the repo root:
- `mobius.pdf` — Siliciano's paper *Constructing Möbius Transformations with
  Spheres* (Rose-Hulman, 2012), which formalises the geometric construction
- `arnold.png`, `arnold1.png`, `arnold2.png` — stills from the film

The package, `MobiusSphereVisual.jl`, renders animations of Möbius sphere
transformations. The entry point is `render_mobius_animation(v, theta, t; ...)`,
which generates a POV-Ray scene from `assets/mobius_template.pov`, renders
frames with `povray`, and stitches them with `ffmpeg`.

## The physical setup we are reproducing

Arnold's image is **not painted**. It is the literal stereographic projection
mechanism:

- A point light sits at the **north pole** of a unit sphere
- The sphere's **lower hemisphere** ("cap") is a coloured filter — each
  longitudinal wedge is a different rainbow hue, with a polar grid of opaque
  black lines (radial rings at stereographic radii, angular spokes every
  `2π/N` radians)
- Photons emitted by the north-pole light refract through the cap, picking up
  its wedge colour, and project a **caustic** onto a gray graph-paper floor
  below
- The black grid lines on the sphere are opaque → they cast black shadow lines
  in the caustic
- The caustic on the floor is geometrically equivalent to stereographic
  projection of the sphere's pattern from the north pole onto the y = -1 plane

When the Möbius transformation rotates/translates the sphere, the caustic
deforms accordingly — that is the animation.

## What must remain true

**Updated 2026-08-28 — the render now uses the texture-projection approach from
the `mobius/` folder, with NO photons.** The coloured floor square is a POV-Ray
*texture*: the stereographic pattern (`SU`/`SV` in `assets/math.inc`, `PatchVal`/
`WireMask` in `assets/setup.inc`) painted on the projection shell's lower cap —
not a photon caustic. So:

- **No photons, no radiosity.** `assets/mobius_template.pov` has a plain
  `global_settings { assumed_gamma 1.0 }`. Every quality preset renders fast in
  seconds/frame; the old "photons only at `:film`" rule no longer applies.
- Painting the coloured projection onto the scene is **correct now** — the
  earlier rule ("the floor colour must be the photon caustic; never paint it")
  is retired.
- The pole light and glow-dot follow the **transformed north pole** each frame
  (`PoleNow`), driven by `clock`: phase 1 (clock ≤ 0.5) rotates about the sphere
  centre by `θ`, phase 2 translates by `t`.
- The rainbow patch uses the `filter` channel so the glass reads through it; the
  black grid (`WireMask`) stays opaque. Palette/material knobs live in
  `assets/setup.inc`.
- `d5_newlook.webm` (in `/tmp`) is the reference look; `/tmp/mobius_anim/` holds
  the standalone prototype this pipeline was ported from.

## Iteration workflow

Trial-and-error on visuals is the normal mode of work here.

- Iterate at any quality — all are fast now (no photons). `:medium` is a good
  default; higher presets only add antialiasing.
- Render 2–4 frames at 640×360 for quick iteration; reserve full resolution
  and frame count for the final pass.
- Always pass `keep_temp = true` during iteration so frames remain at
  `/tmp/<output_stem>_frames/frame_*.png` for inspection.
- Read frames directly with the Read tool to see them visually before reporting.
- When in doubt about a visual goal, ask the user to drop a reference image
  in the repo root and compare side-by-side.

## Examples and demos

- **Everything lives in `Laura.org`.** Do not create `examples/`, `demo/`, or
  similar folders, and do not add example `.jl` files at the repo root.
- All example renders write to `/tmp/...`, never into the repo.

## POV-Ray gotchas worth remembering

- **Layered textures and photons:** photon mapping samples a surface's
  pigment to decide whether light is filtered or absorbed. Stacked
  `texture { ... } texture { ... }` layers are not reliable for this — only
  the base pigment is consulted. To get black grid shadows in the caustic,
  combine wedge colours and grid into a **single** pigment via `pigment_map`.
- **`#declare X = pigment { function { ... } ... }` does not parse** in
  POV-Ray. The parser interprets `function { ... }` inside a top-level
  `#declare` as a function definition with parameters and complains. Either
  inline the function inside a macro/scope, or use a built-in pattern
  (`radial`, `gradient`, etc.) in `#declare`.
- **Built-in `radial` pattern** is more reliable for angular wedges/spokes
  than hand-rolled `select(min(...))` formulas; the latter can render
  correctly on flat surfaces but go invisible on curved sphere sections.
- **Coordinate swap:** MobiusSphere uses z-up; POV-Ray uses y-up. The Julia
  vector `[vx, vy, vz]` maps to the POV-Ray vector `<vx, vz, vy>` — swapping
  the second and third components. The swap happens in
  `src/Emit.jl :: generate_pov_scene`.
- **Stereographic radius** from a unit sphere point `(x, y, z)` to the floor
  at `y = -1` via the north pole `(0, 1, 0)` is
  `r = 2 * sqrt(x² + z²) / (1 - y)`. For the floor and sphere grid to align,
  both must derive their radial-ring positions from this expression (sphere)
  / the floor's plain radius `r = sqrt(x² + z²)` (floor) using the same
  spacing.

## Commands

Julia is at `~/src/juliaup/bin/julia`. Run from package root with `--project=.`.

```bash
# Test suite
~/src/juliaup/bin/julia --project=. test/runtests.jl

# Quick visual iteration (no caustic — use for sphere/colour tweaks only)
~/src/juliaup/bin/julia --project=. -e "
  using MobiusSphereVisual
  render_mobius_animation([0.,0.,1.], pi/4, [0.,0.,0.];
                          output=\"/tmp/test.mp4\", nframes=4,
                          resolution=(640,360), quality=:medium,
                          keep_temp=true)
"

# Full Arnold-style render (with photon caustic — slower)
# Use :film and bump nframes/resolution when you have a confirmed look.
```

## External dependencies

- `povray` (≥ 3.7) and `ffmpeg` must be in `PATH`. Neither is managed by Julia.

## Code architecture (read-only summary)

The source lives in two files in `src/`:

| File | Responsibility |
|------|---------------|
| `MobiusSphereVisual.jl` | Module entry; exports `render_mobius_animation` |
| `Emit.jl` | POV scene generation: template substitution, asset copying, quality presets |
| `Render.jl` | Input validation, `povray` invocation, FFmpeg encoding, photon/radiosity blocks |

Scene assets live in `assets/` (the `mobius/` texture approach, no photons):
- `mobius_template.pov` — main template with `@V_X@`, `@THETA@`, … placeholders;
  clock-driven Möbius motion
- `math.inc` — `SU`/`SV` inverse-stereographic projection + grid `Line` helper
- `setup.inc` — palette, patch/wire masks, material tuning
- `textures.inc` — floor, glass, rainbow patch, wire, glow textures
- `objects.inc` — `FloorPlane`, `GlassBall`, `ProjectionShell`, `AxisPin`, `GlowDot` macros

All `.inc` files are copied to the temp render directory by
`copy_assets(output_dir)`.

## Quality presets

`:draft`, `:medium`, `:high`, `:ultra`, `:film` — these now differ only in
antialiasing; **none use photons** (the scene has none), so all render fast.
Sampling fields are overridable via the `sampling` keyword (`NamedTuple` or `Dict`).
