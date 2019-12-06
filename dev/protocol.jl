push!(LOAD_PATH,joinpath(@__DIR__,"../../"))
using Headless
using Headless.Protocol

function module_datatypes(mod::Module, t::DataType)
    symbols = names(mod)
    modules = filter(symbols) do sym
        Core.eval(mod, sym) isa t && !occursin("#", string(sym))
    end
end

function get_types(s)
    fn_types = Core.eval(Protocol, quote 
        l = []
        for fn in $module_datatypes($s, Function)
            fn = Core.eval(Protocol, Base.return_types(getproperty($s, fn)))[1]
            push!(l, fn)
        end
        l
    end )
    fn_types
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

    events = """
    ### Events
    ```@docs
    """

    cmds = """
    ### Commands
    ```@docs
    """

    fn_names= module_datatypes(Core.eval(Protocol, mod), Function)
    fn_types = get_types(mod)
    for (fn, t) in zip(fn_names, fn_types)
        println(t)
        if t isa Headless.Protocol.Command
            cmds *=  "$(mod).$(fn)\n"
        else
            events *=  "$(mod).$(fn)\n"
        end
    end

    reference *= "```\n\n"
    events *= "```\n\n"
    cmds *= "```\n\n"

    reference = """
    $reference
    $events
    $cmds
    """


end

open(joinpath(@__DIR__,"protocol.md"),"w") do f
    write(f, reference)
end