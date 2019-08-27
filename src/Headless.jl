module Headless

using Signals
import JSON

export Browser, Protocol, Repl

include("protocol/Protocol.jl")
include("browser/Browser.jl")
include("repl/Repl.jl")


using .Browser
using .Protocol
using .Repl

end # module
