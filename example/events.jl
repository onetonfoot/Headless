using Headless.Protocol: Page, Runtime, DOM, Network, Event
using Headless.Browser: init_script
using Headless: Browser
import JSON

chrome = Browser.Chrome(headless=false)

# Alterantive API allowing user to add time signals to the event struct
# To achieve this would probaly have add a signals to field  event struct
# and overload the debounce/throttle functions to add
# there signal to the events struct

# Network.response_received() do res
#     @show res
# end |> debounce(delay=2.0) |> chrome[:tab1]


Network.response_received() do res
    @show res
end |> chrome[:tab1]

DOM.enable() |> chrome[:tab1]

doc_loaded = DOM.document_updated() do x
    print("page fully loaded event fired")
end

doc_loaded |> chrome[:tab1]

# delete!(chrome[:tab1], doc_loaded)

Page.navigate("https://news.ycombinator.com/") |> chrome[:tab1]
close(chrome)
