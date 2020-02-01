
using MLStyle
using Headless.Protocol: protocols

# If can figure outhow to parse the json and generate the relevant structs this could make
# working with the response from the protocol slightly easier

types = []

for protocol in values(protocols)
    if haskey(protocol, "types")
        push!(types, protocol["types"]...)
    end
end

complex = types[map(x->x["type"] == "object" || x["type"] == "array", types)]
filter!(x->haskey(x, "properties"), complex)

primatives = types[map(x->!(x["type"] == "object" || x["type"] == "array"), types)]
unique!(primatives)
# @assert length(types) == length(primatives) + length(complex)

@info (length(complex) + length(primatives))

# DEFINE  PRIMATIIVE TYPES

primative2expr = Dict()

for d in primatives
    t = @match d["type"] begin
        "string" => String
        "integer" => Int
        "number" => Float64
        "boolean" => Bool
    end

    # some of the String primatives are actually enums
    expr = if haskey(d, "enum")
        set = Set(d["enum"])
        T = Symbol(d["id"])
        quote
            struct $T
                value::$t
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

const string2datatype = Dict(k => eval(Symbol(k)) for k in keys(primative2expr))
string2datatype["string"] = String
string2datatype["integer"] = Int64
string2datatype["number"] = Float64
string2datatype["boolean"] = Bool
string2datatype["object"] = Dict{String,String}

@info length(string2datatype)


function create_struct_data(complex_datatype)
    global string2datatype

    l = map(complex_datatype["properties"]) do d
        datatype = @match d begin
            Dict("items" => Dict("type" => type), "type" => "array") => Vector{string2datatype[type]}
            Dict("items" => Dict("\$ref" => type), "type" => "array") => Vector{string2datatype[type]}
            Dict("\$ref" => type) =>  string2datatype[type]
            Dict("type" => type) => string2datatype[type]
        end
        # TODO is this needed?!
        name = split(d["name"], ".")[end]
        name = Symbol(name)
        name => datatype
    end |> x->Dict(x...)
    Symbol(complex_datatype["id"]), l
end



example_props_false = Dict("properties" => [
 Dict{String,Any}("name" => "functionName", "description" => "JavaScript function name.", "type" => "string")                                                                             
 Dict{String,Any}("name" => "ranges", "items" => Dict{String,Any}("\$ref" => "CoverageRange"), "description" => "Source ranges inside the function with coverage data.", "type" => "array")
 Dict{String,Any}("name" => "isBlockCoverage", "description" => "Whether coverage data for this function has block granularity.", "type" => "boolean")   
])

example_props_true = Dict("properties" =>  [
    Dict{String,Any}("name" => "label", "description" => "Signed exchange signature label.", "type" => "string")                                                                  
    Dict{String,Any}("name" => "signature", "description" => "The hex string of signed exchange signature.", "type" => "string")                                                  
    Dict{String,Any}("name" => "integrity", "description" => "Signed exchange signature integrity.", "type" => "string")                                                          
    Dict{String,Any}("name" => "certUrl", "optional" => true, "description" => "Signed exchange signature cert Url.", "type" => "string")                                          
    Dict{String,Any}("name" => "certSha256", "optional" => true, "description" => "The hex string of signed exchange signature cert sha256.", "type" => "string")                  
    Dict{String,Any}("name" => "validityUrl", "description" => "Signed exchange signature validity Url.", "type" => "string")                                                     
    Dict{String,Any}("name" => "date", "description" => "Signed exchange signature date.", "type" => "integer")                                                                   
    Dict{String,Any}("name" => "expires", "description" => "Signed exchange signature expires.", "type" => "integer")                                                             
    Dict{String,Any}("name" => "certificates", "items" => Dict{String,Any}("type" => "string"), "optional" => true, "description" => "The encoded certificates.", "type" => "array")
])

function can_define(complex_datatype)

    global string2datatype

    defined_datatypes = collect(keys(string2datatype))

    map(complex_datatype["properties"]) do d
        @match d  begin
            Dict("items" => Dict("type" => t), "type" => "array") => t in defined_datatypes
            Dict("items" => Dict("\$ref" => ref), "type" => "array") => ref in defined_datatypes
            Dict("type" => t) => t in defined_datatypes
            Dict("\$ref" => ref) => ref in defined_datatypes
        end
    end |> all
end

function get_array_type(::Type{Array{T,1}}) where T
    return T
end

function create_struct_expr(struct_name::Symbol, fields::Dict{Symbol,DataType}, mutable = false)

    fields = map((collect(fields))) do (k, v)
        if v <: Vector
            t = get_array_type(v)
            Expr(:(::), k, Expr(:curly, :Array, Symbol(t), 1))
        elseif v <: Dict
            Expr(:(::), k, Expr(:curly, :Dict, :String, :String))
        else
            Expr(:(::), k, Symbol(v))   
        end
    end

    Expr(:struct, mutable, struct_name, Expr(:block,
        fields...))
end

using Base.Meta


l = map(enumerate(complex)) do (idx, c)
    if can_define(c)
        create_struct_data(c)
    end
end



complex = types[map(x->x["type"] == "object" || x["type"] == "array", types)]
filter!(x->haskey(x, "properties"), complex)

tmp_complex = []
struct_expr = []

while !isempty(complex)
    c = pop!(complex)
    if can_define(c)
        name, fields = create_struct_data(c)
        expr = create_struct_expr(name, fields)
        try 
            eval(expr)
            string2datatype[String(name)] = eval(name)
        catch e
                # @warn e
                # @info expr
        end
    else
        @info c["id"] 
    end
end

# Still misssing round 70 types :/
@info  length(string2datatype) 

