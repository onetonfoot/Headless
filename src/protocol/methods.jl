using Base.Meta, MLStyle, Plumber
import JSON

include("command.jl")

const protocols = @pipe read(joinpath(@__DIR__,"./protocol.json") ,String) |>
    JSON.parse |> filter(x -> !haskey(x,"experimental"), _["domains"] ) |>
    Dict(p["domain"] =>p for p in _)

function has_optional_args(d)
    haskey(d,"parameters") || return false
    map( x -> haskey(x, "optional") ,d["parameters"]) |> any
end

is_optional_arg(d) = haskey(d, "optional")
get_arg_names(d) = map(x -> x["name"], d["parameters"])

function camel_to_snake(x)
    x = replace(x, "JavaScript" => "javascript" )
    #TODO handle these cases
    # remove_script_toevaluate_onload
    # clear_compilation_cache
    # remove_script_toevaluate_onnew_document
    replace(x, r"(.)([A-Z][a-z+])" =>s"\1_\2") |> lowercase
end

camel_to_sym(x) = camel_to_snake(x) |> Symbol

function create_command(d, domain_name)

    fname = d["name"] |> camel_to_sym
    method = "$(domain_name).$(d["name"])"

    args, kwargs = if haskey(d, "parameters")
        params = d["parameters"]
        args = @pipe filter(!is_optional_arg, params) |> map(x -> x["name"], _)
        kwargs = @pipe filter(is_optional_arg, params) |> map(x-> x["name"], _)
        args, kwargs
    else
        [], []
    end

    kwpairs = [Expr(:kw, camel_to_sym(k), :nothing) for k in kwargs ]
    pairs = [Expr(:call, :(=>), k, camel_to_sym(k)) for k in [args; kwargs]]
    dict = Expr(:call, :Dict, pairs...)

    a =  quote
        function $fname( $(camel_to_sym.(args)...) ;  $(kwpairs...))
            Command(
                Int(rand(UInt16)),
                $method,
                $dict
            )
        end
    end

    b = maybe_add_doc(d)

    quote
        $a
        $b
    end
end

function maybe_add_doc(d)
    if haskey(d,"description")
        desc = d["description"]
        name = camel_to_sym(d["name"])
        :(@doc $desc $name)
    else
        :(nothing)
    end
end

rmlines = @λ begin
    e :: Expr           -> Expr(e.head, filter(x -> x !== nothing, map(rmlines, e.args))...)
      :: LineNumberNode -> nothing
    a                   -> a
end

const modules  = map(collect(keys(protocols))) do k
    commands = protocols[k]["commands"]
    module_name = Symbol(k)

    expr = quote
        module $module_name
            using ..Protocol: Command
            $create_command.($commands, $k) .|> eval
        end  # module
    end |> rmlines

    # https://github.com/JuliaLang/julia/issues/21009
    expr.head = :toplevel
    expr
end

eval.(modules)
