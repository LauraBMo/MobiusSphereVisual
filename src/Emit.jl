"""
    markers_pov(markers)

Build POV-Ray objects for point markers (e.g. base points and their images).
`markers` is `nothing` or a vector of NamedTuples. `kind` is `:dot` (filled
sphere), `:ring` (flat torus), or `:raw`. For `:dot`/`:ring`, `pos` and `color`
are 3-vectors in POV world coords / rgb and `size` is the marker radius (default
0.05); markers are emissive and cast no shadow, so they never disturb the caustic.
For `:raw`, the single field `sdl` is emitted verbatim into the scene — it may
reference the scene's motion globals (`clock`, `Motion`, `SphC0`, `Vax`, `Th`,
`Tv`, `PoleNow`), enabling clock-animated markers.
"""
function markers_pov(markers)
    (markers === nothing || isempty(markers)) && return ""
    io = IOBuffer()
    for m in markers
        # :raw injects verbatim SDL. `@MARKERS@` sits at the end of the template,
        # after the motion is set up, so raw SDL may use `clock`, `Motion`, `SphC0`,
        # `Vax`, `Th`, `Tv`, `PoleNow`, etc. (used for clock-animated markers).
        if get(m, :kind, :dot) == :raw
            println(io, m.sdl)
            continue
        end
        p = m.pos
        c = m.color
        s = get(m, :size, 0.05)
        col = "pigment { color rgb <$(c[1]), $(c[2]), $(c[3])> } finish { ambient 1.0 diffuse 0 }"
        if get(m, :kind, :dot) == :ring
            println(io, "torus { $s, $(s * 0.4) $col no_shadow translate <$(p[1]), $(p[2]), $(p[3])> }")
        else
            println(io, "sphere { <$(p[1]), $(p[2]), $(p[3])>, $s $col no_shadow }")
        end
    end
    return String(take!(io))
end

"""
    generate_pov_scene(v, theta, t, output_dir; global_settings_extra="", markers=nothing)

Substitute animation parameters into the POV-Ray template and write it to disk.
`theta` is in radians; converted to degrees here.

Coordinate note: MobiusSphere uses z as the polar axis (NorthAxis = 3, z-up),
right-handed; POV-Ray is y-up and left-handed. Axes 2 and 3 are swapped on output
so that [0,0,1] (north pole in Julia) maps to <0,1,0> (up in POV-Ray). That swap
is orientation-reversing, so the rotation angle is negated here to keep the turn's
chirality — otherwise the caustic rotates opposite to the Möbius map.

Optional `global_settings_extra` injects radiosity/photon blocks into the
template's global_settings block. Optional `markers` draws point markers (see
[`markers_pov`](@ref)).
"""
function generate_pov_scene(
    v::Vector{Float64},
    theta::Float64,
    t::Vector{Float64},
    output_dir::String;
    global_settings_extra::AbstractString="",
    markers=nothing,
)
    template_path = joinpath(ASSETS_DIR, "mobius_template.pov")
    isfile(template_path) || error("Missing template: $template_path")

    template = read(template_path, String)
    theta_deg = Base.rad2deg(theta)

    # MobiusSphere: z-up (index 3 = north pole), right-handed. POV-Ray: y-up, LEFT-handed.
    # Swap Julia axes 2 ↔ 3. That swap is an *odd* permutation (a reflection), so it reverses
    # rotation chirality: a +θ turn about the Julia axis becomes a −θ turn about the swapped
    # POV axis. Negate the angle so the caustic rotates the way the Möbius map dictates.
    # (Verified against real renders: without the negation a +90° map spun the pattern −90°.)
    pov_code = replace(
        template,
        "@GLOBAL_SETTINGS_EXTRA@" => global_settings_extra,
        "@MARKERS@" => markers_pov(markers),
        "@V_X@" => string(v[1]),
        "@V_Y@" => string(v[3]),
        "@V_Z@" => string(v[2]),
        "@THETA@" => string(-theta_deg),
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
    markers=nothing,
)
    sampling = _normalize_sampling_overrides(sampling)
    settings = merge(quality_settings(quality).pov, sampling)
    gs_extra = global_settings_extra(settings)

    ini_file = generate_pov_ini(output_dir, nframes, resolution; settings=settings)
    scene    = generate_pov_scene(v, theta, t, output_dir; global_settings_extra=gs_extra, markers=markers)
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
    for file in ("math.inc", "setup.inc", "textures.inc", "objects.inc")
        src = joinpath(ASSETS_DIR, file)
        isfile(src) || error("Missing asset: $src")
        cp(src, joinpath(output_dir, file))
    end
end
