# -- Miscellaneous helpers ----------------------------------------------------
"""
    derived_temp_destination(output_path)

Return the directory path used to store intermediate frames for a render.
The directory is derived from `output_path` by appending a `_frames` suffix to
the output file name and reusing the same parent directory.
"""
function derived_temp_destination(output_path::AbstractString)
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
    run(Cmd(`povray $ini_file`, dir=output_dir))
end

# -- Validation helpers -----------------------------------------------------
"""
    _validate_resolution(resolution)

Ensure that the `(width, height)` tuple contains positive integers, returning
the tuple unchanged. Throws an `ArgumentError` when either dimension is zero
or negative.
"""
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
