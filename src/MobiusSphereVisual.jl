module MobiusSphereVisual

using Printf
using LinearAlgebra
using FileIO

export render_mobius_animation

const ASSETS_DIR = joinpath(@__DIR__, "..", "assets")

"""
    validate_inputs(v, theta, t)

Ensure `v` is a 3D unit vector (normalizing if needed) and `t` is a 3D
vector. The inputs are coerced to floating-point vectors so callers can pass
integer vectors without hitting a `MethodError`. Returns the normalized axis,
the translation vector, and a floating-point rotation angle.
"""
function validate_inputs(
    v::AbstractVector{<:Real},
    theta::Real,
    t::AbstractVector{<:Real}
)
    if length(v) != 3 || length(t) != 3
        throw(ArgumentError("v and t must be 3D vectors"))
    end

    v = collect(float.(v))
    t = collect(float.(t))

    v_norm = norm(v)
    if isapprox(v_norm, 0.0; atol=1e-12)
        throw(ArgumentError("Rotation axis v cannot be zero vector"))
    end
    if !isapprox(v_norm, 1.0; atol=1e-10)
        @warn "Normalizing non-unit rotation axis"
        v ./= v_norm
    end
    return v, t, float(theta)
end

"""
    generate_pov_scene(v, theta, t, output_dir)

Generate a single POV-Ray file using a template with placeholders.
Relies on POV-Ray's Axis_Rotate_Trans and built-in textures.
"""
function generate_pov_scene(
    v::AbstractVector{<:Real},
    theta::Real,
    t::AbstractVector{<:Real},
    output_dir::String
)
    template_path = joinpath(ASSETS_DIR, "mobius_template.pov")
    if !isfile(template_path)
        error("Missing template: $template_path")
    end

    template = read(template_path, String)

    # Replace placeholders
    vars = ["X", "Y", "Z"]
    v_strings = string.(float.(v))
    t_strings = string.(float.(t))
    theta = float(theta)
    pov_code = replace(template,
                       (("@V_" .* vars .* "@") .=> v_strings)...,
                           "@THETA@" => string(theta),
                       (("@T_" .* vars .* "@") .=> t_strings)...
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
    ini_content = """
Input_File_Name="mobius.pov"
Output_File_Name="frame_"
Output_File_Type=N ; PNG, numbered as frame_0001.png, frame_0002.png, ...

Width=$(resolution[1])
Height=$(resolution[2])

Antialias=On
Antialias_Depth=3
Sampling_Method=2
Antialias_Threshold=0.05

;; # +W1920 +H1080
+A0.1
+AM2 +R3
+Q09
+UA

; === Animation settings ===
Initial_Frame=1
Final_Frame=$nframes
Initial_Clock=0
Final_Clock=1
Cyclic_Animation=Off
Pause_when_Done=Off

; === Performance tuning ===
Bounding=Off
Display=Off
Verbose=Off
"""
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
    v::AbstractVector{<:Real},
    theta::Real,
    t::AbstractVector{<:Real};
    output::String="mobius.mp4",
    fps::Int=30,
    resolution::Tuple{Int,Int}=(1280, 720),
    nframes::Int=150
)
    v, t, theta = validate_inputs(v, theta, t)


    # mktempdir() do output_dir
    output_dir = mktempdir()

    ini_file = generate_pov_ini(output_dir, nframes, resolution)
    povraycall(output_dir, v, theta, t, ini_file)

    ffmpegcall(output_dir, output, fps, resolution)

    @info "Animation saved to: $output in $output_dir/$output"
    # Optionally keep temp dir for debugging by commenting out:
    # rm(output_dir, recursive=true)
end

function ffmpegcall(
    output_dir,
    output::String="mobius.mp4",
    fps::Int=30,
    resolution::Tuple{Int,Int}=(1280, 720),
)
    # 🔍 Auto-detect frame numbering format
    frame_pattern = detect_frame_pattern(output_dir)

    # Convert to video
    @info "Creating video with ffmpeg..."
    if endswith(output, ".mp4")
        cmd = `ffmpeg -y -framerate $fps -i $frame_pattern -c:v libx264 -pix_fmt yuv420p $output`
    elseif endswith(output, ".gif")
        cmd = `ffmpeg -y -framerate $fps -i $frame_pattern -vf "fps=$fps,scale=$(resolution[1]):$(resolution[2]):flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" $output`
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
