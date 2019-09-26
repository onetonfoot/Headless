using .Protocol: protocols
using MLStyle

# If can figure outhow to parse the json and generate the relevant structs this could make
# working with the response from the protocol slightly easier 

types = []

for protocol in values(protocols)
    if haskey(protocol, "types")
        push!(types,protocol["types"]...)
    end
end

primatives = types[map(x -> !(x["type"] == "object" || x["type"] == "array"), types)]
complex = types[map(x -> x["type"] == "object" || x["type"] == "array", types)]

function f(x)
    @match x  begin
        "string" => String
        "integer" => Int
        "object" => "Object"
        "array" => "array"
        "number" => Float64
    end
end
