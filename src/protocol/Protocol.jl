module  Protocol
include("utils.jl")
include("methods.jl")
include("events.jl")

using .Utils: add_cmd_doc, add_event_doc, add_mod_doc

module_names = []

const modules  = map(collect(keys(protocols))) do k
    commands = protocols[k]["commands"]
    protocol = protocols[k]
    events = get(protocol, "events", [])

    module_name = Symbol(k)
    global module_names
    push!(module_names, module_name)

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

for (domain_name, protocol) in collect(protocols)

    add_mod_doc(protocol) |> eval

    for event in get(protocol, "events", [])
        add_event_doc(event, domain_name) |> eval
    end

    for command in get(protocol, "commands", [])
        add_cmd_doc(command, domain_name) |> eval
    end
end

for mod in module_names
    eval(:(export $mod))
end

Page.include("page.jl")

end  # module    Protocol
