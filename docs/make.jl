using Documenter

include("src/protocol.jl")

makedocs(
    sitename="Headless",
    pages = ["home.md", "protocol.md" ],
)

rm("src/protocol.md")
