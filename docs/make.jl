using MobiusSphereVisual
using Documenter

DocMeta.setdocmeta!(MobiusSphereVisual, :DocTestSetup, :(using MobiusSphereVisual); recursive=true)

makedocs(
    modules = [MobiusSphereVisual],
    authors = "LauBMo <laurea987@gmail.com> and contributors",
    sitename = "MobiusSphereVisual",
    format = Documenter.HTML(
        canonical = "https://LauraBMo.github.io/MobiusSphereVisual",
        edit_link = "main",
        assets = String[],
    ),
    pages = [
        "Home" => "index.md",
        "Rendering guide" => Any[
            "Quality presets" => "quality_presets.md",
            "Sampling overrides" => "sampling_overrides.md",
        ],
    ],
)

deploydocs(
    repo = "github.com/LauraBMo/MobiusSphereVisual.jl",
    devbranch = "main",
)
