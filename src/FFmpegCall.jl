# Frame pattern detection helpers.

raw"""
    detect_frame_pattern(output_dir; rx=r"frame_(\d+)\.png")

POV-Ray does not allow predefined output strings, which FFmpeg expects, so we
detect the pattern ourselves. Scan `output_dir` for image frames and derive the
printf-style pattern used by FFmpeg. The default regular expression matches files named like
`frame_0001.png` and extracts the zero-padded index to determine the required
padding width. Returns a string such as `"frame_%04d.png"`. Throws an
`ArgumentError` if no matching files are found.
"""
function detect_frame_pattern(output_dir::String, rx = r"frame_(\d+)\.png")
    for file in readdir(output_dir)
        m = match(rx, file)
        if !isnothing(m)
            num_str = m.captures[1]
            ndigits = length(num_str)
            return "frame_%0$(ndigits)d.png"
        end
    end
    throw(ArgumentError("No frame_*.png files found in $output_dir"))
end

"""
    ffmpegcall(output_dir::String, output_path::String="mobius.mp4", fps::Int=30, resolution::Tuple{Int,Int}=(1280, 720), quality::Symbol=:high)

Converts a sequence of image frames in `output_dir` into a video file (.mp4 or .gif) using FFmpeg.

# Arguments
- `output_dir::String`: Path to the directory containing the input frames.
- `output_path::String`: Path for the output video file (default "mobius.mp4").
- `fps::Int`: Frames per second for the output video (default 30).
- `resolution::Tuple{Int,Int}`: Target resolution (width, height) for the output (default (1280, 720)).
- `quality::Symbol`: Quality setting for MP4 encoding (default :high). Used by `quality_settings`.
"""
function ffmpegcall(
    output_dir,
    output_path::String="mobius.mp4",
    fps::Int=30,
    resolution::Tuple{Int,Int}=(1280, 720),
    quality::Symbol=:high
)
    # Auto-detect the frame numbering format.
    frame_pattern = detect_frame_pattern(output_dir)

    # Determine the output format and construct the appropriate command.
    # ffmpeg_path = FFMPEG.ffmpeg_exe() # Get the path to the FFmpeg binary managed by FFMPEG.jl.
    # Default to the system ffmpeg binary to avoid depending on the package runtime.
    ffmpeg_path = "ffmpeg"

    if endswith(output_path, ".mp4")
        cmd = _build_mp4_command(ffmpeg_path, frame_pattern, fps, output_path, quality)
    elseif endswith(output_path, ".gif")
        cmd = _build_gif_command(ffmpeg_path, frame_pattern, fps, resolution, output_path)
    else
        error("Unsupported output format '$(output_path)'. Use .mp4 or .gif")
    end

    # Execute the command in the specified directory.
    run(Cmd(cmd, dir=output_dir))
end

# Command construction helpers.

"""
    _build_mp4_command(ffmpeg_path, frame_pattern, fps, output_path, quality)

Constructs the FFmpeg command for encoding an MP4 video.
"""
function _build_mp4_command(ffmpeg_path::String, frame_pattern::String, fps::Int, output_path::String, quality::Any)
    # Retrieve quality settings (for example preset and CRF) from the configuration.
    settings = quality_settings(quality).ffmpeg

    # Build the command as an array of strings to be passed to ffmpeg.

    # Start with the executable path.
    command_parts = [ffmpeg_path]

    # Allow overwriting existing files without prompting.
    push!(command_parts, "-y")

    # Point ffmpeg to the image sequence using the detected frame pattern.
    append!(command_parts, ["-framerate", "$fps", "-i", frame_pattern])

    # Encode using H.264 for broad compatibility.
    append!(command_parts, ["-c:v", "libx264"])

    # Apply preset and quality settings supplied by the caller.
    append!(command_parts, ["-preset", settings.preset])
    append!(command_parts, ["-crf", "$(settings.crf)"])

    # Use a pixel format that plays well on the web and in media players.
    append!(command_parts, ["-pix_fmt", "yuv420p"])

    # Append the output path last.
    push!(command_parts, output_path)

    # Return the command as a `Cmd` object for execution.
    return Cmd(command_parts)
end

"""
    _build_gif_command(ffmpeg_path, frame_pattern, fps, resolution, output_path)

Constructs the FFmpeg command for encoding a GIF animation.
"""
function _build_gif_command(ffmpeg_path::String, frame_pattern::String, fps::Int, resolution::Tuple{Int, Int}, output_path::String)
    width, height = resolution

    # Build the command as an array of strings to be passed to ffmpeg.

    # Start with the executable path.
    command_parts = [ffmpeg_path]

    # Allow overwriting existing files without prompting.
    push!(command_parts, "-y")

    # Point ffmpeg to the image sequence using the detected frame pattern.
    append!(command_parts, ["-framerate", "$fps", "-i", frame_pattern])

    # Build the video filter chain responsible for scaling and palette handling.
    filter_string = ""

    # Ensure the GIF runs at the requested frame rate.
    filter_string *= "fps=$fps,"

    # Resize frames to the requested resolution using high-quality resampling.
    filter_string *= "scale=$width:$height:flags=lanczos,"

    # Split the stream so palette generation does not consume the final frames.
    filter_string *= "split[s0][s1];"

    # Produce an optimized palette from the first branch.
    filter_string *= "[s0]palettegen[p];"

    # Apply the palette to the rendering branch to obtain the final GIF.
    filter_string *= "[s1][p]paletteuse"

    # Attach the filter chain to the command.
    append!(command_parts, ["-vf", filter_string])

    # Append the output path last.
    push!(command_parts, output_path)

    # Return the command as a `Cmd` object for execution.
    return Cmd(command_parts)
end
