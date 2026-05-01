"""
    generate_pov_scene(v, theta, t, output_dir; global_settings_extra="")

Substitute animation parameters into the POV-Ray template and write it to disk.
`theta` is in radians; converted to degrees here.

Coordinate note: MobiusSphere uses z as the polar axis (NorthAxis = 3, z-up);
POV-Ray uses y-up. Axes 2 and 3 are swapped on output so that [0,0,1] (north
pole in Julia) maps to <0,1,0> (up in POV-Ray).

Optional `global_settings_extra` injects radiosity/photon blocks into the
template's global_settings block.
"""
function generate_pov_scene(
    v::Vector{Float64},
    theta::Float64,
    t::Vector{Float64},
    output_dir::String;
    global_settings_extra::AbstractString="",
)
    template_path = joinpath(ASSETS_DIR, "mobius_template.pov")
    isfile(template_path) || error("Missing template: $template_path")

    template = read(template_path, String)
    theta_deg = Base.rad2deg(theta)

    # MobiusSphere: z-up (index 3 = north pole). POV-Ray: y-up. Swap Julia axes 2 ↔ 3.
    pov_code = replace(
        template,
        "@GLOBAL_SETTINGS_EXTRA@" => global_settings_extra,
        "@V_X@" => string(v[1]),
        "@V_Y@" => string(v[3]),
        "@V_Z@" => string(v[2]),
        "@THETA@" => string(theta_deg),
        "@T_X@" => string(t[1]),
        "@T_Y@" => string(t[3]),
        "@T_Z@" => string(t[2]),
    )

    scene_path = joinpath(output_dir, "mobius.pov")
    write(scene_path, pov_code)
    @debug "POV-Ray scene written to: $scene_path"
    return scene_path
end

"""
    generate_pov_ini(output_dir, nframes, resolution; settings)

Write a render.ini from the assets template with sampling parameters filled in.
"""
function generate_pov_ini(
    output_dir::String,
    nframes::Int,
    resolution::Tuple{Int,Int};
    settings::NamedTuple,
)
    template_path = joinpath(ASSETS_DIR, "render.ini")
    isfile(template_path) || error("Missing template: $template_path")

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
    @debug "POV-Ray configuration written to: $ini_path"
    return "render.ini"
end

"""
    generate_pov(v, theta, t, output_dir, nframes, resolution; quality, sampling)

Create the POV-Ray scene and ini files. Returns `(ini_filename, scene_path)`.
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
    gs_extra = global_settings_extra(settings)

    ini_file = generate_pov_ini(output_dir, nframes, resolution; settings=settings)
    scene    = generate_pov_scene(v, theta, t, output_dir; global_settings_extra=gs_extra)
    return ini_file, scene
end

function _normalize_sampling_overrides(sampling)
    if sampling === nothing
        return NamedTuple()
    elseif sampling isa NamedTuple
        return sampling
    elseif sampling isa Dict
        return (; (Symbol(key) => value for (key, value) in sampling)...)
    else
        throw(ArgumentError(
            "sampling overrides must be a NamedTuple or Dict, got $(typeof(sampling))",
        ))
    end
end

"""
    copy_assets(output_dir)

Copy all POV-Ray include files required by the template into `output_dir`.
"""
function copy_assets(output_dir::String)
    for file in ("macros.inc", "mobius_textures.inc", "mobius_scene.inc")
        src = joinpath(ASSETS_DIR, file)
        isfile(src) || error("Missing asset: $src")
        cp(src, joinpath(output_dir, file))
    end
end
