"""
    generate_pov_scene(v, theta, t, output_dir)

Generate a single POV-Ray file using a template with placeholders.
Relies on POV-Ray's Axis_Rotate_Trans and built-in textures.
`theta` should be provided in radians; it is converted to degrees for POV-Ray.
"""
function generate_pov_scene(v::Vector{Float64}, theta::Float64, t::Vector{Float64}, output_dir::String)
    template_path = joinpath(ASSETS_DIR, "mobius_template.pov")
    if !isfile(template_path)
        error("Missing template: $template_path")
    end

    template = read(template_path, String)
    theta_deg = Base.rad2deg(theta)

    # Replace placeholders
    vars = ["X@", "Y@", "Z@"]
    pov_code = replace(template,
                       (("@V_" .* vars) .=> string.(v))...,
                           "@THETA@" => string(theta_deg),
                       (("@T_" .* vars) .=> string.(t))...
    )

    scene_path = joinpath(output_dir, "mobius.pov")
    write(scene_path, pov_code)
    return scene_path
end

"""
    generate_pov_ini(output_dir, nframes, resolution; quality=:high)

Generate a minimal, robust .ini file tailored to the requested quality
preset.
"""
function generate_pov_ini(
    output_dir::String,
    nframes::Int,
    resolution::Tuple{Int,Int};
    quality::Symbol=:high,
)
    template_path = joinpath(ASSETS_DIR, "render.ini")
    if !isfile(template_path)
        error("Missing template: $template_path")
    end

    template = read(template_path, String)
    settings = quality_settings(quality).pov
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
    copy_macros(output_dir, nframes, resolution; quality=:high)
"""
function copy_macros(output_dir::String)
    _file = "macros.inc"
    _path = joinpath(ASSETS_DIR, _file)
    if !isfile(_path)
        error("Missing template: $_path")
    end

    # contents = read(_path, String)
    ini_path = joinpath(output_dir, _file)
    # write(ini_path, contents)
    # return ini_path
    cp(_path, ini_path)
    return _file
end
