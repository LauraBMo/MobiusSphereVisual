module MobiusSphereVisual

using Printf
using LinearAlgebra
using FileIO

export render_mobius_animation

const ASSETS_DIR = joinpath(@__DIR__, "..", "assets")

include("Utils.jl")
include("SetQuality.jl")
include("FFmpegCall.jl")
include("Files.jl")

# The vectors `v` and `t` originate from the MobiusSphere package as
# `Vector{T}` values alongside a scalar rotation `theta::T`, where `T`
# represents a real-like numeric type (for example `CalciumFieldElem`).
# This wrapper narrows the signature to `Float64` inputs for a predictable
# rendering pipeline while keeping the call surface familiar.
"""
    render_mobius_animation(v, theta, t; output="mobius.mp4", fps=30,
                            resolution=(1280,720), nframes=150, quality=:high)

Render a Möbius sphere animation in the style of "Möbius Transformations Revealed".
`theta` is specified in radians and converted to degrees for the POV-Ray scene.
The `quality` keyword toggles coordinated POV-Ray and ffmpeg presets ranging
from `:draft` (fastest) through `:film` (highest fidelity), with `:high`
remaining the default. Set `keep_temp=true` to retain the rendered frame
directory alongside the exported video for debugging or post-processing. When
you need to fine-tune ray-tracing parameters beyond a preset, provide
`sampling=(antialias="On", antialias_depth=4, sampling_method=2,
antialias_threshold=0.05, radiosity=true, photons=true,
flags="+A0.05\n+AM2 +R3")` or similar overrides. Setting `radiosity=true`
or `photons=true` injects tuned global illumination blocks into the POV-Ray
scene without touching the template on disk.
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
)
    # Ensure the axis, angle, and translation parameters are well formed.
    v = validate_inputs(v, theta, t)
    resolution = _validate_resolution(resolution)

    output_path = abspath(output)
    parent_dir = dirname(output_path)
    if parent_dir != "."
        # Create the target directory when rendering into a nested path.
        mkpath(parent_dir)
    end

    preserved_dir = Ref{Union{Nothing,String}}(nothing)
    mktempdir() do output_dir
        # Populate the temporary folder with shared POV-Ray macros.
        copy_macros(output_dir)
        ini_file, povscene = generate_pov(
            v, theta, t,
            output_dir,
            nframes,
            resolution;
            quality = quality,
            sampling = sampling,
        )

        # Render frames with POV-Ray before combining them into a video.
        povraycall(output_dir, ini_file)

        # Assemble the video or GIF with ffmpeg using the rendered frames.
        ffmpegcall(output_dir, output_path, fps, resolution, quality)

        if keep_temp
            dest_dir = derived_temp_destination(output_path)
            if ispath(dest_dir)
                rm(dest_dir; recursive=true)
            end
            cp(output_dir, dest_dir; force=true)
            preserved_dir[] = dest_dir
            @info "Preserved temporary frames at: $dest_dir"
        end
    end

    if keep_temp && !isnothing(preserved_dir[])
        @info "Temporary assets copied to: $(preserved_dir[])"
    end

    @info "Animation saved to: $output_path"
end

end # module
