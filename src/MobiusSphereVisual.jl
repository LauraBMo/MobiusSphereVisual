module MobiusSphereVisual

using Printf
using LinearAlgebra
using FileIO

export render_mobius_animation

const ASSETS_DIR = joinpath(@__DIR__, "..", "assets")

include("Utils.jl")
include("FFmpegCall.jl")
include("Files.jl")

## v, theta, t coming from `MobiusSphere` package in form of v::Vector{T}, x::T, t::Vector{T}
## where T may be CalciumFieldElem, T <: Real,...
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
    v = validate_inputs(v, theta, t)

    resolution = _validate_resolution(resolution)
    sampling_overrides = _normalize_sampling_overrides(sampling)
    pov_settings = pov_settings_with_overrides(quality, sampling_overrides)
    global_settings = global_settings_extra(pov_settings)

    output_path = abspath(output)
    parent_dir = dirname(output_path)
    if parent_dir != "."
        mkpath(parent_dir)
    end

    preserved_dir = Ref{Union{Nothing,String}}(nothing)
    mktempdir() do output_dir
        copy_macros(output_dir)
        ini_file = generate_pov_ini(
            output_dir,
            nframes,
            resolution;
            pov_settings=pov_settings,
        )
        povraycall(
            output_dir,
            v,
            theta,
            t,
            ini_file;
            global_settings_extra=global_settings,
        )

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

# -- Validation helpers -----------------------------------------------------

function _validate_resolution(resolution::Tuple{Int,Int})
    width, height = resolution
    if width <= 0 || height <= 0
        throw(ArgumentError("resolution must contain positive integers, got $resolution"))
    end
    return resolution
end

function _normalize_sampling_overrides(sampling)
    if sampling === nothing
        return NamedTuple()
    elseif sampling isa NamedTuple
        return sampling
    elseif sampling isa Dict
        return (; (Symbol(key) => value for (key, value) in sampling)...)
    else
        throw(ArgumentError(
            "sampling overrides must be provided as a NamedTuple or Dict, got $(typeof(sampling))",
        ))
    end
end

# function ffmpegcall(
#     output_dir,
#     output_path::String="mobius.mp4",
#     fps::Int=30,
#     resolution::Tuple{Int,Int}=(1280, 720),
#     quality::Symbol=:high,
# )
#     # 🔍 Auto-detect frame numbering format
#     frame_pattern = detect_frame_pattern(output_dir)

#     # Convert to video
#     @info "Creating video with ffmpeg..."
#     if endswith(output_path, ".mp4")
#         settings = quality_settings(quality).ffmpeg
#         cmd = `ffmpeg -y -framerate $fps -i $frame_pattern -c:v libx264 -preset $(settings.preset) -crf $(settings.crf) -pix_fmt yuv420p $output_path`
#     elseif endswith(output_path, ".gif")
#         cmd = `ffmpeg -y -framerate $fps -i $frame_pattern -vf "fps=$fps,scale=$(resolution[1]):$(resolution[2]):flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" $output_path`
#     else
#         error("Unsupported output format. Use .mp4 or .gif")
#     end
#     run(Cmd(cmd, dir=output_dir))
# end

function povraycall(
    output_dir,
    v,
    theta,
    t,
    ini_file;
    global_settings_extra::AbstractString="",
)
    @info "Working in temporary directory: $output_dir"
    # Generate files
    generate_pov_scene(
        v,
        theta,
        t,
        output_dir;
        global_settings_extra=global_settings_extra,
    )

    # Run POV-Ray
    @info "Rendering frames with POV-Ray..."
    run(Cmd(`povray $ini_file`, dir=output_dir))
end

end # module
