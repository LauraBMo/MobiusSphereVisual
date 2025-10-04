
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
