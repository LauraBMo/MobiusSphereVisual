module MobiusSphereVisual

using Printf
using LinearAlgebra
using FileIO

export render_mobius_animation, coerce_motion_parameters

const AXIS_KEYS = (:v, :axis, :rotation_axis)
const ANGLE_KEYS = (:theta, :angle, :rotation_angle)
const TRANSLATION_KEYS = (:t, :translation, :offset, :translation_vector)

function _has_coeff_key(data, key)
    if data isa NamedTuple
        return haskey(data, key)
    elseif data isa AbstractDict
        return haskey(data, key)
    else
        return Base.hasproperty(data, key)
    end
end

function _get_coeff_value(data, key)
    if data isa NamedTuple
        return getfield(data, key)
    elseif data isa AbstractDict
        return data[key]
    else
        return getproperty(data, key)
    end
end

function _coerce_vector(value, label)
    if value isa AbstractVector
        vec = Float64.(collect(value))
    elseif value isa Tuple
        vec = Float64.(collect(value))
    else
        throw(ArgumentError("Expected $label to be a 3-element vector or tuple, got $(typeof(value))"))
    end
    if length(vec) != 3
        throw(ArgumentError("Expected $label to have length 3, got $(length(vec))"))
    end
    return vec
end

function _coerce_angle(value)
    try
        return Float64(value)
    catch
        throw(ArgumentError("Expected angle to be convertible to Float64, got $(typeof(value))"))
    end
end

function _extract_coeff_component(data, keys, label)
    for key in keys
        if _has_coeff_key(data, key)
            return _get_coeff_value(data, key)
        end
    end
    throw(ArgumentError("Could not find $label in the provided coefficients. Expected one of: $(join(string.(keys), ", "))."))
end

"""
    coerce_motion_parameters(data)

Normalize motion information that may come from the `MobiusSphere` package.
Accepts named tuples, dictionaries or structs that expose any of the
following field names:

- axis: `:v`, `:axis`, `:rotation_axis`
- angle: `:theta`, `:angle`, `:rotation_angle`
- translation: `:t`, `:translation`, `:offset`, `:translation_vector`

Returns a tuple `(v, theta, t)` where the vectors are `Vector{Float64}` and
`theta` is a `Float64`.
"""
function coerce_motion_parameters(data)
    if data isa Tuple && length(data) == 3
        v = _coerce_vector(data[1], "rotation axis")
        theta = _coerce_angle(data[2])
        t = _coerce_vector(data[3], "translation")
        return v, theta, t
    end

    axis_value = _extract_coeff_component(data, AXIS_KEYS, "rotation axis")
    angle_value = _extract_coeff_component(data, ANGLE_KEYS, "rotation angle")
    translation_value = _extract_coeff_component(data, TRANSLATION_KEYS, "translation vector")

    v = _coerce_vector(axis_value, "rotation axis")
    theta = _coerce_angle(angle_value)
    t = _coerce_vector(translation_value, "translation vector")
    return v, theta, t
end

const ASSETS_DIR = joinpath(@__DIR__, "..", "assets")

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
"""
function generate_pov_scene(v::Vector{Float64}, theta::Float64, t::Vector{Float64}, output_dir::String)
    template_path = joinpath(ASSETS_DIR, "mobius_template.pov")
    if !isfile(template_path)
        error("Missing template: $template_path")
    end

    template = read(template_path, String)

    # Replace placeholders
    vars = ["X", "Y", "Z"]
    pov_code = replace(template,
                       (("@V_" .* vars .* "@") .=> string.(v))...,
                           "@THETA@" => string(theta),
                       (("@T_" .* vars .* "@") .=> string.(t))...
        # "@V_X@" => string(v[1]),
        # "@V_Y@" => string(v[2]),
        # "@V_Z@" => string(v[3]),
        # "@THETA@" => string(theta),
        # "@T_X@" => string(t[1]),
        # "@T_Y@" => string(t[2]),
        # "@T_Z@" => string(t[3])
    )

    scene_path = joinpath(output_dir, "mobius.pov")
    write(scene_path, pov_code)
    return scene_path
end

"""
    generate_pov_ini(output_dir, nframes, resolution)

Generate a minimal, robust .ini file.
"""
function generate_pov_ini(output_dir::String, nframes::Int, resolution::Tuple{Int,Int})
    template_path = joinpath(ASSETS_DIR, "render.ini")
    if !isfile(template_path)
        error("Missing template: $template_path")
    end

    template = read(template_path, String)
    ini_content = replace(
        template,
        "@INPUT_FILE@" => "mobius.pov",
        "@WIDTH@" => string(resolution[1]),
        "@HEIGHT@" => string(resolution[2]),
        "@FINAL_FRAME@" => string(nframes),
    )
    ini_path = joinpath(output_dir, "render.ini")
    write(ini_path, ini_content)
    # return ini_path
    return "render.ini"
end

"""
    render_mobius_animation(v, theta, t; output="mobius.mp4", fps=30, resolution=(1280,720), nframes=150)

Render a Möbius sphere animation in the style of "Möbius Transformations Revealed".
"""
function render_mobius_animation(
    v::Vector{Float64},
    theta::Float64,
    t::Vector{Float64};
    output::String="mobius.mp4",
    fps::Int=30,
    resolution::Tuple{Int,Int}=(1280, 720),
    nframes::Int=150
)
    v = validate_inputs(v, theta, t)

    output_path = abspath(output)
    parent_dir = dirname(output)
    if parent_dir != "."
        mkpath(dirname(output_path))
    end


    # mktempdir() do output_dir
    output_dir = mktempdir()

    ini_file = generate_pov_ini(output_dir, nframes, resolution)
    povraycall(output_dir, v, theta, t, ini_file)

    ffmpegcall(output_dir, output_path, fps, resolution)

    @info "Animation saved to: $output_path"
    # Optionally keep temp dir for debugging by commenting out:
    # rm(output_dir, recursive=true)
end

"""
    render_mobius_animation(coefficients; kwargs...)

Convenience wrapper that accepts coefficient objects produced by the
`MobiusSphere` package. The object must expose axis/angle/translation values
under any of the supported field names described in [`coerce_motion_parameters`](@ref).
"""
function render_mobius_animation(coefficients; kwargs...)
    v, theta, t = coerce_motion_parameters(coefficients)
    return render_mobius_animation(v, theta, t; kwargs...)
end

function ffmpegcall(
    output_dir,
    output_path::String="mobius.mp4",
    fps::Int=30,
    resolution::Tuple{Int,Int}=(1280, 720),
)
    # 🔍 Auto-detect frame numbering format
    frame_pattern = detect_frame_pattern(output_dir)

    # Convert to video
    @info "Creating video with ffmpeg..."
    if endswith(output_path, ".mp4")
        cmd = `ffmpeg -y -framerate $fps -i $frame_pattern -c:v libx264 -pix_fmt yuv420p $output_path`
    elseif endswith(output_path, ".gif")
        cmd = `ffmpeg -y -framerate $fps -i $frame_pattern -vf "fps=$fps,scale=$(resolution[1]):$(resolution[2]):flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" $output_path`
    else
        error("Unsupported output format. Use .mp4 or .gif")
    end
    run(Cmd(cmd, dir=output_dir))
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
