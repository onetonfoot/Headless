using Base.Meta, MLStyle, Pipe
import JSON
using .Utils: camel_to_sym

const protocols = @pipe read(joinpath(@__DIR__,"./protocol.json") ,String) |>
    JSON.parse |>  
    getindex(_,  "domains") |>
    Dict(p["domain"] =>p for p in _)

# TODO Since a commands is a doubley linked list should implement iteration traits

mutable struct Command
    id
    method
    params
    next
    prev
end

Command(id, method, params) = Command(id, method, params, nothing, nothing)

function (c2::Command)(c1::Command)
    c1.next = c2
    c2.prev = c1
    c2
end

function JSON.lower(cmd::Command)
    params = filter(p ->  !isnothing(p[2]), cmd.params)
    Dict(:id     => cmd.id,
         :method => cmd.method,
         :params => params)
end

function has_optional_args(d)
    haskey(d,"parameters") || return false
    map( x -> haskey(x, "optional") ,d["parameters"]) |> any
end

is_optional_arg(d) = haskey(d, "optional")
get_arg_names(d) = map(x -> x["name"], d["parameters"])

function create_command(d, domain_name)

    fname = d["name"] |> camel_to_sym
    method = "$(domain_name).$(d["name"])"

    args, kwargs = if haskey(d, "parameters")
        params = d["parameters"]
        args = map(x -> x["name"], filter(!is_optional_arg, params))
        kwargs = map(x-> x["name"], filter(is_optional_arg, params))
        args, kwargs
    else
        [], []
    end

    kwpairs = [Expr(:kw, camel_to_sym(k), :nothing) for k in kwargs ]
    pairs = [Expr(:call, :(=>), k, camel_to_sym(k)) for k in [args; kwargs]]
    dict = Expr(:call, :Dict, pairs...)

    quote
        function $fname( $(camel_to_sym.(args)...) ;  $(kwpairs...))
            Command(Int(rand(UInt16)), $method, $dict)
        end

        export $fname
    end
end
