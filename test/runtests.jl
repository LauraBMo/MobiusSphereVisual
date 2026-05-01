using MobiusSphereVisual
using Test
using LinearAlgebra: norm

@testset "MobiusSphereVisual" begin

    @testset "Input validation" begin
        v_out = @test_logs (:warn, r"Normalising") MobiusSphereVisual.validate_inputs(
            [0.0, 0.0, 2.0], π/4, [0.0, 0.0, 0.0])
        @test norm(v_out) ≈ 1.0  atol=1e-12

        @test_throws ArgumentError MobiusSphereVisual.validate_inputs(
            [0.0, 0.0, 0.0], π/4, [0.0, 0.0, 0.0])
        @test_throws ArgumentError MobiusSphereVisual.validate_inputs(
            [0.0, 0.0, 1.0], Inf,  [0.0, 0.0, 0.0])
        @test_throws ArgumentError MobiusSphereVisual._validate_resolution((0, 720))
        @test_throws ArgumentError MobiusSphereVisual._validate_resolution((1280, -1))
    end

    @testset "Quality presets" begin
        for sym in (:draft, :medium, :high, :ultra, :film)
            qs = MobiusSphereVisual.quality_settings(sym)
            @test haskey(qs, :pov)
            @test haskey(qs, :ffmpeg)
        end
        @test_throws ArgumentError MobiusSphereVisual.quality_settings(:nonexistent)

        # Per plan: radiosity on :high and :film; photons on :film only.
        @test MobiusSphereVisual.quality_settings(:high).pov.radiosity  == true
        @test MobiusSphereVisual.quality_settings(:film).pov.radiosity  == true
        @test MobiusSphereVisual.quality_settings(:film).pov.photons    == true
        @test MobiusSphereVisual.quality_settings(:draft).pov.radiosity == false
        @test MobiusSphereVisual.quality_settings(:draft).pov.photons   == false
    end

    @testset "POV scene generation -- z to y axis swap" begin
        dir = mktempdir()
        # Julia north pole is z-up [0,0,1]; POV-Ray is y-up -> must appear as <0,1,0>
        v = [0.0, 0.0, 1.0]
        t = [0.0, 0.5, 0.3]   # t[3]=0.3 -> @T_Y@, t[2]=0.5 -> @T_Z@

        scene_path = MobiusSphereVisual.generate_pov_scene(v, π/4, t, dir)
        pov = read(scene_path, String)

        @test occursin("<0.0, 1.0, 0.0>", pov)           # axis y-up after swap
        @test occursin(string(rad2deg(π/4)), pov)        # theta in degrees
        @test occursin("0.3", pov)                        # t[3] -> @T_Y@
        @test occursin("0.5", pov)                        # t[2] -> @T_Z@

        rm(dir; recursive=true)
    end

    @testset "copy_assets" begin
        dir = mktempdir()
        MobiusSphereVisual.copy_assets(dir)
        for f in ("macros.inc", "mobius_textures.inc", "mobius_scene.inc")
            @test isfile(joinpath(dir, f))
        end
        # Deleted duplicate must not be present.
        @test !isfile(joinpath(dir, "mobius_macros.inc"))
        rm(dir; recursive=true)
    end

    @testset "derived_temp_destination" begin
        @test MobiusSphereVisual.derived_temp_destination("/tmp/foo.mp4") == "/tmp/foo_frames"
        @test MobiusSphereVisual.derived_temp_destination("/out/bar.gif") == "/out/bar_frames"
    end

    # End-to-end render -- only runs when povray and ffmpeg are in PATH.
    if success(`which povray`) && success(`which ffmpeg`)
        @testset "render_mobius_animation :draft" begin
            out = tempname() * ".mp4"
            result = render_mobius_animation(
                [0.0, 0.0, 1.0],
                π / 4,
                [0.0, 0.0, 0.0];
                output  = out,
                nframes = 6,
                quality = :draft,
            )
            @test isfile(result)
            @test filesize(result) > 1000
            rm(result)
        end
    end

end
