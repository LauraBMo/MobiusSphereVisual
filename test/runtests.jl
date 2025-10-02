using MobiusSphereVisual
using Test

@testset "MobiusSphereVisual.jl" begin
    sample_mp4 = joinpath(tempdir(), "video.mp4")
    sample_gif = joinpath(tempdir(), "gif_output.gif")
    @test MobiusSphereVisual.derived_temp_destination(sample_mp4) == joinpath(dirname(sample_mp4), "video_frames")
    @test MobiusSphereVisual.derived_temp_destination(sample_gif) == joinpath(dirname(sample_gif), "gif_output_frames")
end
