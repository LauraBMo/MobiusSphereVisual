module MobiusSphereVisual

using Printf
using LinearAlgebra
using FileIO

export render_mobius_animation

const ASSETS_DIR = joinpath(@__DIR__, "..", "assets")

"""
    quality_settings(quality)

Return the rendering settings associated with `quality`.

The preset controls both POV-Ray sampling quality and ffmpeg encoding
parameters so that a single keyword can trade fidelity for faster render
times.
"""
function quality_settings(quality::Symbol)
    if quality == :draft
        return (
            pov = (
                antialias = "Off",
                antialias_depth = 1,
                sampling_method = 1,
                antialias_threshold = 0.3,
                flags = "+A0.5\n+AM1 +R1\n+Q08\n+UA",
            ),
            ffmpeg = (
                crf = 30,
                preset = "veryfast",
            ),
        )
    elseif quality == :medium
        return (
            pov = (
                antialias = "On",
                antialias_depth = 2,
                sampling_method = 2,
                antialias_threshold = 0.1,
                flags = "+A0.2\n+AM2 +R3\n+Q09\n+UA",
            ),
            ffmpeg = (
                crf = 23,
                preset = "faster",
            ),
        )
    elseif quality == :high
        return (
            pov = (
                antialias = "On",
                antialias_depth = 3,
                sampling_method = 2,
                antialias_threshold = 0.05,
                flags = "+A0.1\n+AM2 +R3\n+Q09\n+UA",
            ),
            ffmpeg = (
                crf = 20,
                preset = "medium",
            ),
        )
    else
        valid = join(string.((:draft, :medium, :high)), ", ")
        throw(ArgumentError("Unknown quality preset: $quality. Supported presets: $valid"))
    end
end

"""
    validate_inputs(v, theta, t)

Ensure v is a 3D unit vector; normalize if needed. Ensure t is 3D.
"""
function validate_inputs(v::Vector{Float64}, theta::Float64, t::Vector{Float64})
    if length(v) != 3 || length(t) != 3
        throw(ArgumentError("v and t must be 3D vectors"))
    end
    v_norm = norm(v)
    if isapprox(v_norm, 0.0; atol=1e-12)
        throw(ArgumentError("Rotation axis v cannot be zero vector"))
    end
    if !isapprox(v_norm, 1.0; atol=1e-10)
        @warn "Normalizing non-unit rotation axis"
        v ./= v_norm
    end
    return v
end

"""
    generate_pov_scene(v, theta, t, output_dir)

Generate a single POV-Ray file using a template with placeholders.
Relies on POV-Ray's Axis_Rotate_Trans and built-in textures.
`theta` should be provided in radians; it is converted to degrees for POV-Ray.
"""
function generate_pov_scene(v::Vector{Float64}, theta::Float64, t::Vector{Float64}, output_dir::String)
    template_path = joinpath(ASSETS_DIR, "mobius_template.pov")
    if !isfile(template_path)
        error("Missing template: $template_path")
    end

    template = read(template_path, String)
    theta_deg = Base.rad2deg(theta)

    # Replace placeholders
    vars = ["X@", "Y@", "Z@"]
    pov_code = replace(template,
                       (("@V_" .* vars) .=> string.(v))...,
                           "@THETA@" => string(theta_deg),
                       (("@T_" .* vars) .=> string.(t))...
    )

    scene_path = joinpath(output_dir, "mobius.pov")
    write(scene_path, pov_code)
    return scene_path
end

"""
    generate_pov_ini(output_dir, nframes, resolution; quality=:high)

Generate a minimal, robust .ini file tailored to the requested quality
preset.
"""
function generate_pov_ini(
    output_dir::String,
    nframes::Int,
    resolution::Tuple{Int,Int};
    quality::Symbol=:high,
)
    template_path = joinpath(ASSETS_DIR, "render.ini")
    if !isfile(template_path)
        error("Missing template: $template_path")
    end

    template = read(template_path, String)
    settings = quality_settings(quality).pov
    ini_content = replace(
        template,
        "@INPUT_FILE@" => "mobius.pov",
        "@WIDTH@" => string(resolution[1]),
        "@HEIGHT@" => string(resolution[2]),
        "@FINAL_FRAME@" => string(nframes),
        "@ANTIALIAS@" => settings.antialias,
        "@ANTIALIAS_DEPTH@" => string(settings.antialias_depth),
        "@SAMPLING_METHOD@" => string(settings.sampling_method),
        "@ANTIALIAS_THRESHOLD@" => string(settings.antialias_threshold),
        "@POVRAY_FLAGS@" => settings.flags,
    )
    ini_path = joinpath(output_dir, "render.ini")
    write(ini_path, ini_content)
    # return ini_path
    return "render.ini"
end

"""
    copy_macros(output_dir, nframes, resolution; quality=:high)
"""
function copy_macros(output_dir::String)
    _file = "macros.inc"
    _path = joinpath(ASSETS_DIR, _file)
    if !isfile(_path)
        error("Missing template: $_path")
    end

    contents = read(_path, String)
    ini_path = joinpath(output_dir, _file)
    write(ini_path, contents)
    # return ini_path
    return _file
end

## v, theta, t coming from `MobiusSphere` package in form of v::Vector{T}, x::T, t::Vector{T}
## where T may be CalciumFieldElem, T <: Real,...
"""
    render_mobius_animation(v, theta, t; output="mobius.mp4", fps=30,
                            resolution=(1280,720), nframes=150, quality=:high)

Render a Möbius sphere animation in the style of "Möbius Transformations Revealed".
`theta` is specified in radians and converted to degrees for the POV-Ray scene.
The `quality` keyword toggles coordinated POV-Ray and ffmpeg presets ranging
from `:draft` (fastest) to `:high` (default, best fidelity). Set `keep_temp=true`
to retain the rendered frame directory alongside the exported video for
debugging or post-processing.
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
    keep_temp::Bool=false,
)
    v = validate_inputs(v, theta, t)

    output_path = abspath(output)
    parent_dir = dirname(output_path)
    if parent_dir != "."
        mkpath(parent_dir)
    end

    preserved_dir = Ref{Union{Nothing,String}}(nothing)
    mktempdir() do output_dir
        copy_macros(output_dir)
        ini_file = generate_pov_ini(output_dir, nframes, resolution; quality=quality)
        povraycall(output_dir, v, theta, t, ini_file)

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

function ffmpegcall(
    output_dir,
    output_path::String="mobius.mp4",
    fps::Int=30,
    resolution::Tuple{Int,Int}=(1280, 720),
    quality::Symbol=:high,
)
    # 🔍 Auto-detect frame numbering format
    frame_pattern = detect_frame_pattern(output_dir)

    # Convert to video
    @info "Creating video with ffmpeg..."
    if endswith(output_path, ".mp4")
        settings = quality_settings(quality).ffmpeg
        cmd = `ffmpeg -y -framerate $fps -i $frame_pattern -c:v libx264 -preset $(settings.preset) -crf $(settings.crf) -pix_fmt yuv420p $output_path`
    elseif endswith(output_path, ".gif")
        cmd = `ffmpeg -y -framerate $fps -i $frame_pattern -vf "fps=$fps,scale=$(resolution[1]):$(resolution[2]):flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" $output_path`
    else
        error("Unsupported output format. Use .mp4 or .gif")
    end
    run(Cmd(cmd, dir=output_dir))
end

function derived_temp_destination(output_path::AbstractString)
    stem, _ = splitext(basename(output_path))
    return joinpath(dirname(output_path), "$(stem)_frames")
end

function povraycall(
    output_dir,
    v, theta, t,
    ini_file
    )
    @info "Working in temporary directory: $output_dir"
    # Generate files
    generate_pov_scene(v, theta, t, output_dir)

    # Run POV-Ray
    @info "Rendering frames with POV-Ray..."
    run(Cmd(`povray $ini_file`, dir=output_dir))
end

function detect_frame_pattern(output_dir::String)
    for f in readdir(output_dir)
        m = match(r"frame_(\d+)\.png", f)
        if !isnothing(m)
            num_str = m.captures[1]
            ndigits = length(num_str)
            return "frame_%0$(ndigits)d.png"
        end
    end
    error("No frame_*.png files found in $output_dir")
end

end # module
