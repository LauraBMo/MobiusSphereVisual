# ── Quality presets ────────────────────────────────────────────────────────────

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
    get(pov_settings, :radiosity, false) && push!(sections, RADIOSITY_BLOCK)
    get(pov_settings, :photons,   false) && push!(sections, PHOTONS_BLOCK)
    return isempty(sections) ? "" : "\n" * join(sections, "\n")
end

# Presets: radiosity on :high and :film; photons on :film only.
const QUALITY_PRESETS = Dict{Symbol,NamedTuple}(
    :draft => (
        pov = (
            antialias           = "Off",
            antialias_depth     = 1,
            sampling_method     = 1,
            antialias_threshold = 0.3,
            flags               = "+A0.5\n+AM1 +R1\n+Q08\n+UA",
            radiosity           = false,
            photons             = false,
        ),
        ffmpeg = (crf = 30, preset = "veryfast"),
    ),
    :medium => (
        pov = (
            antialias           = "On",
            antialias_depth     = 2,
            sampling_method     = 2,
            antialias_threshold = 0.1,
            flags               = "+A0.2\n+AM2 +R3\n+Q09\n+UA",
            radiosity           = false,
            photons             = false,
        ),
        ffmpeg = (crf = 23, preset = "faster"),
    ),
    :high => (
        pov = (
            antialias           = "On",
            antialias_depth     = 3,
            sampling_method     = 2,
            antialias_threshold = 0.05,
            flags               = "+A0.1\n+AM2 +R3\n+Q09\n+UA",
            radiosity           = true,
            photons             = false,
        ),
        ffmpeg = (crf = 20, preset = "medium"),
    ),
    :ultra => (
        pov = (
            antialias           = "On",
            antialias_depth     = 5,
            sampling_method     = 2,
            antialias_threshold = 0.03,
            flags               = "+A0.03\n+AM2 +R5\n+Q11\n+UA",
            radiosity           = true,
            photons             = false,
        ),
        ffmpeg = (crf = 18, preset = "slow"),
    ),
    :film => (
        pov = (
            antialias           = "On",
            antialias_depth     = 6,
            sampling_method     = 2,
            antialias_threshold = 0.02,
            flags               = "+A0.02\n+AM2 +R7\n+Q13\n+UA",
            radiosity           = true,
            photons             = true,
        ),
        ffmpeg = (crf = 16, preset = "slower"),
    ),
)

"""
    quality_settings(quality)

Return the rendering settings for `quality` (one of `:draft`, `:medium`, `:high`,
`:ultra`, `:film`). Controls both POV-Ray sampling and ffmpeg encoding.
"""
function quality_settings(quality::Symbol)
    haskey(QUALITY_PRESETS, quality) || throw(ArgumentError(
        "Unknown quality preset: $quality. Supported: $(join(string.(collect(keys(QUALITY_PRESETS))), ", "))",
    ))
    return QUALITY_PRESETS[quality]
end

# ── Validation ─────────────────────────────────────────────────────────────────

"""
    _validate_resolution(resolution)

Ensure (width, height) are positive integers. Warns above 4K.
"""
function _validate_resolution(resolution::Tuple{Int,Int})
    width, height = resolution
    width > 0 && height > 0 ||
        throw(ArgumentError("Resolution must contain positive integers, got $resolution"))
    width * height > 3840 * 2160 &&
        @warn "Resolution $(width)x$(height) exceeds 4K; may need significant memory."
    return resolution
end

"""
    validate_inputs(v, theta, t)

Ensure `v` is a 3-D unit vector (normalises if needed) and `t` is 3-D with
finite components. Returns the (possibly normalised) axis vector.
"""
function validate_inputs(v::Vector{Float64}, theta::Float64, t::Vector{Float64})
    length(v) == 3 || throw(ArgumentError("Rotation axis v must be 3-D, got length $(length(v))"))
    length(t) == 3 || throw(ArgumentError("Translation t must be 3-D, got length $(length(t))"))

    v_norm = norm(v)
    isapprox(v_norm, 0.0; atol=1e-12) &&
        throw(ArgumentError("Rotation axis v cannot be the zero vector"))
    if !isapprox(v_norm, 1.0; atol=1e-10)
        @warn "Normalising non-unit rotation axis (norm = $v_norm)"
        v = v ./ v_norm
    end

    isfinite(theta) || throw(ArgumentError("Rotation angle theta must be finite, got $theta"))
    all(isfinite, t)  || throw(ArgumentError("All components of t must be finite, got $t"))

    return v
end

# ── POV-Ray call ───────────────────────────────────────────────────────────────

"""
    povraycall(output_dir, ini_file)

Invoke POV-Ray to render frames described by `ini_file` inside `output_dir`.
"""
function povraycall(output_dir, ini_file)
    @info "Working in temporary directory: $output_dir"
    @info "Rendering frames with POV-Ray…"
    success(`which povray`) ||
        throw(ErrorException("POV-Ray not found. Please install POV-Ray and ensure it is in PATH."))
    try
        run(Cmd(`povray $ini_file`, dir=output_dir))
        @info "POV-Ray rendering completed."
    catch e
        @error "POV-Ray rendering failed" exception=(e, catch_backtrace())
        rethrow(e)
    end
end

# ── FFmpeg helpers ─────────────────────────────────────────────────────────────

"""
    detect_frame_pattern(output_dir)

Scan `output_dir` for `frame_\\d+.png` files and return the printf-style pattern
(e.g. `"frame_%04d.png"`) that FFmpeg expects. Throws if no frames are found.
"""
function detect_frame_pattern(output_dir::String, rx=r"frame_(\d+)\.png")
    frame_files = filter(f -> !isnothing(match(rx, f)), readdir(output_dir))
    isempty(frame_files) && throw(ArgumentError("No frame_*.png files found in $output_dir"))
    num_str = match(rx, first(frame_files)).captures[1]
    return "frame_%0$(length(num_str))d.png"
end

function _build_mp4_command(ffmpeg::String, pattern::String, fps::Int, output::String, quality)
    s = quality_settings(quality).ffmpeg
    return Cmd([ffmpeg, "-y",
                "-framerate", "$fps", "-i", pattern,
                "-c:v", "libx264",
                "-preset", s.preset, "-crf", "$(s.crf)",
                "-pix_fmt", "yuv420p",
                output])
end

function _build_gif_command(ffmpeg::String, pattern::String, fps::Int,
                            resolution::Tuple{Int,Int}, output::String)
    w, h = resolution
    vf = "fps=$fps,scale=$w:$h:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse"
    return Cmd([ffmpeg, "-y",
                "-framerate", "$fps", "-i", pattern,
                "-vf", vf,
                output])
end

"""
    ffmpegcall(output_dir, output_path, fps, resolution, quality)

Combine rendered frames in `output_dir` into an MP4 or GIF at `output_path`.
"""
function ffmpegcall(
    output_dir,
    output_path::String="mobius.mp4",
    fps::Int=30,
    resolution::Tuple{Int,Int}=(1280, 720),
    quality::Symbol=:high,
)
    pattern = detect_frame_pattern(output_dir)
    ffmpeg  = "ffmpeg"
    success(`which $ffmpeg`) ||
        throw(ErrorException("FFmpeg not found. Please install FFmpeg and ensure it is in PATH."))

    cmd = if endswith(output_path, ".mp4")
        _build_mp4_command(ffmpeg, pattern, fps, output_path, quality)
    elseif endswith(output_path, ".gif")
        _build_gif_command(ffmpeg, pattern, fps, resolution, output_path)
    else
        error("Unsupported output format '$(output_path)'. Use .mp4 or .gif")
    end

    try
        run(Cmd(cmd; dir=output_dir))
        @info "FFmpeg processing completed."
    catch e
        @error "FFmpeg processing failed" exception=(e, catch_backtrace())
        rethrow(e)
    end
end

# ── Misc helpers ───────────────────────────────────────────────────────────────

"""
    derived_temp_destination(output_path)

Return a sibling directory used to store intermediate frames when `keep_temp=true`.
Derived from `output_path` by appending `_frames` to the filename stem.
"""
function derived_temp_destination(output_path::AbstractString)
    stem, _ = splitext(basename(output_path))
    return joinpath(dirname(output_path), "$(stem)_frames")
end
