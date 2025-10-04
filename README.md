# MobiusSphereVisual [![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://LauraBMo.github.io/MobiusSphereVisual/stable/) [![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://LauraBMo.github.io/MobiusSphereVisual/dev/) [![Build Status](https://github.com/LauraBMo/MobiusSphereVisual.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/LauraBMo/MobiusSphereVisual.jl/actions/workflows/CI.yml?query=branch%3Amain) [![Coverage](https://codecov.io/gh/LauraBMo/MobiusSphereVisual.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/LauraBMo/MobiusSphereVisual.jl)

Render Möbius transformations in the style of *Möbius Transformations Revealed* directly from Julia.

## Quick start

```julia
using MobiusSphereVisual

v = [0.0, 0.0, 1.0]
theta = π / 2
t = [0.0, 0.0, 0.0]

render_mobius_animation(v, theta, t; output="examples/demo.mp4", nframes=120, quality=:medium)
```

The helper takes care of generating the POV-Ray scene, rendering the frames and stitching the resulting images into the requested video or GIF.

## Using coefficients from MobiusSphere.jl

`MobiusSphere.jl` exposes its motions as coefficient objects that already contain an axis, rotation angle and translation. You can feed those coefficients directly into the renderer. The snippet below uses one of the helper constructors shipped with `MobiusSphere.jl`; swap it out for whichever transformation you are working with:

```julia
using MobiusSphere
using MobiusSphereVisual

mobius = MobiusSphere.example_loxodromic()  # replace with your own construction
coeffs = MobiusSphere.motion_parameters(mobius)  # returns (v, theta, t)

render_mobius_animation(coeffs...; output="examples/loxodromic.mp4", nframes=120)
```

## Quality presets

`render_mobius_animation` accepts a `quality::Symbol` keyword that configures
both the POV-Ray sampling parameters and the ffmpeg encoder preset.

| Preset | Relative render time | Visual fidelity | Recommended hardware | POV-Ray sampling | ffmpeg preset |
| ------ | ------------------- | --------------- | -------------------- | ---------------- | ------------- |
| `:draft` | ~0.3× `:high` | Coarse edges, minimal antialiasing | 2-core laptop CPU | Antialias off, depth 1, sampling method 1 | `-preset veryfast`, `-crf 30` |
| `:medium` | ~0.6× `:high` | Smooth edges suitable for previews | 4-core desktop or better | Antialias on, depth 2, sampling method 2 | `-preset faster`, `-crf 23` |
| `:high` | Baseline | Highest fidelity with low aliasing | 6–8 core desktop CPU | Antialias on, depth 3, sampling method 2 | `-preset medium`, `-crf 20` |
| `:ultra` | ~2.0× `:high` | Filmic lighting with radiosity and photons | 8-core/16-thread workstation, 16 GB RAM | Antialias on, depth 5, sampling method 2, radiosity & photons enabled | `-preset slow`, `-crf 18` |
| `:film` | ~3.2× `:high` | Maximum fidelity for large-format delivery | 12+ core workstation, 32 GB RAM | Antialias on, depth 6, sampling method 2, radiosity & photons enabled | `-preset slower`, `-crf 16` |

- **Draft** renders trade sharpness for iteration speed; use them when adjusting
  camera or transformation parameters.
- **Medium** balances turnaround time and visual smoothness for team reviews or
  sharing quick demos.
- **High** reproduces the original defaults for production-ready output.
- **Ultra** enables deeper antialiasing with radiosity and photon passes when
  you have workstation-class CPUs and want cinematic lighting.
- **Film** pushes sampling to the limit for large-format renders; budget ample
  time or render on a compute cluster.

### Choosing a preset

POV-Ray sampling depth has the largest influence on render time. Increasing the
preset from `:draft` to `:high` roughly triples the number of rays traced per
pixel, so expect render times to scale accordingly while reducing jagged edges.
Similarly, the ffmpeg presets balance compression quality and encoding speed—the
faster settings write files quickly at the cost of larger sizes and slightly
lower detail.

When you need the raw pieces, unpack the tuple manually and pass the components to `render_mobius_animation`:

```julia
using MobiusSphereVisual

params = ([0.0, 0.0, 1.0], pi / 2, [0.2, 0.0, 0.0])

v, theta, t = params
render_mobius_animation(v, theta, t; output="examples/from_tuple.mp4", nframes=120)
```

### Example renders

```julia
render_mobius_animation(v, theta, t; quality=:draft)   # Fast iteration
render_mobius_animation(v, theta, t; quality=:medium)  # Balanced preview
render_mobius_animation(v, theta, t; quality=:high)    # Final delivery
```

### Sampling overrides

Each quality preset controls a bundle of POV-Ray parameters. If you need to override them, pass a `sampling` NamedTuple or `Dict` when calling `render_mobius_animation`:

```julia
render_mobius_animation(v, theta, t; quality=:ultra,
    sampling=(
        antialias = "On",
        antialias_depth = 7,
        sampling_method = 2,
        antialias_threshold = 0.015,
        radiosity = true,
        photons = true,
        flags = "+A0.015\n+AM2 +R9\n+Q13\n+UA",
    ))
```

The renderer understands the following fields:

- `antialias` — either `"On"` or `"Off"`, matching POV-Ray’s `Antialias` switch.
- `antialias_depth` — integer depth for adaptive supersampling.
- `sampling_method` — sampling algorithm (`1` for non-recursive, `2` for recursive sampling).
- `antialias_threshold` — floating point threshold that controls pixel refinement.
- `radiosity` — boolean toggle that injects a high-quality radiosity block into the scene’s `global_settings`.
- `photons` — boolean toggle that adds a photon-mapping block with dense gathers for caustics and secondary illumination.
- `flags` — free-form string appended to the `.ini` file for extra POV-Ray options (e.g. `+Q11`, `+UA`).

Any field you omit inherits its value from the chosen quality preset, so you can override just the settings you need.

The `:ultra` and `:film` presets set both `radiosity` and `photons` to `true`, enabling soft indirect light and photon caustics without
requiring a user configuration file.

See the [documentation](https://LauraBMo.github.io/MobiusSphereVisual/dev/)
for API details and extended examples.
