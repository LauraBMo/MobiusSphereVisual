# -- Miscelaneos helpers -----------------------------------------------------
const QUALITY_PRESETS = Dict{Symbol, NamedTuple}(
    :draft => (
        pov = (
            antialias = "Off",
            antialias_depth = 1,
            sampling_method = 1,
            antialias_threshold = 0.3,
            flags = "+A0.5\n+AM1 +R1\n+Q08\n+UA",
            radiosity = false,
            photons = false,
        ),
        ffmpeg = (
            crf = 30,
            preset = "veryfast",
        ),
    ),
    :medium => (
        pov = (
            antialias = "On",
            antialias_depth = 2,
            sampling_method = 2,
            antialias_threshold = 0.1,
            flags = "+A0.2\n+AM2 +R3\n+Q09\n+UA",
            radiosity = false,
            photons = false,
        ),
        ffmpeg = (
            crf = 23,
            preset = "faster",
        ),
    ),
    :high => (
        pov = (
            antialias = "On",
            antialias_depth = 3,
            sampling_method = 2,
            antialias_threshold = 0.05,
            flags = "+A0.1\n+AM2 +R3\n+Q09\n+UA",
            radiosity = false,
            photons = false,
        ),
        ffmpeg = (
            crf = 20,
            preset = "medium",
        ),
    ),
    :ultra => (
        pov = (
            antialias = "On",
            antialias_depth = 5,
            sampling_method = 2,
            antialias_threshold = 0.03,
            flags = "+A0.03\n+AM2 +R5\n+Q11\n+UA",
            radiosity = true,
            photons = true,
        ),
        ffmpeg = (
            crf = 18,
            preset = "slow",
        ),
    ),
    :film => (
        pov = (
            antialias = "On",
            antialias_depth = 6,
            sampling_method = 2,
            antialias_threshold = 0.02,
            flags = "+A0.02\n+AM2 +R7\n+Q13\n+UA",
            radiosity = true,
            photons = true,
        ),
        ffmpeg = (
            crf = 16,
            preset = "slower",
        ),
    ),
)
function derived_temp_destination(output_path::AbstractString)
    stem, _ = splitext(basename(output_path))
    return joinpath(dirname(output_path), "$(stem)_frames")
end

# -- Validation helpers -----------------------------------------------------
function _validate_resolution(resolution::Tuple{Int,Int})
    width, height = resolution
    if width <= 0 || height <= 0
        throw(ArgumentError("resolution must contain positive integers, got $resolution"))
    end
    return resolution
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

# -- Building files helpers -----------------------------------------------------
"""
    quality_settings(quality)

Return the rendering settings associated with `quality`.

The preset controls both POV-Ray sampling quality and ffmpeg encoding
parameters so that a single keyword can trade fidelity for faster render
times.
"""
function quality_settings(quality::Symbol)
    if !haskey(QUALITY_PRESETS, quality)
        valid = join(string.(collect(keys(QUALITY_PRESETS))), ", ")
        throw(ArgumentError("Unknown quality preset: $quality. Supported presets: $valid"))
    end
    return QUALITY_PRESETS[quality]
end

const RADIOSITY_BLOCK = join(
    [
        "  radiosity {",
        "    pretrace_start 0.08",
        "    pretrace_end 0.005",
        "    count 200",
        "    recursion_limit 2",
        "    nearest_count 10",
        "    low_error_factor 0.5",
        "    minimum_reuse 0.015",
        "    maximum_reuse 0.1",
        "    brightness 1.0",
        "  }",
    ],
    "\n",
)

const PHOTONS_BLOCK = join(
    [
        "  photons {",
        "    spacing 0.025",
        "    gather 40, 80",
        "    max_trace_level 12",
        "  }",
    ],
    "\n",
)

function global_settings_extra(pov_settings::NamedTuple)
    sections = String[]
    if get(pov_settings, :radiosity, false)
        push!(sections, RADIOSITY_BLOCK)
    end
    if get(pov_settings, :photons, false)
        push!(sections, PHOTONS_BLOCK)
    end
    return isempty(sections) ? "" : "\n" * join(sections, "\n")
end
