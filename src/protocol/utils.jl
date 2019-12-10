module Utils

using MLStyle

function camel_to_snake(x)
    # add any special cases here
    x = replace(x, "JavaScript" => "Javascript" )
    x = replace(x, "CSS" => "Css")
    replace(x, r"([a-z])([A-Z])" =>s"\1_\2") |> lowercase
end

camel_to_sym(x) = camel_to_snake(x) |> Symbol

rmlines = @λ begin
    e :: Expr           -> Expr(e.head, filter(x -> x !== nothing, map(rmlines, e.args))...)
      :: LineNumberNode -> nothing
    a                   -> a
end

function add_cmd_doc(d, domain_name)

    if haskey(d,"description")
        desc = d["description"]
        arg_desc = create_args_doc(d)
        doc = join([desc, arg_desc], "\n\n")
        name = camel_to_sym(d["name"])
        mod = Symbol(domain_name)
        :(@doc $doc $mod.$name)
    else
        :(nothing)
    end
end

function add_event_doc(d, domain_name)

    if haskey(d,"description")
        desc = d["description"]
        desc *= "\nReturns dictionary with the following fields. "
        arg_desc = create_args_doc(d)
        doc = join([desc, arg_desc], "\n\n")
        doc = replace(doc, "Args:" => "Feilds:")
        name = camel_to_sym(d["name"])
        mod = Symbol(domain_name)
        :(@doc $doc $mod.$name)
    else
        :(nothing)
    end
end

function add_mod_doc(d)
    if haskey(d,"description")
        desc = d["description"]
        name = Symbol(d["domain"])
        :(@doc $desc $name)
    else
        :(nothing)
    end
end

function gettype(d, fallback="")
    if haskey(d, "type")
        s = @match String(d["type"]) begin
            "integer" => "Int"
            "boolean" => "Bool"
            "number" => "AbstractFloat"
            "string" => "AbstractString"
            x => "UnknownType"
        end
        ":: " * s
    elseif haskey(d, "\$ref")
        t = d["\$ref"]
        ":: $t"
    else
        fallback
    end
end

# TODO refactor code is dumb but does the job
function create_args_doc(d)

    if !haskey(d, "parameters")
        return ""
    end

    args = []
    optional = []
    return_args = []
    return_optional = []

    arg_desc = ""
    optional_desc = ""
    return_arg_desc = ""
    return_optional_desc = ""

    for param in d["parameters"]
        type = gettype(param)
        name = camel_to_snake(param["name"])
        desc = if haskey(param, "description")
            replace(param["description"], "\n" => " ")
        else
            "this argument has no description in devtools protocol"
        end

        doc = "  * `$(name)` $(type) - $(desc)"

        haskey(param, "optional") ? push!(optional, doc) : push!(args, doc)
    end


    for j in get(d, "returns", [])
        type = gettype(j)
        name = camel_to_snake(j["name"])
        desc = if haskey(j, "description")
            j["description"]
        else
            "this return type has no description in devtool protocol"
        end

        doc = "  * `$(name)` $(type) - $(desc)"

        haskey(j, "optional") ? push!(return_optional, doc) : push!(return_args, doc)
    end

    if !isempty(args)
        arg_desc *= "Args:\n"
        arg_desc *= join(args,  "\n")
    end

    if !isempty(optional)
        optional_desc *= "Arg optional:\n"
        optional_desc *= join(optional,  "\n")
    end

    if !isempty(return_args)
        return_arg_desc *= "Returns:\n"
        return_arg_desc *= join(return_args,  "\n")
    end

    if !isempty(return_optional)
        return_optional_desc *= "Returns optional:\n"
        return_optional_desc *= join(return_optional,  "\n")
    end


    join([arg_desc, optional_desc, return_arg_desc, return_optional_desc], "\n\n") |> strip
end


end  # module Utils
