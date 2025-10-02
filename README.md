# MobiusSphereVisual [![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://LauraBMo.github.io/MobiusSphereVisual.jl/stable/) [![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://LauraBMo.github.io/MobiusSphereVisual.jl/dev/) [![Build Status](https://github.com/LauraBMo/MobiusSphereVisual.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/LauraBMo/MobiusSphereVisual.jl/actions/workflows/CI.yml?query=branch%3Amain) [![Coverage](https://codecov.io/gh/LauraBMo/MobiusSphereVisual.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/LauraBMo/MobiusSphereVisual.jl)

Render Möbius transformations in the style of *Möbius Transformations Revealed* directly from Julia.

## Quick start

```julia
using MobiusSphereVisual

v = [0.0, 0.0, 1.0]
theta = π / 2
t = [0.0, 0.0, 0.0]

render_mobius_animation(v, theta, t; nframes=120, quality=:medium)
```

This command writes a temporary sequence of PNG frames with POV-Ray and stitches
them together into `mobius.mp4` with ffmpeg. The finished video is moved to your
current working directory while the intermediate frames are cleaned up. Pass
`keep_temp=true` to retain a copy of the temporary render directory for
debugging; if rendering fails, the directory is automatically copied to a
`mobius_failure_…` folder so you can inspect the generated assets.

## Quality presets

`render_mobius_animation` accepts a `quality::Symbol` keyword that configures
both the POV-Ray sampling parameters and the ffmpeg encoder preset.

| Preset | Relative render time | Visual fidelity | POV-Ray sampling | ffmpeg preset |
| ------ | ------------------- | --------------- | ---------------- | ------------- |
| `:draft` | ~0.3× `:high` | Coarse edges, minimal antialiasing | Antialias off, depth 1, sampling method 1 | `-preset veryfast`, `-crf 30` |
| `:medium` | ~0.6× `:high` | Smooth edges suitable for previews | Antialias on, depth 2, sampling method 2 | `-preset faster`, `-crf 23` |
| `:high` | Baseline | Highest fidelity with low aliasing | Antialias on, depth 3, sampling method 2 | `-preset medium`, `-crf 20` |

- **Draft** renders trade sharpness for iteration speed; use them when adjusting
  camera or transformation parameters.
- **Medium** balances turnaround time and visual smoothness for team reviews or
  sharing quick demos.
- **High** reproduces the original defaults for production-ready output.

### Choosing a preset

POV-Ray sampling depth has the largest influence on render time. Increasing the
preset from `:draft` to `:high` roughly triples the number of rays traced per
pixel, so expect render times to scale accordingly while reducing jagged edges.
Similarly, the ffmpeg presets balance compression quality and encoding speed—the
faster settings write files quickly at the cost of larger sizes and slightly
lower detail.

### Example renders

```julia
render_mobius_animation(v, theta, t; quality=:draft)   # Fast iteration
render_mobius_animation(v, theta, t; quality=:medium)  # Balanced preview
render_mobius_animation(v, theta, t; quality=:high)    # Final delivery
render_mobius_animation(v, theta, t; keep_temp=true)   # Keep intermediate frames
```

See the [documentation](https://LauraBMo.github.io/MobiusSphereVisual.jl/dev/)
for API details and extended examples.
