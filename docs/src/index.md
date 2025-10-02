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

## Quality presets

`render_mobius_animation` exposes a `quality` keyword argument so you can match
the rendering pipeline to your iteration speed:

- `:draft` disables most antialiasing for extremely fast test renders and uses a
  veryfast ffmpeg preset.
- `:medium` offers balanced sampling (antialias depth 2) and a faster encoder,
  making it a good choice for sharing previews.
- `:high` keeps the original high-quality settings (antialias depth 3, sampling
  method 2) together with a slower `-preset medium`/`-crf 20` ffmpeg encode for
  production output.

Render time scales roughly with the antialias depth—expect `:draft` to finish in
about a third of the time of `:high`, while `:medium` lands in between with
noticeably smoother edges.
