using MobiusSphereVisual
using Test
using LinearAlgebra

@testset "MobiusSphereVisual.jl" begin
    @testset "input validation" begin
        v, t, theta = MobiusSphereVisual.validate_inputs([0, 0, 2], 1, [1, 2, 3])
        @test isapprox(norm(v), 1.0; atol=1e-12)
        @test v ≈ [0.0, 0.0, 1.0]
        @test t == [1.0, 2.0, 3.0]
        @test theta === float(1)
    end
end
