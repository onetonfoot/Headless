push!(LOAD_PATH,joinpath(@__DIR__,"../../"))
using Headless
using Headless.Protocol

function module_datatypes(mod::Module, t::DataType)
    symbols = names(mod)
    modules = filter(symbols) do sym
        Core.eval(mod, sym) isa t && !occursin("#", string(sym))
    end
end
    
reference = """
# Protocol

```@meta
CurrentModule = Headless.Protocol
```
"""

modules =  module_datatypes(Protocol, Module)
for mod in modules

    global reference
    reference *= """
    ## $mod

    ```@docs
    $mod
    """

    fn_names= module_datatypes(Core.eval(Protocol, mod), Function)
    for fn in fn_names
        reference *=  "$(mod).$(fn)\n"
    end

    reference *= "```\n\n"

end

open(joinpath(@__DIR__,"protocol.md"),"w") do f
    write(f, reference)
end