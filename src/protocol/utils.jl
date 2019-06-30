module Utils

using MLStyle

function camel_to_snake(x)
    x = replace(x, "JavaScript" => "javascript" )
    #TODO handle these cases
    # remove_script_toevaluate_onload
    # clear_compilation_cache
    # remove_script_toevaluate_onnew_document
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
        name = camel_to_sym(d["name"])
        :(@doc $desc $name)
    else
        :(nothing)
    end
end

end  # moduleUtils
