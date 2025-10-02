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

`MobiusSphere.jl` returns coefficient objects that carry the axis, rotation angle and translation used by the Möbius motion. The renderer accepts those objects directly, or you can turn them into raw tuples via [`coerce_motion_parameters`](@ref):

```julia
using MobiusSphereVisual

coeffs = (axis = [0.0, 0.0, 1.0], angle = pi / 2, translation = [0.2, 0.0, 0.0])

render_mobius_animation(coeffs; output="examples/from_coeffs.mp4", nframes=120)
```

```@autodocs
Modules = [MobiusSphereVisual]
```
