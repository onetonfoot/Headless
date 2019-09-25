using Signals, JSON
using .Protocol: protocols
using .Utils: camel_to_sym, maybe_add_doc,rmlines

const events = filter(x->haskey(x[2], "events"), protocols)

struct Event
    fn::Function
    name
    # signals # signals should be applyed after the when condition is met
end

function create_event(d, domain_name)
    ename = "$(domain_name).$(d["name"])"
    fname = d["name"] |> camel_to_sym

    a = quote
        function $fname(fn::Function)
            Event(fn, $ename)
        end
    end

    b = maybe_add_doc(d)

    quote
        $a
        $b
    end |> rmlines
end
