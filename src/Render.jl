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
        "    spacing 0.012",
        "    gather 60, 120",
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
        ffmpeg = (crf = 30, preset = "veryfast", bitrate = "1500k"),
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
        ffmpeg = (crf = 23, preset = "faster", bitrate = "3000k"),
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
        ffmpeg = (crf = 20, preset = "medium", bitrate = "6000k"),
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
        ffmpeg = (crf = 18, preset = "slow", bitrate = "10000k"),
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
        ffmpeg = (crf = 16, preset = "slower", bitrate = "14000k"),
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

"""
    _h264_encoder()

Return the name of an available H.264 software encoder, preferring `libx264`
(best quality/controls) and falling back to `libopenh264`, which ships with
patent-free builds such as Fedora's `ffmpeg-free`. Returns `nothing` if neither
is present, in which case callers fall back to GIF.
"""
function _h264_encoder()
    out = try
        read(`ffmpeg -hide_banner -encoders`, String)
    catch
        return nothing
    end
    for enc in ("libx264", "libopenh264")
        occursin(Regex("\\b$(enc)\\b"), out) && return enc
    end
    return nothing
end

# ── Held first/last frame ("hold") ───────────────────────────────────────────
# `hold` resolves to seconds of cloned first/last frame padded onto the video:
# `true` → 1.5 s (default), `false`/0 → none, a number → that many seconds.
_hold_seconds(hold::Bool) = hold ? 1.5 : 0.0
_hold_seconds(hold::Real) = Float64(hold)

# The ffmpeg `tpad` filter string for `sec` seconds of held ends, or "" for none.
_tpad_vf(sec::Real) = sec > 0 ?
    "tpad=start_duration=$(sec):start_mode=clone:stop_duration=$(sec):stop_mode=clone" : ""

function _build_mp4_command(ffmpeg::String, pattern::String, fps::Int, output::String,
                            quality, encoder::String; hold_sec::Real=1.5)
    s = quality_settings(quality).ffmpeg
    cmd = [ffmpeg, "-y", "-framerate", "$fps", "-i", pattern]
    vf = _tpad_vf(hold_sec)
    isempty(vf) || append!(cmd, ["-vf", vf])
    append!(cmd, ["-c:v", encoder])
    if encoder == "libx264"
        # x264 uses CRF + named presets.
        append!(cmd, ["-preset", s.preset, "-crf", "$(s.crf)"])
    else
        # libopenh264 has no CRF/preset; drive it with a target bitrate. Force
        # Constrained Baseline — otherwise openh264 emits an "UNSPECIFIC" profile
        # that many players (VLC) decode as an all-black video.
        append!(cmd, ["-b:v", s.bitrate, "-profile:v", "constrained_baseline"])
    end
    append!(cmd, ["-pix_fmt", "yuv420p", output])
    return Cmd(cmd)
end

function _build_webm_command(ffmpeg::String, pattern::String, fps::Int, output::String,
                             quality; hold_sec::Real=1.5)
    s = quality_settings(quality).ffmpeg
    vp9_crf = clamp(s.crf + 8, 10, 40)   # shift x264-scale CRF into VP9's 0–63 range
    cmd = [ffmpeg, "-y", "-framerate", "$fps", "-i", pattern]
    vf = _tpad_vf(hold_sec)
    isempty(vf) || append!(cmd, ["-vf", vf])
    append!(cmd, ["-c:v", "libvpx-vp9",
                  "-crf", "$vp9_crf", "-b:v", "0",
                  "-deadline", "good", "-cpu-used", "4",
                  "-pix_fmt", "yuv420p",
                  output])
    return Cmd(cmd)
end

function _build_gif_command(ffmpeg::String, pattern::String, fps::Int,
                            resolution::Tuple{Int,Int}, output::String; hold_sec::Real=1.5)
    w, h = resolution
    chain = "fps=$fps,scale=$w:$h:flags=lanczos"
    tp = _tpad_vf(hold_sec)
    isempty(tp) || (chain *= ",$tp")   # clone held ends before palette split so both see them
    vf = "$chain,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse"
    return Cmd([ffmpeg, "-y",
                "-framerate", "$fps", "-i", pattern,
                "-vf", vf,
                output])
end

"""
    ffmpegcall(output_dir, output_path, fps, resolution, quality; hold=true)

Combine rendered frames in `output_dir` into an MP4, WebM or GIF at `output_path`.

`hold` pads a held (cloned) first and last frame onto the video: `true` → 1.5 s at
each end (default), `false` (or `0`) → none, a number → that many seconds. Applies
to all three formats.
"""
function ffmpegcall(
    output_dir,
    output_path::String="mobius.mp4",
    fps::Int=30,
    resolution::Tuple{Int,Int}=(1280, 720),
    quality::Symbol=:high;
    hold::Union{Bool,Real}=true,
)
    pattern = detect_frame_pattern(output_dir)
    ffmpeg  = "ffmpeg"
    success(`which $ffmpeg`) ||
        throw(ErrorException("FFmpeg not found. Please install FFmpeg and ensure it is in PATH."))

    hold_sec = _hold_seconds(hold)
    actual_output = output_path
    cmd = if endswith(output_path, ".mp4")
        encoder = _h264_encoder()
        if isnothing(encoder)
            actual_output = splitext(output_path)[1] * ".gif"
            @warn "No H.264 software encoder (libx264/libopenh264) in this FFmpeg build; \
                   writing GIF instead." gif = actual_output
            _build_gif_command(ffmpeg, pattern, fps, resolution, actual_output; hold_sec=hold_sec)
        else
            _build_mp4_command(ffmpeg, pattern, fps, output_path, quality, encoder; hold_sec=hold_sec)
        end
    elseif endswith(output_path, ".webm")
        _build_webm_command(ffmpeg, pattern, fps, output_path, quality; hold_sec=hold_sec)
    elseif endswith(output_path, ".gif")
        _build_gif_command(ffmpeg, pattern, fps, resolution, output_path; hold_sec=hold_sec)
    else
        error("Unsupported output format '$(output_path)'. Use .mp4, .webm or .gif")
    end

    try
        run(Cmd(cmd; dir=output_dir))
        @info "FFmpeg processing completed."
    catch e
        @error "FFmpeg processing failed" exception=(e, catch_backtrace())
        rethrow(e)
    end
    return actual_output
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
