```@meta
CurrentModule = MobiusSphereVisual
```

# MobiusSphereVisual

Documentation for [MobiusSphereVisual](https://github.com/LauraBMo/MobiusSphereVisual.jl).

```@index
```

```@autodocs
Modules = [MobiusSphereVisual]
```

## Quality presets

`render_mobius_animation` exposes a `quality` keyword argument so you can match
the rendering pipeline to your iteration speed. The function renders into a
temporary directory that is cleaned up automatically; pass `keep_temp=true` to
retain the intermediate POV-Ray frames for debugging. When rendering fails, the
library copies the directory to a `mobius_failure_…` folder so you can inspect
the generated POV-Ray inputs and partial frames:

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
