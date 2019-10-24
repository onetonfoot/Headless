using Signals, JSON
using .Protocol: protocols
using .Utils: camel_to_sym, rmlines

const events = filter(x->haskey(x[2], "events"), protocols)

struct Event
    fn::Function
    name
    # signals # signals should be applyed after the when condition is met
end


function create_event(d, domain_name)
    ename = "$(domain_name).$(d["name"])"
    fname = d["name"] |> camel_to_sym

    quote
        function $fname(fn::Function)
            Event(fn, $ename)
        end

        export $fname
    end |> rmlines
end