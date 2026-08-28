module MobiusSphereVisual

using Printf
using LinearAlgebra
using FileIO

export render_mobius_animation

const ASSETS_DIR = joinpath(@__DIR__, "..", "assets")

include("Emit.jl")
include("Render.jl")

"""
    render_mobius_animation(v, theta, t; output="mobius.mp4", fps=30,
                            resolution=(1280,720), nframes=150, quality=:high)

Render a Möbius sphere animation in the style of “Möbius Transformations Revealed”.

`v` is the 3D rotation axis (unit vector, z-up convention matching MobiusSphere).
`theta` is the rotation angle in radians (converted to degrees for POV-Ray).
`t` is the 3D translation vector.

`quality` is one of `:draft` (fastest, ~30 s on a laptop), `:medium`, `:high`,
`:ultra`, or `:film` (highest fidelity). Set `keep_temp=true` to retain the
rendered frame directory alongside the exported video for debugging.

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
        )

        povraycall(output_dir, ini_file)
        final_output[] = ffmpegcall(output_dir, output_path, fps, validated_resolution, quality)

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

end # module
