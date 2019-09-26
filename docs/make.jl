using Documenter

push!(LOAD_PATH,"../src/")
using Headless
using Headless.Protocol

function module_datatypes(mod::Module, t::DataType)
    symbols = names(mod; all = true, imported = false)
    modules = filter(symbols) do sym
        Core.eval(mod, sym) isa t && !occursin("#", string(sym))
    end
end
#
modules = module_datatypes(Protocol, Module)

reference = """

# Reference

```@meta
CurrentModule = Headless.Protocol
DocTestSetup = quote
    using Headless.Protocol
end
```

"""

for mod in modules
    global reference *= """

    ## $mod

    ```@autodocs
    Modules = [ $mod ]
    ```

    """
end

open(joinpath(@__DIR__ ,"src" ,"reference.md"),"w") do f
    write(f, reference)
end

makedocs(
    sitename="Headless",
    pages = ["home.md", "reference.md" ], #,"browser.md","protocol.md","reference.md"],
    modules = [Headless]
    )
