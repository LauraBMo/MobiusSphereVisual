# ── Scene.jl ─────────────────────────────────────────────────────────────────
# The generic scene layer: a settable global scene config whose keys MIRROR the
# POV-Ray `#declare` names in assets/setup.inc (+ SphC0/camera/toggles), emitted
# as an override block before setup.inc so its `#ifndef` guards yield to them.
# `render_scene` is the generic entry; `render_mobius_animation` is a thin preset
# over it that keeps the Arnold defaults.

# Every key that may be overridden (mirror of the #ifndef-guarded globals in setup.inc).
const SCENE_KEYS = Set{Symbol}([
    # geometry / pattern
    :A, :GridSpc, :WireSpc, :WireW, :UCircW, :FadeR,
    # camera + placement
    :SphC0, :CamLoc, :CamLook, :CamAngle, :AxisLen, :AxisVtop,
    # assembly toggles
    :ShowFloor, :ShowAxes, :ShowGlass, :ShowShell, :ShowGlow,
    # palette
    :C_SkyHorizon, :C_Floor, :C_GridLine, :C_AxisLine, :C_Pin, :C_Wire,
    :C_Glass, :C_Glow, :C_Projector, :C_Axis,
    :R0, :R1, :R2, :R3, :R4, :R5,
    # material tuning
    :FilterAmt, :FilterView, :GlassFilter, :GlassDiff,
    :AmbFloor, :AmbGlass, :AmbPatch, :AmbWire, :AmbPin, :FillA, :FillB,
])

# Keys whose 3-tuple value is a colour (emitted as `rgb <...>`); other 3-tuples
# are plain POV vectors (`<...>`).
const SCENE_COLOR_KEYS = Set{Symbol}([
    :C_SkyHorizon, :C_Floor, :C_GridLine, :C_AxisLine, :C_Pin, :C_Wire,
    :C_Glass, :C_Glow, :C_Projector, :C_Axis,
    :R0, :R1, :R2, :R3, :R4, :R5,
])

# render_scene toggle keyword → the POV boolean global it sets.
const _TOGGLE_KEY = (floor = :ShowFloor, axes = :ShowAxes, glass = :ShowGlass,
                     shell = :ShowShell, glow = :ShowGlow)

# The process-wide scene config. Empty ⇒ every parameter keeps its setup.inc default.
const _SCENE = Dict{Symbol,Any}()

"""
    set_scene!(; kwargs...)

Set global scene overrides. Keys mirror the POV-Ray `#declare` names in
`assets/setup.inc` (see [`SCENE_KEYS`](@ref MobiusSphereVisual.SCENE_KEYS)):
scalars (`A=2.0`, `CamAngle=55`, `FilterAmt=0.9`), colours/vectors as 3-tuples
(`C_Floor=(0.44,0.44,0.45)`, `CamLoc=(8,4,5)`), booleans (`ShowAxes=false`), or a
raw POV string (emitted verbatim). Persists across renders until [`reset_scene!`](@ref).
Unknown keys are warned and ignored. Returns the current settings.
"""
function set_scene!(; kwargs...)
    for (k, v) in kwargs
        if k in SCENE_KEYS
            _SCENE[k] = v
        else
            @warn "set_scene!: unknown scene key :$k (ignored)."
        end
    end
    return scene_settings()
end

"""
    reset_scene!()

Clear all global scene overrides, restoring the Arnold `setup.inc` defaults.
"""
reset_scene!() = (empty!(_SCENE); nothing)

"""
    scene_settings() -> Dict{Symbol,Any}

A copy of the current global scene overrides set via [`set_scene!`](@ref).
"""
scene_settings() = copy(_SCENE)

# Format one override value as a POV-Ray literal.
function _pov_literal(key::Symbol, val)
    if val isa Bool
        return val ? "true" : "false"
    elseif val isa Real
        return string(val)
    elseif val isa AbstractString
        return String(val)                       # verbatim escape hatch (e.g. a full pigment)
    elseif val isa Union{Tuple,AbstractVector}
        length(val) == 3 ||
            throw(ArgumentError("scene key :$key expects 3 components, got $(length(val))"))
        a, b, c = val
        body = "<$(a), $(b), $(c)>"
        return key in SCENE_COLOR_KEYS ? "rgb $body" : body
    else
        throw(ArgumentError("scene key :$key: unsupported value type $(typeof(val))"))
    end
end

# Build the `#declare` override block injected before setup.inc.
function scene_override_block(overrides)
    isempty(overrides) && return ""
    io = IOBuffer()
    println(io, "// ---- scene overrides (set_scene! / render_scene) ----")
    for k in sort!(collect(keys(overrides)))
        println(io, "#declare $(k) = $(_pov_literal(k, overrides[k]));")
    end
    return String(take!(io))
end

# Merge precedence (low→high): global _SCENE < per-call `scene` < explicit toggle kwargs.
function _merge_scene_overrides(scene; floor, axes, glass, shell, glow)
    ov = copy(_SCENE)
    for (k, v) in pairs(scene)
        if k in SCENE_KEYS
            ov[k] = v
        else
            @warn "render_scene: unknown scene key :$k (ignored)."
        end
    end
    for (name, tv) in pairs((; floor, axes, glass, shell, glow))
        tv === nothing || (ov[_TOGGLE_KEY[name]] = tv)
    end
    return ov
end

"""
    render_scene(v, theta, t; floor, axes, glass, shell, glow, extra_sdl, scene, kwargs...)

Generic Möbius-sphere render. Same `(v, θ, t)` rigid motion as
[`render_mobius_animation`](@ref), but with the scene fully configurable:

- **`scene`** — a NamedTuple of per-call overrides (POV-mirrored keys, e.g.
  `scene = (A = 2.0, C_Floor = (0.5,0.5,0.5), CamAngle = 55)`), merged over any
  globals set with [`set_scene!`](@ref).
- **`floor`/`axes`/`glass`/`shell`/`glow`** — `Bool` toggles to drop a built-in
  object (default `nothing` ⇒ keep whatever the global/`setup.inc` default is).
- **`extra_sdl`** — a raw POV-Ray SDL string appended to the scene (custom
  objects). It can reference the scene's motion globals (`clock`, `Motion`,
  `SphC0`, `Vax`, `Th`, `Tv`, `PoleNow`), like a `:raw` marker.

All remaining keyword arguments (`output`, `fps`, `resolution`, `nframes`,
`quality`, `sampling`, `keep_temp`, `hold`, `markers`) match
[`render_mobius_animation`](@ref).
"""
function render_scene(
    v::AbstractVector{<:Real},
    theta::Real,
    t::AbstractVector{<:Real};
    floor::Union{Nothing,Bool}=nothing,
    axes::Union{Nothing,Bool}=nothing,
    glass::Union{Nothing,Bool}=nothing,
    shell::Union{Nothing,Bool}=nothing,
    glow::Union{Nothing,Bool}=nothing,
    extra_sdl::AbstractString="",
    scene=(;),
    output::String="mobius.mp4",
    fps::Int=30,
    resolution::Tuple{Int,Int}=(1280, 720),
    nframes::Int=150,
    quality::Symbol=:high,
    sampling::Union{Nothing,NamedTuple,Dict}=nothing,
    keep_temp::Bool=false,
    hold::Union{Bool,Real}=true,
    markers=nothing,
)
    overrides = _merge_scene_overrides(scene; floor, axes, glass, shell, glow)
    block = scene_override_block(overrides)
    return _render_animation(
        Vector{Float64}(v), Float64(theta), Vector{Float64}(t);
        scene_overrides=block, extra_sdl=String(extra_sdl),
        output=output, fps=fps, resolution=resolution, nframes=nframes,
        quality=quality, sampling=sampling, keep_temp=keep_temp, hold=hold, markers=markers,
    )
end
