module Headless

using Signals
import JSON

export Browser, Protocol, kill_port

include("protocol/Protocol.jl")
include("browser/Browser.jl")
include("utils.jl")


using .Browser
export Chrome, close, opentab!, closetab!, activatetab!, tabnames

using .Protocol

end # module
