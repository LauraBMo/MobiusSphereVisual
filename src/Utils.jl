# Miscellaneous helper functions.
"""
    derived_temp_destination(output_path)

Return the directory path used to store intermediate frames for a render.
The directory is derived from `output_path` by appending a `_frames` suffix to
the output file name and reusing the same parent directory.
"""
function derived_temp_destination(output_path::AbstractString)
    # Reuse the output directory and append a `_frames` suffix to the stem.
    stem, _ = splitext(basename(output_path))
    return joinpath(dirname(output_path), "$(stem)_frames")
end

"""
    povraycall(output_dir, ini_file)

Invoke POV-Ray to render frames described by `ini_file` inside `output_dir`.
The function logs the working directory for transparency and forwards the
`.ini` file to the `povray` executable using Julia's `run`.
"""
function povraycall(output_dir, ini_file)
    @info "Working in temporary directory: $output_dir"
    @info "Rendering frames with POV-Ray..."
    
    # Check if povray executable exists
    if !success(`which povray`)
        throw(ErrorException("POV-Ray executable not found. Please ensure POV-Ray is installed and in your PATH."))
    end
    
    # Run POV-Ray with the generated configuration file inside the temp folder.
    try
        run(Cmd(`povray $ini_file`, dir=output_dir))
        @info "POV-Ray rendering completed successfully"
    catch e
        @error "POV-Ray rendering failed" exception=(e, catch_backtrace())
        rethrow(e)
    end
end

# Validation helper functions.
"""
    _validate_resolution(resolution)

Ensure that the `(width, height)` tuple contains positive integers, returning
the tuple unchanged. Throws an `ArgumentError` when either dimension is zero
or negative.
"""
function _validate_resolution(resolution::Tuple{Int,Int})
    width, height = resolution
    if width <= 0 || height <= 0
        throw(ArgumentError("Resolution must contain positive integers, got $resolution"))
    end
    
    # Check for reasonable resolution limits to prevent excessive memory usage
    max_pixels = 3840 * 2160  # 4K resolution
    if width * height > max_pixels
        @warn "Resolution $(width)x$(height) exceeds 4K. This may require significant memory and processing time."
    end
    
    return resolution
end

"""
    validate_inputs(v, theta, t)

Ensure v is a 3D unit vector; normalize if needed. Ensure t is 3D.
"""
function validate_inputs(v::Vector{Float64}, theta::Float64, t::Vector{Float64})
    # Validate vector dimensions
    if length(v) != 3
        throw(ArgumentError("Rotation axis v must be a 3D vector, got length $(length(v))"))
    end
    
    if length(t) != 3
        throw(ArgumentError("Translation vector t must be a 3D vector, got length $(length(t))"))
    end
    
    # Validate rotation axis
    v_norm = norm(v)
    if isapprox(v_norm, 0.0; atol=1e-12)
        throw(ArgumentError("Rotation axis v cannot be zero vector"))
    end
    
    # Check if rotation axis needs normalization
    if !isapprox(v_norm, 1.0; atol=1e-10)
        @warn "Normalizing non-unit rotation axis (norm = $v_norm)"
        # Preserve the rotation axis direction while enforcing unit length.
        return v ./= v_norm
    end
    
    # Validate theta is finite
    if !isfinite(theta)
        throw(ArgumentError("Rotation angle theta must be finite, got $theta"))
    end
    
    # Validate translation vector components are finite
    if !all(isfinite, t)
        throw(ArgumentError("All components of translation vector t must be finite, got $t"))
    end
    
    return v
end
