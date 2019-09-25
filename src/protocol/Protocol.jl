module  Protocol
include("utils.jl")
include("methods.jl")
include("events.jl")

using .Utils: maybe_add_mod_doc


const modules  = map(collect(keys(protocols))) do k
    commands = protocols[k]["commands"]
    protocol = protocols[k]
    events = get(protocol, "events", [])

    module_name = Symbol(k)

    expr = quote
        module $module_name
            using ..Protocol: Command, Event
            commands = $(protocol["commands"])
            $create_command.($commands, $k) .|> eval
            for event in $events
                $create_event(event, $k) |> eval
            end
        end  # module
    end |> rmlines

    # https://github.com/JuliaLang/julia/issues/21009
    expr.head = :toplevel
    expr
end

eval.(modules)

# Add documentaion for each module

for d in values(protocols)
    expr = maybe_add_mod_doc(d)
    eval(expr)
end


Page.include("page.jl")

end  # module    Protocol
