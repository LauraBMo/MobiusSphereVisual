```@meta
CurrentModule = MobiusSphereVisual
```

# MobiusSphereVisual

Render Möbius transformations on the Riemann sphere using POV-Ray.

## Quick start

```julia
using MobiusSphereVisual

v = [0.0, 0.0, 1.0]
theta = pi / 2
t = [0.2, 0.0, 0.0]

render_mobius_animation(v, theta, t; output="examples/demo.mp4", nframes=120)
```

## Using coefficients from MobiusSphere.jl

`MobiusSphere.jl` returns coefficient objects that carry the axis, rotation angle and translation used by the Möbius motion. Destructure the triple into `(v, theta, t)` before calling the renderer so the arguments match the current method signature:

```julia
using MobiusSphereVisual

coeffs = ([0.0, 0.0, 1.0], pi / 2, [0.2, 0.0, 0.0])

v, theta, t = coeffs
render_mobius_animation(v, theta, t; output="examples/from_coeffs.mp4", nframes=120)
```

## Rendering guide

```@contents
Pages = [
    "quality_presets.md",
    "sampling_overrides.md",
]
Depth = 2
```

Explore the quality presets and sampling overrides for [`render_mobius_animation`](@ref) to tailor visual fidelity and render time to your project.

```@autodocs
Modules = [MobiusSphereVisual]
```
