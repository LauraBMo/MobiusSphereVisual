"""
    generate_pov_scene(v, theta, t, output_dir; global_settings_extra="")

Generate a single POV-Ray file using a template with placeholders.
Relies on POV-Ray's Axis_Rotate_Trans and built-in textures.
`theta` should be provided in radians; it is converted to degrees for POV-Ray.
`global_settings_extra` injects additional lines inside the template's
`global_settings` block, enabling radiosity or photon settings when requested.
"""
function generate_pov_scene(
    v::Vector{Float64},
    theta::Float64,
    t::Vector{Float64},
    output_dir::String;
    global_settings_extra::AbstractString="",
)
    template_path = joinpath(ASSETS_DIR, "mobius_template.pov")
    if !isfile(template_path)
        error("Missing template: $template_path")
    end

    template = read(template_path, String)
    theta_deg = Base.rad2deg(theta)

    # Replace placeholders
    vars = ["X@", "Y@", "Z@"]
    pov_code = replace(
        template,
        "@GLOBAL_SETTINGS_EXTRA@" => global_settings_extra,
        (("@V_" .* vars) .=> string.(v))...,
        "@THETA@" => string(theta_deg),
        (("@T_" .* vars) .=> string.(t))...,
    )

    scene_path = joinpath(output_dir, "mobius.pov")
    write(scene_path, pov_code)
    return scene_path
end

"""
    generate_pov_ini(output_dir, nframes, resolution; pov_settings)

Generate a minimal, robust .ini file tailored to the requested sampling
parameters. Pass a NamedTuple containing the POV-Ray fields (antialias,
depth, sampling method, threshold, flags, radiosity, photons). A convenience
method remains available that accepts `quality` and `sampling_overrides` for
backwards compatibility.
"""
function generate_pov_ini(
    output_dir::String,
    nframes::Int,
    resolution::Tuple{Int,Int};
    settings::NamedTuple,
)
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
        "@ANTIALIAS@" => settings.antialias,
        "@ANTIALIAS_DEPTH@" => string(settings.antialias_depth),
        "@SAMPLING_METHOD@" => string(settings.sampling_method),
        "@ANTIALIAS_THRESHOLD@" => string(settings.antialias_threshold),
        "@POVRAY_FLAGS@" => settings.flags,
    )
    ini_path = joinpath(output_dir, "render.ini")
    write(ini_path, ini_content)
    # return ini_path
    return "render.ini"
end

"""
    generate_pov(v, theta, t, output_dir, nframes, resolution; quality=:high, sampling=nothing)

Create the POV-Ray scene and configuration files for an animation render.
Returns a tuple containing the `.ini` filename and the path to the generated
scene. Quality presets are merged with optional `sampling` overrides before
delegating to `generate_pov_ini` and `generate_pov_scene`.
"""
function generate_pov(
    v::Vector{Float64},
    theta::Float64,
    t::Vector{Float64},
    output_dir::String,
    nframes::Int,
    resolution::Tuple{Int,Int};
    quality::Symbol=:high,
    sampling::Union{Nothing,NamedTuple,Dict}=nothing,
    )
    sampling = _normalize_sampling_overrides(sampling)
    settings = merge(quality_settings(quality).pov, sampling)
    global_settings = global_settings_extra(settings)

    ini_file = generate_pov_ini(output_dir, nframes, resolution; settings=settings)
    scene = generate_pov_scene(v, theta, t, output_dir;
                               global_settings_extra = global_settings)
    return ini_file, scene
end

"""
    _normalize_sampling_overrides(sampling)

Normalize sampling overrides into a `NamedTuple`. Accepts `nothing`, an
existing `NamedTuple`, or a `Dict` whose keys are converted to symbols. Throws
an `ArgumentError` for any other input type.
"""
function _normalize_sampling_overrides(sampling)
    if sampling === nothing
        return NamedTuple()
    elseif sampling isa NamedTuple
        return sampling
    elseif sampling isa Dict
        return (; (Symbol(key) => value for (key, value) in sampling)...)
    else
        throw(ArgumentError(
            "sampling overrides must be provided as a NamedTuple or Dict, got $(typeof(sampling))",
        ))
    end
end

"""
    copy_macros(output_dir)
"""
function copy_macros(output_dir::String)
    _file = "macros.inc"
    _path = joinpath(ASSETS_DIR, _file)
    if !isfile(_path)
        error("Missing file: $_path")
    end

    ini_path = joinpath(output_dir, _file)
    cp(_path, ini_path)
    return _file
end
