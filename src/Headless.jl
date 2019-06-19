module Headless

using Signals
import JSON

export Browser, Protocol

include("protocol/Protocol.jl")
include("browser/Browser.jl")

using .Browser
using .Protocol

end # module
