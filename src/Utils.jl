
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
    elseif quality == :ultra
        return (
            pov = (
                antialias = "On",
                antialias_depth = 5,
                sampling_method = 2,
                antialias_threshold = 0.03,
                flags = "+A0.03\n+AM2 +R5\n+Q11\n+UA\nRadiosity=On\nPhotons=On",
            ),
            ffmpeg = (
                crf = 18,
                preset = "slow",
            ),
        )
    elseif quality == :film
        return (
            pov = (
                antialias = "On",
                antialias_depth = 6,
                sampling_method = 2,
                antialias_threshold = 0.02,
                flags = "+A0.02\n+AM2 +R7\n+Q13\n+UA\nRadiosity=On\nPhotons=On",
            ),
            ffmpeg = (
                crf = 16,
                preset = "slower",
            ),
        )
    else
        valid = join(string.((:draft, :medium, :high, :ultra, :film)), ", ")
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

function derived_temp_destination(output_path::AbstractString)
    stem, _ = splitext(basename(output_path))
    return joinpath(dirname(output_path), "$(stem)_frames")
end

## POV-Ray not allow predefine output string, which is needed by ffmepg, funny enough.
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
