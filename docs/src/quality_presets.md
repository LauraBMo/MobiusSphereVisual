# Quality presets

`render_mobius_animation` accepts a `quality::Symbol` keyword that configures both POV-Ray sampling and the ffmpeg encoder preset. Pick the preset that matches your hardware and the fidelity you need for the shot. See also the [Sampling overrides](@ref sampling-overrides) section for fine-grained control, or jump directly to the [`render_mobius_animation`](@ref) API reference.

| Preset   | Relative render time | Visual fidelity                            | Recommended hardware                    | POV-Ray sampling                                             | ffmpeg preset                 |
|:-------- |:-------------------- |:------------------------------------------ |:--------------------------------------- |:------------------------------------------------------------ |:----------------------------- |
| `:draft` | ~0.3× `:high`        | Coarse edges, minimal antialiasing         | 2-core laptop CPU                       | Antialias off, depth 1, sampling method 1                    | `-preset veryfast`, `-crf 30` |
| `:medium`| ~0.6× `:high`        | Smooth edges suitable for previews         | 4-core desktop or better                | Antialias on, depth 2, sampling method 2                     | `-preset faster`, `-crf 23`   |
| `:high`  | Baseline             | Highest fidelity with low aliasing         | 6–8 core desktop CPU                    | Antialias on, depth 3, sampling method 2                     | `-preset medium`, `-crf 20`   |
| `:ultra` | ~2.0× `:high`        | Filmic lighting with radiosity and photons | 8-core/16-thread workstation, 16 GB RAM | Antialias on, depth 5, sampling method 2, radiosity & photons | `-preset slow`, `-crf 18`     |
| `:film`  | ~3.2× `:high`        | Maximum fidelity for large-format delivery | 12+ core workstation, 32 GB RAM         | Antialias on, depth 6, sampling method 2, radiosity & photons | `-preset slower`, `-crf 16`   |

- **Draft** renders trade sharpness for iteration speed; use them when adjusting camera or transformation parameters.
- **Medium** balances turnaround time and visual smoothness for team reviews or sharing quick demos.
- **High** reproduces the original defaults for production-ready output.
- **Ultra** enables deeper antialiasing with radiosity and photon passes when you have workstation-class CPUs and want cinematic lighting.
- **Film** pushes sampling to the limit for large-format renders; budget ample time or render on a compute cluster.

## Choosing a preset

POV-Ray sampling depth has the largest influence on render time. Increasing the preset from `:draft` to `:high` roughly triples the number of rays traced per pixel, so expect render times to scale accordingly while reducing jagged edges. Similarly, the ffmpeg presets balance compression quality and encoding speed—the faster settings write files quickly at the cost of larger sizes and slightly lower detail.

For an end-to-end workflow that wires these presets into the rendering pipeline, see [`render_mobius_animation`](@ref) and the examples in the [Quick start](@ref).
