module Headless

using Signals
import JSON

export Browser, Protocol

include("browser/Browser.jl")
using .Browser

include("protocol/Protocol.jl")
using .Protocol


end # module
