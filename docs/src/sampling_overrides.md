# Sampling overrides

While the quality presets cover common workflows, you can override individual POV-Ray parameters directly when calling [`render_mobius_animation`](@ref). Pass a `sampling` NamedTuple or `Dict` with only the fields you need to adjust—any omitted setting inherits its value from the active preset.

```julia
render_mobius_animation(v, theta, t; quality = :ultra,
    sampling = (
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

The `:ultra` and `:film` [quality presets](@ref quality-presets) enable both `radiosity` and `photons` to deliver soft indirect light and caustics without extra configuration. Combine overrides with those presets for even finer control.
