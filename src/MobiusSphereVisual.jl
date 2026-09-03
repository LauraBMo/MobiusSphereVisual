module MobiusSphereVisual

using Printf
using LinearAlgebra
using FileIO

export render_mobius_animation, render_scene, set_scene!, reset_scene!, scene_settings, concat_clips

const ASSETS_DIR = joinpath(@__DIR__, "..", "assets")

include("Emit.jl")
include("Render.jl")
include("Scene.jl")

# ── Core render orchestration ────────────────────────────────────────────────
# Shared by `render_scene` and the `render_mobius_animation` preset. Everything
# scene-specific arrives already lowered to POV strings (`scene_overrides`,
# `extra_sdl`); this function only drives the temp dir → POV-Ray → FFmpeg pipeline.
function _render_animation(
    v::Vector{Float64},
    theta::Float64,
    t::Vector{Float64};
    scene_overrides::AbstractString="",
    extra_sdl::AbstractString="",
    output::String="mobius.mp4",
    fps::Int=30,
    resolution::Tuple{Int,Int}=(1280, 720),
    nframes::Int=150,
    quality::Symbol=:high,
    sampling::Union{Nothing,NamedTuple,Dict}=nothing,
    keep_temp::Bool=false,
    hold::Union{Bool,Real}=true,
    markers=nothing,
)
    validated_v = validate_inputs(v, theta, t)
    validated_resolution = _validate_resolution(resolution)

    output_path = abspath(output)
    mkpath(dirname(output_path))

    preserved_dir = Ref{Union{Nothing,String}}(nothing)
    final_output = Ref(output_path)

    mktempdir() do output_dir
        @debug "Using temporary directory: $output_dir"

        copy_assets(output_dir)

        ini_file, _scene = generate_pov(
            validated_v, theta, t,
            output_dir,
            nframes,
            validated_resolution;
            quality=quality,
            sampling=sampling,
            scene_overrides=scene_overrides,
            extra_sdl=extra_sdl,
            markers=markers,
        )

        povraycall(output_dir, ini_file)
        final_output[] =
            ffmpegcall(output_dir, output_path, fps, validated_resolution, quality; hold=hold)

        if keep_temp
            dest_dir = derived_temp_destination(output_path)
            ispath(dest_dir) && rm(dest_dir; recursive=true)
            cp(output_dir, dest_dir; force=true)
            preserved_dir[] = dest_dir
            @info "Preserved temporary frames at: $dest_dir"
        end
    end

    keep_temp && !isnothing(preserved_dir[]) &&
        @info "Temporary assets copied to: $(preserved_dir[])"

    @info "Animation saved to: $(final_output[])"
    return final_output[]
end

"""
    render_mobius_animation(v, theta, t; output="mobius.mp4", fps=30,
                            resolution=(1280,720), nframes=150, quality=:high)

Render a Möbius sphere animation in the style of “Möbius Transformations Revealed”.

This is the **Arnold preset** — a thin wrapper over the generic [`render_scene`](@ref)
with the default look. For a customised scene (palette, camera, geometry, toggled or
custom objects) call `render_scene`, or set globals with [`set_scene!`](@ref) first;
both are picked up here too.

`v` is the 3D rotation axis (unit vector, z-up convention matching MobiusSphere).
`theta` is the rotation angle in radians (converted to degrees for POV-Ray).
`t` is the 3D translation vector.

`quality` is one of `:draft` (fastest, ~30 s on a laptop), `:medium`, `:high`,
`:ultra`, or `:film` (highest fidelity). Set `keep_temp=true` to retain the
rendered frame directory alongside the exported video for debugging.

`hold` pads a held (cloned) first and last frame onto the video: `true` → 1.5 s at
each end (default), `false` (or `0`) → none, a number → that many seconds. Applies
to every output format (mp4, webm, gif).

Optional `sampling` NamedTuple or Dict overrides individual POV-Ray sampling fields.
"""
function render_mobius_animation(
    v::Vector{Float64},
    theta::Float64,
    t::Vector{Float64};
    output::String="mobius.mp4",
    fps::Int=30,
    resolution::Tuple{Int,Int}=(1280, 720),
    nframes::Int=150,
    quality::Symbol=:high,
    sampling::Union{Nothing,NamedTuple,Dict}=nothing,
    keep_temp::Bool=false,
    hold::Union{Bool,Real}=true,
    markers=nothing,
)
    return render_scene(
        v, theta, t;
        output=output, fps=fps, resolution=resolution, nframes=nframes,
        quality=quality, sampling=sampling, keep_temp=keep_temp, hold=hold, markers=markers,
    )
end

end # module
