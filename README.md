# MobiusSphereVisual [![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://LauraBMo.github.io/MobiusSphereVisual.jl/stable/) [![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://LauraBMo.github.io/MobiusSphereVisual.jl/dev/) [![Build Status](https://github.com/LauraBMo/MobiusSphereVisual.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/LauraBMo/MobiusSphereVisual.jl/actions/workflows/CI.yml?query=branch%3Amain) [![Coverage](https://codecov.io/gh/LauraBMo/MobiusSphereVisual.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/LauraBMo/MobiusSphereVisual.jl)

Render Möbius transformations on the Riemann sphere using POV-Ray in the style of the classic *Möbius Transformations Revealed* video.

## Quick start

```julia
using MobiusSphereVisual

v = [0.0, 0.0, 1.0]
theta = pi / 2
t = [0.2, 0.0, 0.0]

render_mobius_animation(v, theta, t; output="examples/demo.mp4", nframes=120)
```

The helper takes care of generating the POV-Ray scene, rendering the frames and stitching the resulting images into the requested video or GIF.

## Using coefficients from MobiusSphere.jl

`MobiusSphere.jl` exposes its motions as coefficient objects that already contain an axis, rotation angle and translation. You can feed those coefficients directly into the renderer. The snippet below uses one of the helper constructors shipped with `MobiusSphere.jl`; swap it out for whichever transformation you are working with:

```julia
using MobiusSphere
using MobiusSphereVisual

mobius = MobiusSphere.example_loxodromic()  # replace with your own construction
coeffs = MobiusSphere.motion_parameters(mobius)  # returns axis/angle/translation data

render_mobius_animation(coeffs; output="examples/loxodromic.mp4", nframes=120)
```

When you need the raw pieces, the new [`coerce_motion_parameters`](https://LauraBMo.github.io/MobiusSphereVisual.jl/dev/reference/#MobiusSphereVisual.coerce_motion_parameters) utility converts any compatible coefficient object into `(v, theta, t)` tuples:

```julia
using MobiusSphereVisual

coeffs = (axis = [0.0, 0.0, 1.0], angle = pi / 2, translation = [0.2, 0.0, 0.0])

v, theta, t = coerce_motion_parameters(coeffs)
render_mobius_animation(v, theta, t; output="examples/from_tuple.mp4", nframes=120)
```

Both approaches are supported by `Demo.jl` so you can pick whichever workflow is more convenient.
