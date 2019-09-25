using Documenter

push!(LOAD_PATH,"../src/")
using Headless

makedocs(
    sitename="Headless",
    pages = ["home.md","browser.md","protocol.md"]
    )
