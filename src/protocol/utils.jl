module Utils

using MLStyle

function camel_to_snake(x)
    #add any special cases here
    x = replace(x, "JavaScript" => "javascript" )
    replace(x, r"([a-z])([A-Z])" =>s"\1_\2") |> lowercase
end

camel_to_sym(x) = camel_to_snake(x) |> Symbol

rmlines = @λ begin
    e :: Expr           -> Expr(e.head, filter(x -> x !== nothing, map(rmlines, e.args))...)
      :: LineNumberNode -> nothing
    a                   -> a
end

function maybe_add_doc(d)
    if haskey(d,"description")
        desc = d["description"]
        arg_desc = create_args_doc(d)
        desc = join([desc, arg_desc], "\n\n")
        name = camel_to_sym(d["name"])
        :(@doc $desc $name)
    else
        :(nothing)
    end
end

function create_args_doc(d)

    if !haskey(d, "parameters")
        return ""
    end

    args = []
    optional = []

    for param in d["parameters"]
        if haskey(param, "description")
            #TODO this doesn't handle nested list properly see Page.printToPDF for example
            if haskey(param, "optional")
                push!(optional, replace("  * $(camel_to_snake(param["name"])) - $(param["description"])", "\n" => " "))
            else
                push!(args, replace("  * $(camel_to_snake(param["name"])) - $(param["description"])", "\n" => " "))
            end
        else
            if haskey(param, "optional")
                push!(optional, "  * $(camel_to_snake(param["name"])) - has no description in devtools protocol")
            else
                push!(args, "  * $(camel_to_snake(param["name"])) - has no description in devtools protocol")
            end
        end
    end

    arg_desc = ""
    optional_desc = ""

    if !isempty(args)
        arg_desc *= "Args:\n"

        arg_desc *= join(args,  "\n")
    end

    if !isempty(optional)
        optional_desc *= "Optional:\n"
        optional_desc *= join(optional,  "\n")
    end

    join([arg_desc, optional_desc], "\n\n") |> strip
end

function maybe_add_mod_doc(d)
    if haskey(d,"description")
        desc = d["description"]
        name = Symbol(d["domain"])
        :(@doc $desc $name)
    else
        :(nothing)
    end
end

end  # moduleUtils
