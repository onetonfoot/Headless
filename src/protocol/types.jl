using MLStyle

function match_primative(x)
    if x == "string"
        String
    elseif x == "number"
        Float64
    elseif x == "integer"
        Int
    else
        error("unknonwn type $x")
    end
end

function match_objects()
    error("not implemented")
end

function match_types(d)
    @match d begin
        Dict("id" => id, "type" => type , "description" => desc) &&
            if type != "object" end =>  begin
                Expr(:const, Expr(Symbol("="), Symbol(id), match_primative(type)))
            end
        end
    end
end

#Evaluate the primative types
expr1 = match_types.(primatives)
eval.(expr1)
objects[1]
vcat(map(x -> x["properties"], objects)...)


chrome = Browser.Chrome(headless=false)
Browser.close(chrome)

#Should go in types file
primatives = filter( x -> x["type"] != "object",protocol["Runtime"]["types"])
objects = filter( x -> x["type"] == "object",protocol["Runtime"]["types"])
