using MobiusSphereVisual
using Test

@testset "MobiusSphereVisual.jl" begin
    @testset "maybe_preserve_temp_dir" begin
        mktempdir() do temp_dir
            touch(joinpath(temp_dir, "frame0001.png"))

            dest = MobiusSphereVisual.maybe_preserve_temp_dir(temp_dir; keep_temp=true)
            @test dest !== nothing
            @test isdir(dest)
            @test isfile(joinpath(dest, "frame0001.png"))
            rm(dest; recursive=true)

            nothing_dest = MobiusSphereVisual.maybe_preserve_temp_dir(temp_dir; keep_temp=false)
            @test nothing_dest === nothing
        end
    end

    @testset "preserve_temp_dir" begin
        mktempdir() do temp_dir
            touch(joinpath(temp_dir, "test.txt"))

            dest = MobiusSphereVisual.preserve_temp_dir(temp_dir; prefix="mobius_test")
            @test isdir(dest)
            @test occursin("mobius_test", dest)
            @test isfile(joinpath(dest, "test.txt"))
            rm(dest; recursive=true)
        end
    end

    @testset "copy_output_into_preserved" begin
        mktempdir() do preserved_dir
            mktempdir() do temp_dir
                output = "nested/path/mobius_test.mp4"
                mkpath(joinpath(temp_dir, dirname(output)))
                output_path = joinpath(temp_dir, output)
                touch(output_path)

                dest = MobiusSphereVisual.copy_output_into_preserved(preserved_dir, output_path, output)
                @test dest == joinpath(preserved_dir, output)
                @test isfile(dest)
            end
        end
    end

    @testset "materialize_output" begin
        mktempdir() do temp_dir
            output = "mobius_test.mp4"
            touch(joinpath(temp_dir, output))

            dest = MobiusSphereVisual.materialize_output(temp_dir, output)
            @test dest == abspath(output)
            @test isfile(dest)
            rm(dest)
        end
    end

    @testset "preserve_failure_assets" begin
        mktempdir() do temp_dir
            touch(joinpath(temp_dir, "frame0001.png"))

            mktempdir() do final_dir
                output = "mobius_test.mp4"
                output_path = joinpath(final_dir, output)
                touch(output_path)

                failure_dir = MobiusSphereVisual.preserve_failure_assets(temp_dir, output, output_path)
                @test isdir(failure_dir)
                @test isfile(joinpath(failure_dir, "frame0001.png"))
                @test isfile(joinpath(failure_dir, output))

                rm(failure_dir; recursive=true)
                rm(output_path)
            end
        end
    end
end
