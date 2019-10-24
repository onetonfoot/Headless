using Documenter

include("src/protocol.jl")

makedocs(
    sitename="Headless",
    pages = ["home.md", "protocol.md" ],
)

rm("src/protocol.md")


deploydocs(
    repo = "github.com/onetonfoot/Headless.git",
)