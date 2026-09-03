#!/usr/bin/env julia
# test_refactor.jl — exercises PR-1 (MobiusSphere) and PR-2 (MobiusSphereVisual)
#
# SETUP — run once to point Julia at the branch:
#
#   julia --project=@. -e '
#     using Pkg
#     Pkg.add(url="https://github.com/LauraBMo/MobiusSphere",
#             rev="claude/update-mobius-refactor-plan-vzDH1")
#     Pkg.add(url="https://github.com/LauraBMo/MobiusSphereVisual",
#             rev="claude/update-mobius-refactor-plan-vzDH1")
#   '
#
# If you have local clones use Pkg.develop(path="...") instead.
#
# Then:
#   julia --project=@. test_refactor.jl

using MobiusSphereVisual
using LinearAlgebra
using Test

@testset "MobiusSphereVisual.jl" begin
    sample_mp4 = joinpath(tempdir(), "video.mp4")
    sample_gif = joinpath(tempdir(), "gif_output.gif")
    @test MobiusSphereVisual.derived_temp_destination(sample_mp4) == joinpath(dirname(sample_mp4), "video_frames")
    @test MobiusSphereVisual.derived_temp_destination(sample_gif) == joinpath(dirname(sample_gif), "gif_output_frames")
end

# ── PR-1: MobiusSphere ────────────────────────────────────────────────────────
println("\n═══════════════════════════════════════")
println("  PR-1  MobiusSphere")
println("═══════════════════════════════════════")

using MobiusSphere

@testset "re-exports" begin
    # `using MobiusSphere` should expose these without qualifying
    @test @isdefined(MobiusTransformation)
    @test @isdefined(Möbius)
    @test @isdefined(Mobius)
    @test @isdefined(stereo)
    @test Möbius === Mobius   # ASCII alias
    println("  ✓  MobiusTransformation, Möbius, Mobius, stereo all exported")
end

@testset "MobiusTransformation basics" begin
    # Identity
    id = Möbius(ComplexF64)
    @test id(1.0+0im) ≈ 1.0+0im
    @test id(0.0+0im) ≈ 0.0+0im

    # Composition: m ∘ inv(m) ≈ identity
    m = Möbius(1.0+0im, 2.0+1im, 0.5+0im, 1.0+0im)
    for z in [0.0+0im, 1.0+0im, 0.3+0.7im, -1.0-1im]
        @test (m ∘ inv(m))(z) ≈ z  atol=1e-12
    end

    # Stereographic projection round-trip
    p = stereo()
    for pt in ([1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, -1.0])
        @test p(p(pt)) ≈ pt  atol=1e-12
    end
    println("  ✓  MobiusTransformation composition and stereo round-trip")
end

@testset "Mobius_to_rigid! (Float64)" begin
    rotation_about_y(θ) = [cos(θ) 0 sin(θ); 0 1 0; -sin(θ) 0 cos(θ)]

    proj = stereo()
    base_R = [0.0, 0.0, -1.0]   # stereo^{-1}(0)
    base_G = [1.0, 0.0,  0.0]   # stereo^{-1}(1)
    base_B = [0.0, 0.0,  1.0]   # stereo^{-1}(∞)

    for θ in (π/6, π/4, π/3, π/2, 2π/3)
        tilt = rotation_about_y(θ)
        R, G, B = tilt .* Ref(base_R), tilt .* Ref(base_G), tilt .* Ref(base_B)
        # Broadcast-multiply won't work on vectors — use actual matrix multiply:
        R, G, B = tilt*base_R, tilt*base_G, tilt*base_B

        rot, tr = MobiusSphere.Mobius_to_rigid!(R, G, B, proj)

        @test rot ≈ rotation_about_y(-θ)  atol=1e-10
        @test tr  ≈ zeros(3)              atol=1e-10
    end
    println("  ✓  Mobius_to_rigid! recovers rotation for multiple angles")
end

@testset "rigid_to_Mobius round-trip (Float64)" begin
    rotation_about_z(θ) = [cos(θ) -sin(θ) 0; sin(θ) cos(θ) 0; 0 0 1]

    for θ in (π/5, π/3, π/2)
        Q = rotation_about_z(θ)
        T = zeros(3)
        m  = rigid_to_Mobius(Q, T)
        Q2, T2 = Mobius_to_rigid(m)
        # Reconstruct: apply m, then go back
        @test Q2 ≈ Q  atol=1e-9
        @test T2 ≈ T  atol=1e-9
    end
    println("  ✓  rigid_to_Mobius ∘ Mobius_to_rigid round-trip")
end

@testset "rotation_axis_angle" begin
    function rotation_matrix(axis, θ)
        u = axis / norm(axis)
        x, y, z = u; c = cos(θ); s = sin(θ); v = 1-c
        [c+x^2*v    x*y*v-z*s  x*z*v+y*s;
         y*x*v+z*s  c+y^2*v    y*z*v-x*s;
         z*x*v-y*s  z*y*v+x*s  c+z^2*v]
    end

    for (axis, θ) in (([0.,1.,0.], π/4), ([1.,1.,0.]/√2, π/3), ([0.,0.,1.], π/2))
        R = rotation_matrix(axis, θ)
        recovered_axis, recovered_θ = MobiusSphere.rotation_axis_angle(R)
        @test recovered_θ ≈ θ  atol=1e-12
        # axis may come back flipped
        @test isapprox(recovered_axis, axis; atol=1e-12) ||
              isapprox(recovered_axis, -axis; atol=1e-12)
    end
    # Identity → θ = 0
    _, θ0 = MobiusSphere.rotation_axis_angle(Matrix{Float64}(I,3,3))
    @test θ0 ≈ 0.0  atol=1e-12
    println("  ✓  rotation_axis_angle")
end

# (The Nemo/CalciumField extension was dropped 2026-09-03 — the whole suite is Nemo-free.)

# ── PR-2: MobiusSphereVisual ──────────────────────────────────────────────────
println("\n═══════════════════════════════════════")
println("  PR-2  MobiusSphereVisual")
println("═══════════════════════════════════════")

using MobiusSphereVisual

@testset "Input validation" begin
    # Non-unit axis → normalised with a warning
    v_out = @test_logs (:warn, r"Normalising") MobiusSphereVisual.validate_inputs(
        [0.0, 0.0, 2.0], π/4, [0.0, 0.0, 0.0])
    @test norm(v_out) ≈ 1.0  atol=1e-12

    # Zero axis → error
    @test_throws ArgumentError MobiusSphereVisual.validate_inputs(
        [0.0, 0.0, 0.0], π/4, [0.0, 0.0, 0.0])

    # Non-finite theta → error
    @test_throws ArgumentError MobiusSphereVisual.validate_inputs(
        [0.0, 0.0, 1.0], Inf, [0.0, 0.0, 0.0])

    # Bad resolution → error
    @test_throws ArgumentError MobiusSphereVisual._validate_resolution((0, 720))
    println("  ✓  validate_inputs / _validate_resolution")
end

@testset "Quality presets" begin
    for sym in (:draft, :medium, :high, :ultra, :film)
        qs = MobiusSphereVisual.quality_settings(sym)
        @test haskey(qs, :pov)
        @test haskey(qs, :ffmpeg)
    end
    @test_throws ArgumentError MobiusSphereVisual.quality_settings(:nonexistent)

    # Per plan: radiosity on :high and :film; photons on :film only
    @test  MobiusSphereVisual.quality_settings(:high).pov.radiosity  == true
    @test  MobiusSphereVisual.quality_settings(:film).pov.radiosity  == true
    @test  MobiusSphereVisual.quality_settings(:film).pov.photons    == true
    @test  MobiusSphereVisual.quality_settings(:draft).pov.radiosity == false
    @test  MobiusSphereVisual.quality_settings(:draft).pov.photons   == false
    println("  ✓  quality presets (radiosity/photon flags)")
end

@testset "POV scene generation (z→y axis swap)" begin
    dir = mktempdir()
    # Rotation axis is Julia z-up [0,0,1]; should appear as <0,1,0> in POV
    v = [0.0, 0.0, 1.0]
    t = [0.0, 0.5, 0.3]  # Julia [y,z] → POV [z,y]

    scene_path = MobiusSphereVisual.generate_pov_scene(
        v, π/4, t, dir)

    pov = read(scene_path, String)

    # Axis swap: Julia v=[0,0,1] → @V_X@=0, @V_Y@=v[3]=1, @V_Z@=v[2]=0
    @test occursin("<0.0, 1.0, 0.0>", pov)   # rotation axis is y-up ✓

    # Translation swap: t=[0, 0.5, 0.3] → @T_Y@=t[3]=0.3, @T_Z@=t[2]=0.5
    @test occursin("0.3", pov)
    @test occursin("0.5", pov)

    # Theta in degrees, NEGATED: the 2↔3 axis swap reverses rotation chirality
    # into POV's left-handed frame, so generate_pov_scene emits -theta_deg.
    θ_deg = rad2deg(π/4)
    @test occursin(string(-θ_deg), pov)

    println("  ✓  generate_pov_scene: z→y swap, negated angle, degrees conversion")
    rm(dir; recursive=true)
end

@testset "copy_assets copies the mobius-look .inc files" begin
    dir = mktempdir()
    MobiusSphereVisual.copy_assets(dir)
    for f in ("math.inc", "setup.inc", "textures.inc", "objects.inc")
        @test isfile(joinpath(dir, f))
    end
    # the old photon-era assets must NOT be copied (retired 2026-08-28)
    for f in ("macros.inc", "mobius_textures.inc", "mobius_scene.inc")
        @test !isfile(joinpath(dir, f))
    end
    println("  ✓  copy_assets copies exactly the right .inc files")
    rm(dir; recursive=true)
end

@testset "derived_temp_destination" begin
    @test MobiusSphereVisual.derived_temp_destination("/tmp/foo.mp4")  == "/tmp/foo_frames"
    @test MobiusSphereVisual.derived_temp_destination("/out/bar.gif")  == "/out/bar_frames"
    println("  ✓  derived_temp_destination")
end

# ── Generic scene layer (Scene.jl) ────────────────────────────────────────────
@testset "Scene config: set_scene!/reset_scene!/scene_settings" begin
    reset_scene!()
    @test scene_settings() == Dict{Symbol,Any}()
    set_scene!(A = 2.2, C_Floor = (0.6, 0.3, 0.3), ShowAxes = false)
    s = scene_settings()
    @test s[:A] == 2.2
    @test s[:C_Floor] == (0.6, 0.3, 0.3)
    @test s[:ShowAxes] == false
    # unknown key warns and is ignored
    @test_logs (:warn, r"unknown scene key") set_scene!(NoSuchKey = 1)
    @test !haskey(scene_settings(), :NoSuchKey)
    reset_scene!()
    @test isempty(scene_settings())
    println("  ✓  set_scene! / reset_scene! / scene_settings + unknown-key warning")
end

@testset "Scene POV-literal formatting" begin
    lit = MobiusSphereVisual._pov_literal
    @test lit(:A, 2.0)                    == "2.0"
    @test lit(:ShowAxes, false)           == "false"
    @test lit(:ShowFloor, true)           == "true"
    @test lit(:C_Floor, (0.6, 0.3, 0.3))  == "rgb <0.6, 0.3, 0.3>"   # colour key → rgb
    @test lit(:CamLoc, (8, 4, 5))         == "<8, 4, 5>"             # vector key → bare <>
    @test lit(:FilterAmt, "raw_pov_here") == "raw_pov_here"          # string emitted verbatim
    @test_throws ArgumentError lit(:CamLoc, (1, 2))                  # wrong arity
    blk = MobiusSphereVisual.scene_override_block(Dict{Symbol,Any}(:A => 2.2, :ShowAxes => false))
    @test occursin("#declare A = 2.2;", blk)
    @test occursin("#declare ShowAxes = false;", blk)
    @test MobiusSphereVisual.scene_override_block(Dict{Symbol,Any}()) == ""
    println("  ✓  _pov_literal (scalar/bool/colour/vector/string) + override block")
end

@testset "toggle kwargs map to Show* globals" begin
    reset_scene!()
    ov = MobiusSphereVisual._merge_scene_overrides((;);
             floor=nothing, axes=false, glass=nothing, shell=nothing, glow=true)
    @test ov[:ShowAxes] == false
    @test ov[:ShowGlow] == true
    @test !haskey(ov, :ShowFloor)   # nothing ⇒ leave at global/default
    reset_scene!()
    println("  ✓  render_scene toggles → ShowFloor/ShowAxes/… overrides")
end

@testset "render_scene injects overrides + extra_sdl into the .pov" begin
    reset_scene!()
    dir = mktempdir()
    block = MobiusSphereVisual.scene_override_block(
        Dict{Symbol,Any}(:A => 2.2, :C_Floor => (0.6, 0.3, 0.3)))
    scene_path = MobiusSphereVisual.generate_pov_scene(
        [0.0, 0.0, 1.0], π/4, [0.0, 0.0, 0.0], dir;
        scene_overrides = block,
        extra_sdl = "sphere { <1,0,0>, 0.2 }")
    pov = read(scene_path, String)
    @test occursin("#declare A = 2.2;", pov)
    @test occursin("#declare C_Floor = rgb <0.6, 0.3, 0.3>;", pov)
    @test occursin("sphere { <1,0,0>, 0.2 }", pov)
    # the override block lands BEFORE the setup.inc include, so its #ifndef guards yield
    @test first(findfirst("#declare A = 2.2;", pov)) <
          first(findfirst("#include \"setup.inc\"", pov))
    println("  ✓  generate_pov_scene threads @SCENE_OVERRIDES@ / @EXTRA_SDL@")
    rm(dir; recursive=true)
end

# ── End-to-end render (requires povray + ffmpeg) ──────────────────────────────
println("\n═══════════════════════════════════════")
println("  End-to-end render  (skip if no tools)")
println("═══════════════════════════════════════")

has_povray = success(`which povray`)
has_ffmpeg = success(`which ffmpeg`)

if has_povray && has_ffmpeg
    @testset "render_mobius_animation :draft" begin
        out = tempname() * ".mp4"
        result = render_mobius_animation(
            [0.0, 0.0, 1.0],   # rotation axis: z-up (→ y-up in POV)
            π / 4,              # 45° rotation
            [0.0, 0.0, 0.0];   # no translation
            output   = out,
            nframes  = 6,       # tiny — just proves the pipeline works
            quality  = :draft,
        )
        @test isfile(result)
        @test filesize(result) > 1000   # non-trivial mp4
        println("  ✓  render_mobius_animation(:draft) → $(result)  ($(filesize(result)) bytes)")
        rm(result)
    end
else
    missing = filter(!identity, [has_povray ? nothing : "povray",
                                  has_ffmpeg ? nothing : "ffmpeg"])
    @warn "Skipping render test — not found in PATH: $(join(missing, ", "))"
end

println("\nAll done.")
