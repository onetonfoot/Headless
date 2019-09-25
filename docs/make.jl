using Documenter

push!(LOAD_PATH,"../src/")
using Headless


function module_datatypes(mod::Module, t::DataType)
    symbols = names(mod; all = true, imported = false)
    modules = filter(symbols) do sym
        Core.eval(mod, sym) isa t && !occursin("#", string(sym))
    end
end

modules = module_datatypes(Protocol, Module)

reference = "# Reference \n\n"

for mod in modules
    global reference
    reference *= "## $mod \n\n"

    mod = Core.eval(Protocol, mod)

    # modules = map(modules) do sym
    #     Core.eval(Protocol, sym)
    # end
end


names(p; all = true, imported = false)


open(joinpath(@__DIR__ ,"src" ,"reference.md"),"w") do f
    write(f, reference)
end


makedocs(
    sitename="Headless",
    pages = ["home.md","browser.md","protocol.md","reference.md"]
    )
