# using .Protocol: protocols
using MLStyle
using Headless.Protocol: protocols

# If can figure outhow to parse the json and generate the relevant structs this could make
# working with the response from the protocol slightly easier

types = []

for protocol in values(protocols)
    if haskey(protocol, "types")
        push!(types,protocol["types"]...)
    end
end

complex = types[map(x -> x["type"] == "object" || x["type"] == "array", types)]
primatives = types[map(x -> !(x["type"] == "object" || x["type"] == "array"), types)]
@assert length(types) == length(primatives) + length(complex)

#DEFINE  PRIMATIIVE TYPES

primative2expr = Dict()

for d in primatives

    t = @match d["type"] begin
        "string" => String
        "integer" => Int
        "number" => Float64
        "boolean" => Bool
    end

    expr = if haskey(d, "enum")
        set = Set(d["enum"])
        T = Symbol(d["id"])
        quote
            struct $T
                value :: $t
                function $T(value)
                    @assert value in $set
                    new(value)
                end
            end
        end
    else
        :(const $(Symbol(d["id"])) = $t)
    end

    if haskey(primative2expr, d["id"])
        @warn "Duplicate key $(d["id"])"
    end

    primative2expr[d["id"]] = expr
end

eval.(values(primative2expr))

const string2datatype = Dict(k=>eval(Symbol(k)) for k in keys(primative2expr))

using Base.Meta



c = complex[2]
#
map(c["properties"]) do d
    t = if haskey(d,"\$ref")
        ref = d["\$ref"]
        # TODO its possible that the type in seperate modules are not the same :/
        # in which case this spliting will be invalid
        # s =  split(ref, ".")[2]
        @info ref
        # string2datatype[s]
    else
        @match d["type"] begin
            "string" => String
            "integer" => Int
            "number" => Float64
            "boolean" => Bool
                _ => @warn d["type"]
        end
    end
end
#
#
# c["properties"]
#
#
# function f(x)
#     @match x  begin
#         "string" => String
#         "integer" => Int
#         "object" => "Object"
#         "array" => "array"
#         "number" => Float64
#     end
# end
