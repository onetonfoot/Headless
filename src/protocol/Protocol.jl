module  Protocol
include("utils.jl")
include("methods.jl")
include("events.jl")

using .Utils: add_cmd_doc, add_event_doc, add_mod_doc


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

for (domain_name, protocol) in collect(protocols)

    add_mod_doc(protocol) |> eval

    for event in get(protocol, "events", [])
        add_event_doc(event, domain_name) |> eval
    end

    for command in get(protocol, "commands", [])
        add_cmd_doc(command, domain_name) |> eval
    end
end

# Utiliy functions for specific modules

Page.include("page.jl")

end  # module    Protocol
