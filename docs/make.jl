using Documenter

include(joinpath(@__DIR__, "src/protocol.jl"))

makedocs(
    sitename="Headless",
    pages = ["home.md", "protocol.md" ],
)


rm(joinpath(@__DIR__, "src/protocol.md"))


deploydocs(
    repo = "github.com/onetonfoot/Headless.git",
)